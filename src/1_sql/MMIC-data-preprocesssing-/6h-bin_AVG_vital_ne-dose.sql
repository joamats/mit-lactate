-- 6h bind with the average vital sign,  (heart rate, respiratory rate, temperature, mean arterial blood pressure, and SpO2) and norepinephrine equivalent dose
WITH heart_rate_table AS (SELECT ce.subject_id, ce.hadm_id,ce.stay_id,ce.charttime,icu.intime,
case when itemid in (220045) then valuenum else null end as heart_rate,
TIMESTAMP_DIFF(charttime, intime, HOUR) AS hrs,
FROM `physionet-data.mimiciv_icu.icustays` icu
INNER JOIN  `physionet-data.mimiciv_icu.chartevents` ce
ON icu.stay_id=ce.stay_id
WHERE itemid=220045),

heart_rate_hrs_less_7 as (SELECT stay_id, hrs,heart_rate
                           FROM heart_rate_table
                           WHERE hrs<7
                           ORDER BY stay_id,hrs),

heart_rate_hrs_less_7_AVG as (SELECT stay_id, hrs,AVG(heart_rate) AS heart_rate_AVG
                           FROM heart_rate_table
                           WHERE hrs<7
                           GROUP BY  stay_id, hrs
                           ORDER BY stay_id,hrs),

-------------------------------------------------------------------------------------------------------------
resp_rate_table AS (SELECT ce.subject_id, ce.hadm_id,ce.stay_id,ce.charttime,icu.intime,
case when itemid in (220210,224690)then valuenum else null end as resp_rate,
TIMESTAMP_DIFF(charttime, intime, HOUR) AS hrs,
FROM `physionet-data.mimiciv_icu.icustays` icu
INNER JOIN  `physionet-data.mimiciv_icu.chartevents` ce
ON icu.stay_id=ce.stay_id
WHERE itemid in (220210,224690)),


resp_rate_hrs_less_7_AVG as (SELECT stay_id, hrs,AVG(resp_rate) AS resp_rate_AVG
                           FROM resp_rate_table
                           WHERE hrs<7
                           GROUP BY  stay_id, hrs
                           ORDER BY stay_id,hrs),
-------------------------------------------------------------------------------------------------------------
mbp_table AS (SELECT ce.subject_id, ce.hadm_id,ce.stay_id,ce.charttime,icu.intime,
case when itemid in (220052,225312) then valuenum else null end as mbp,
TIMESTAMP_DIFF(charttime, intime, HOUR) AS hrs,
FROM `physionet-data.mimiciv_icu.icustays` icu
INNER JOIN  `physionet-data.mimiciv_icu.chartevents` ce
ON icu.stay_id=ce.stay_id
WHERE itemid in (220052,225312)),

mbp_hrs_less_7_AVG as (SELECT stay_id, hrs,AVG(mbp) AS mbp_AVG
                           FROM mbp_table
                           WHERE hrs<7
                           GROUP BY  stay_id, hrs
                           ORDER BY stay_id,hrs),
-------------------------------------------------------------------------------------------------------------
spo2_table AS (SELECT ce.subject_id, ce.hadm_id,ce.stay_id,ce.charttime,icu.intime,
case when itemid in (220277) then valuenum else null end as spo2,
TIMESTAMP_DIFF(charttime, intime, HOUR) AS hrs,
FROM `physionet-data.mimiciv_icu.icustays` icu
INNER JOIN  `physionet-data.mimiciv_icu.chartevents` ce
ON icu.stay_id=ce.stay_id
WHERE itemid in (220277)),
spo2_hrs_less_7_AVG as (SELECT stay_id, hrs,AVG(spo2) AS spo2_AVG
                           FROM spo2_table
                           WHERE hrs<7
                           GROUP BY  stay_id, hrs
                           ORDER BY stay_id,hrs),
-------------------------------------------------------------------------------------------------------------
temp_table AS (SELECT ce.subject_id, ce.hadm_id,ce.stay_id,ce.charttime,icu.intime,
case when itemid in (223761) then (valuenum-32)/1.8 -- converted to degC in valuenum call
      when itemid in (223762)then valuenum else null end as temp_degC,
TIMESTAMP_DIFF(charttime, intime, HOUR) AS hrs,
FROM `physionet-data.mimiciv_icu.icustays` icu
INNER JOIN  `physionet-data.mimiciv_icu.chartevents` ce
ON icu.stay_id=ce.stay_id
WHERE itemid in (223761,223762)),
temp_degC_hrs_less_7_AVG as (SELECT stay_id, hrs,AVG(temp_degC) AS temp_degC_AVG
                           FROM temp_table
                           WHERE hrs<7
                           GROUP BY  stay_id, hrs
                           ORDER BY stay_id,hrs),
-------------------------------------------------------------------------------------------------------------
norepi_equi_table as (SELECT ne.*except(endtime),
TIMESTAMP_DIFF(starttime, intime, HOUR) AS hrs,
FROM `physionet-data.mimiciv_icu.icustays` icu
INNER JOIN `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose`  ne
ON icu.stay_id=ne.stay_id),

norepi_equi_hrs_less_7_AVG as (SELECT stay_id, hrs,AVG(norepinephrine_equivalent_dose) AS norepinephrine_equivalent_dose_AVG
                           FROM norepi_equi_table
                           WHERE hrs<7
                           GROUP BY  stay_id, hrs
                           ORDER BY stay_id,hrs),

-------------------------------------------------------------------------------------------------------------
icustays AS (
  SELECT DISTINCT stay_id
  FROM `physionet-data.mimiciv_icu.icustays`
),

hrs_0_6 as (SELECT stay_id, hours AS hrs
FROM icustays
CROSS JOIN UNNEST(GENERATE_ARRAY(0, 6)) AS hours
ORDER BY icustays.stay_id, hours)

SELECT a.stay_id,
a.hrs,
heart_rate_AVG,
resp_rate_AVG,
mbp_AVG,
spo2_AVG,
temp_degC_AVG,
norepinephrine_equivalent_dose_AVG
FROM hrs_0_6 a
LEFT JOIN heart_rate_hrs_less_7_AVG b
ON a.stay_id=b.stay_id
AND a.hrs=b.hrs
LEFT JOIN resp_rate_hrs_less_7_AVG c
ON a.stay_id=c.stay_id
AND a.hrs=c.hrs

LEFT JOIN mbp_hrs_less_7_AVG d
ON a.stay_id=d.stay_id
AND a.hrs=d.hrs

LEFT JOIN spo2_hrs_less_7_AVG e
ON a.stay_id=e.stay_id
AND a.hrs=e.hrs

LEFT JOIN temp_degC_hrs_less_7_AVG f
ON a.stay_id=f.stay_id
AND a.hrs=f.hrs

LEFT JOIN norepi_equi_hrs_less_7_AVG g
ON a.stay_id=g.stay_id
AND a.hrs=g.hrs

ORDER BY stay_id,hrs
