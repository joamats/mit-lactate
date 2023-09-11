-- Thus we would need from you a data frame/csv with stay id, charttime, and vital signs (heart rate, respiratory rate, temperature, mean arterial blood pressure, and SpO2) and norepinephrine equivalent dose (there is a derived table on Physionet for that).
vitals AS (SELECT 
ce.stay_id,ce.charttime,
MAX(case when itemid in (220045) then valuenum else null end) as heart_rate,
MAX(case when itemid in (220210,224690)then valuenum else null end) as resp_rate,
MAX(case when itemid in (220052,225312) then valuenum else null end) as mbp,
MAX(case when itemid in (220277) then valuenum else null end) as spo2,
MAX(case when itemid in (223761) then round((valuenum-32)/1.8) -- converted to degC
     when itemid in (223762)then valuenum else null end) as temp_degC
FROM `physionet-data.mimiciv_icu.chartevents` ce
GROUP BY ce.stay_id, ce.charttime
),

norepi_equi_table AS (SELECT ne.stay_id,ne.starttime as charttime,norepinephrine_equivalent_dose
FROM`physionet-data.mimiciv_derived.norepinephrine_equivalent_dose`  ne), 


remove_null_vitals AS (SELECT * FROM vitals
WHERE heart_rate IS NOT NULL
OR resp_rate IS NOT NULL
OR mbp IS NOT NULL
OR spo2 IS NOT NULL
OR temp_degC IS NOT NULL
ORDER BY stay_id,charttime),

distinct_stayids AS (SELECT DISTINCT stay_id
FROM (
  SELECT stay_id
  FROM vitals
  UNION ALL
  SELECT stay_id
  FROM norepi_equi_table
) 
ORDER BY stay_id) -- 73176
,

common AS (SELECT a.*,b.*except(stay_id,charttime) FROM remove_null_vitals a
INNER JOIN norepi_equi_table b
ON a.stay_id=b.stay_id
and a.charttime=b.charttime)-- 63694
,

rows_in_vitals_not_in_ned_based_on_stayid_and_charttime AS (SELECT a.*,b.norepinephrine_equivalent_dose
FROM remove_null_vitals a
LEFT JOIN norepi_equi_table b ON a.stay_id=b.stay_id and a.charttime=b.charttime
WHERE b.charttime IS NULL) -- select rows in vitals not in ned --7184890 
,
rows_in_ned_not_in_vitals_on_stayid_and_charttime AS (SELECT b.stay_id,
b.charttime,
heart_rate,
resp_rate,
mbp,
spo2,
temp_degC,
norepinephrine_equivalent_dose
FROM remove_null_vitals a
RIGHT JOIN norepi_equi_table b ON a.stay_id=b.stay_id and a.charttime=b.charttime
AND a.charttime is NULL) --select rows in right table (NED) not in left table (vitals) --619330

SELECT stay_id, charttime, heart_rate, resp_rate, mbp, spo2, temp_degC, norepinephrine_equivalent_dose
FROM common
UNION DISTINCT
SELECT stay_id, charttime, heart_rate, resp_rate, mbp, spo2, temp_degC, norepinephrine_equivalent_dose
FROM rows_in_vitals_not_in_ned_based_on_stayid_and_charttime
UNION DISTINCT
SELECT stay_id, charttime, heart_rate, resp_rate, mbp, spo2, temp_degC, norepinephrine_equivalent_dose
FROM rows_in_ned_not_in_vitals_on_stayid_and_charttime
ORDER BY stay_id,charttime
