WITH lac AS (

  SELECT
      chartevents.*
    , icustays.intime
    , ROW_NUMBER() OVER(PARTITION BY icustays.stay_id ORDER BY DATE_DIFF(charttime, intime, MINUTE) ASC) AS total_seq
    , CASE WHEN DATE_DIFF(charttime, intime, MINUTE) >= -1440 AND DATE_DIFF(charttime, intime, MINUTE) < 1440 THEN 1
           WHEN DATE_DIFF(charttime, intime, MINUTE) >= 1440  AND DATE_DIFF(charttime, intime, MINUTE) < 1440*2 THEN 2
           ELSE NULL
      END AS day

  FROM physionet-data.mimiciv_icu.chartevents
  LEFT JOIN physionet-data.mimiciv_icu.icustays 
  ON chartevents.stay_id = icustays.stay_id
  WHERE itemid = 225668
  AND valuenum < 100
  AND valuenum IS NOT NULL
)
, lac_1 AS (

  SELECT 

    stay_id
  , MAX(valuenum) AS lactate_day1
  , COUNT(valuenum) AS lactate_freq_day1

  FROM lac
  WHERE day = 1
  GROUP BY stay_id
),

lac_2 AS (

  SELECT 

    stay_id
  , MAX(valuenum) AS lactate_day2
  , COUNT(valuenum) AS lactate_freq_day2

  FROM lac
  WHERE day = 2
  GROUP BY stay_id
)

, fio2_table AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_24h

  FROM `db_name.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS fio2_table
  ON fio2_table.subject_id = icu.subject_id

  WHERE TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) <= 1440 
  AND TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) >= 0
  GROUP BY subject_id, stay_id
)

, fluids_table AS (
    SELECT
      ce.stay_id
    , SUM(amount) AS fluids_volume
    , SUM(amount)/MAX(icu.los_icu) AS fluids_volume_norm_by_los_icu
    , MAX(icu.los_icu) AS los_icu

    FROM  `physionet-data.mimiciv_icu.inputevents` ce

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id

    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    GROUP BY stay_id
)

SELECT 
-- icu details
    icu.subject_id
  , icu.stay_id
  , icu.hadm_id
  , icu.los_icu
  , icu.los_hospital
  , icu.admittime AS hosp_intime
  , icu.dischtime AS hosp_outtime
  , icu.icu_intime
  , icu.icu_outtime
  , icu.hospstay_seq
  , icu.icustay_seq
  , icu.dod
  , CASE WHEN s3.sepsis3 IS TRUE THEN 1 ELSE 0 END AS sepsis3

-- baseline clinical and demographics vars
  , pat.anchor_year_group
  , icu.admission_age
  , icu.gender
  , CASE WHEN icu.gender = "F" THEN 1 ELSE 0 END AS sex_female
  , icu.race
  , CASE 
      WHEN (
         LOWER(icu.race) LIKE "%white%"
      OR LOWER(icu.race) LIKE "%portuguese%" 
      OR LOWER(icu.race) LIKE "%caucasian%" 
      ) THEN "White"
      WHEN (
         LOWER(icu.race) LIKE "%black%"
      OR LOWER(icu.race) LIKE "%african american%"
      ) THEN "Black"
      WHEN (
         LOWER(icu.race) LIKE "%hispanic%"
      OR LOWER(icu.race) LIKE "%south american%" 
      ) THEN "Hispanic"
      WHEN (
         LOWER(icu.race) LIKE "%asian%"
      ) THEN "Asian"
      ELSE "Other"
    END AS race_group

  , weight.weight_admit
  , charlson.charlson_comorbidity_index
  , ad.language
  , CASE WHEN ad.language = "ENGLISH" THEN 1 ELSE 0 END AS eng_prof
  , ad.insurance
  , CASE WHEN ad.insurance = "Other" THEN 1 ELSE 0 END AS private_insurance
  , adm.adm_type
  , adm.adm_elective
  , major_surgery

-- lactate values
  , lac_1.lactate_day1
  , lac_1.lactate_freq_day1
  , lac_2.lactate_day2
  , lac_2.lactate_freq_day2

-- illness severity - admission
  , sf.SOFA
  , sf.respiration
  , sf.coagulation
  , sf.liver
  , sf.cardiovascular
  , sf.cns
  , sf.renal
  , oa.oasis
  , oa.oasis_prob AS prob_mort

-- treatments
  , fluids_volume
  , fluids_volume_norm_by_los_icu
  , CASE WHEN (transfusion_yes IS NOT NULL) THEN transfusion_yes ELSE 0 END AS transfusion_overall
  , CASE WHEN (insulin_yes IS NOT NULL) THEN insulin_yes ELSE 0 END AS insulin_overall
  , InvasiveVent.InvasiveVent_hr
  , Oxygen.Oxygen_hr
  , HighFlow.HighFlow_hr
  , NonInvasiveVent.NonInvasiveVent_hr
  , Trach.Trach_hr

  , CASE
    WHEN (InvasiveVent.InvasiveVent_hr IS NOT NULL OR Trach.Trach_hr IS NOT NULL)
    THEN 1
    ELSE 0
  END AS mech_vent_overall

  , CASE WHEN rrt.rrt = 1 THEN 1 ELSE 0 END AS rrt_overall
  , CASE WHEN (pressor.stay_id = icu.stay_id) IS TRUE THEN 1 ELSE 0 END AS vasopressor_overall

  , FiO2_mean_24h
  , MV_time_hr/24 AS MV_time_abs
  , vp_time_hr/24 AS VP_time_abs
  , MV_time_hr/24/icu.los_icu AS MV_time_perc_of_stay
  , vp_time_hr/24/icu.los_icu AS VP_time_perc_of_stay

-- initiation offsets
  , CASE
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS MV_init_offset_perc

  , CASE
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS MV_init_offset_abs

  , CASE
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24/icu.los_icu
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS RRT_init_offset_perc
  , CASE
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS RRT_init_offset_abs

  , CASE
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS VP_init_offset_perc

  , CASE
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS VP_init_offset_abs

-- vital signs (first 24h)
  , resp_rate_mean
  , mbp_mean
  , heart_rate_mean
  , temperature_mean
  , spo2_mean

-- lab values (first 24h) 
  , po2_min
  , pco2_max
  , ph_min
  , lactate_max
  , glucose_max
  , sodium_min
  , potassium_max
  , cortisol_min
  , hemoglobin_min
  , fibrinogen_min
  , inr_max

-- comorbidites
  , hypertension_present
  , heart_failure_present
  , copd_present
  , asthma_present
  , cad_present
  , ckd_stages
  , diabetes_types
  , connective_disease

-- origin of infection
  , pneumonia
  , uti
  , biliary
  , skin
  
-- hospital complications
  , clabsi
  , cauti
  , ssi
  , vap

-- code
  , first_code
  , last_code
  , CASE
      WHEN codes.first_code IS NULL
        OR codes.first_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_admission
  
  , CASE
      WHEN codes.last_code IS NULL
        OR codes.last_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_discharge

-- outcome
  , ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) as dod_icuout_offset

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
  ) THEN 1
    ELSE 0
  END AS mortality_in

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
      OR ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) <= 90
  ) THEN 1
    ELSE 0
  END AS mortality_90

FROM `physionet-data.mimiciv_derived.icustay_detail`
AS icu

-- Sepsis Patients
LEFT JOIN physionet-data.mimiciv_derived.sepsis3
AS s3
ON s3.stay_id = icu.stay_id

LEFT JOIN lac_1
AS lac_1
ON lac_1.stay_id = icu.stay_id

LEFT JOIN lac_2
AS lac_2
ON lac_2.stay_id = icu.stay_id

left join `physionet-data.mimiciv_hosp.patients` as pat
on icu.subject_id = pat.subject_id

left join `physionet-data.mimiciv_hosp.admissions` as ad
on icu.hadm_id = ad.hadm_id

left join `physionet-data.mimiciv_derived.first_day_sofa` as sf
on icu.stay_id = sf.stay_id 

left join `physionet-data.mimiciv_derived.first_day_weight` as weight
on icu.stay_id = weight.stay_id 

left join `physionet-data.mimiciv_derived.charlson` as charlson
on icu.hadm_id = charlson.hadm_id 

left join `physionet-data.mimiciv_derived.first_day_urine_output` as fd_uo
on icu.stay_id = fd_uo.stay_id 

-- rrt
left join (select distinct stay_id, dialysis_present as rrt  from `physionet-data.mimiciv_derived.rrt` where dialysis_present = 1) as rrt
on icu.stay_id = rrt.stay_id 

-- RRT initiation offset
left join (
  SELECT dia.stay_id,
  MAX(dialysis_present) AS rrt,
  MIN(charttime) AS charttime
  FROM `physionet-data.mimiciv_derived.rrt` dia
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = dia.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, charttime, HOUR) > 0 -- to make sure it's within the ICU stay
  AND TIMESTAMP_DIFF(charttime, icu.icu_intime, HOUR) > 0
  WHERE dialysis_present = 1
  GROUP BY stay_id
) AS rrt_time
ON icu.stay_id = rrt_time.stay_id 

-- vasopressors
left join (select distinct stay_id from  `physionet-data.mimiciv_derived.epinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.norepinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.phenylephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.vasopressin`) as pressor
on icu.stay_id = pressor.stay_id 

-- for VP percentage of stay
LEFT JOIN(
  SELECT
    nor.stay_id
    , SUM(TIMESTAMP_DIFF(endtime, starttime, HOUR)) AS vp_time_hr
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_time
ON vp_time.stay_id = icu.stay_id

-- VPs offset initiation
LEFT JOIN(
  SELECT
    nor.stay_id
    , MIN(starttime) AS starttime
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_mtime
ON vp_mtime.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as InvasiveVent_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "InvasiveVent" group by stay_id) as InvasiveVent
on InvasiveVent.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as Oxygen_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "Oxygen" group by stay_id) as Oxygen
on Oxygen.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as HighFlow_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "HighFlow" group by stay_id) as HighFlow
on HighFlow.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as NonInvasiveVent_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "NonInvasiveVent" group by stay_id) as NonInvasiveVent
on NonInvasiveVent.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as Trach_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "Trach" group by stay_id) as Trach
on Trach.stay_id = icu.stay_id

-- for MV perc of stay
left join (
  SELECT vent.stay_id,
  SUM(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as MV_time_hr
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
) AS mv_time
ON mv_time.stay_id = icu.stay_id

-- for MV initation offset 
LEFT JOIN (
  SELECT vent.stay_id, MIN(starttime) as starttime
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
)
AS mv_mtime
ON mv_mtime.stay_id = icu.stay_id

-- FiO2 table
LEFT JOIN fio2_table
ON fio2_table.stay_id = icu.stay_id

-- Add admission type
-- Mapping: 
-- Emergency: ‘AMBULATORY OBSERVATION’, ‘DIRECT EMER.’, ‘URGENT’, ‘EW EMER.’, ‘DIRECT OBSERVATION’, ‘EU OBSERVATION’, ‘OBSERVATION ADMIT’
-- Elective: ‘ELECTIVE’, ‘SURGICAL SAME DAY ADMISSION’

LEFT JOIN (SELECT hadm_id, admission_type as adm_type,
CASE
    WHEN (admission_type LIKE "%ELECTIVE%" OR
     admission_type LIKE "%SURGICAL SAME DAY ADMISSION%") 
     THEN 1
     ELSE 0
     END AS adm_elective
FROM `physionet-data.mimiciv_hosp.admissions`) as adm
on adm.hadm_id = icu.hadm_id

-- Add OASIS Score
LEFT JOIN (SELECT stay_id, oasis, oasis_prob
FROM `physionet-data.mimiciv_derived.oasis`) as oa
on oa.stay_id = icu.stay_id

-- Add Transfusions
LEFT JOIN (
SELECT ce.stay_id --, amount --, valueuom --itemid
, max(
    CASE
    WHEN ce.itemid IN ( 226368, 227070, 220996, 221013,226370) THEN 1
    ELSE 0
    END) AS transfusion_yes
FROM  `physionet-data.mimiciv_icu.inputevents` ce
WHERE itemid IN (226368, 227070, 220996, 221013, 226370) 
and amount is NOT NULL and amount >0 
GROUP BY stay_id
)
AS ce
ON ce.stay_id = icu.stay_id

-- Add insulin transfusion
LEFT JOIN (
SELECT cee.stay_id --, amount --, valueuom --itemid
, max(
    CASE
    WHEN cee.itemid IN (223257, 223258, 223259, 223260, 223261, 223262, 229299, 229619) THEN 1
    ELSE 0
    END) AS insulin_yes
FROM  `physionet-data.mimiciv_icu.inputevents` cee
WHERE itemid IN (223257, 223258, 223259, 223260, 223261, 223262, 229299, 229619)
and amount is NOT NULL and amount > 0 
GROUP BY stay_id
)
AS cee
ON cee.stay_id = icu.stay_id

-- Add Lab from original table
-- minimal whole stay cortisol and hemoglobin
LEFT JOIN (
SELECT hadm_id,
MIN(
    CASE
    WHEN lab.itemid IN (50909) THEN valuenum
    ELSE NULL
    END) AS cortisol_min,

MIN(
    CASE
    WHEN lab.itemid IN (50811, 51222) THEN valuenum
    ELSE NULL
    END) AS hemoglobin_min

FROM `physionet-data.mimiciv_hosp.labevents` AS lab
where itemid IN (50909, 50811, 51222)
GROUP BY hadm_id
)
AS lab
ON lab.hadm_id = icu.hadm_id

-- Add Lab values from derived tables
LEFT JOIN (
SELECT stay_id,
glucose_max, sodium_min, potassium_max,
fibrinogen_min, inr_max
FROM `physionet-data.mimiciv_derived.first_day_lab` AS dl
)
AS dl
ON dl.stay_id = icu.stay_id

LEFT JOIN (
SELECT stay_id,
ph_min, lactate_max 

FROM `physionet-data.mimiciv_derived.first_day_bg` AS bg
)
AS bg
ON bg.stay_id = icu.stay_id

LEFT JOIN (
SELECT stay_id,
po2_min, pco2_max

FROM `physionet-data.mimiciv_derived.first_day_bg_art` AS bgart
)
AS bgart
ON bgart.stay_id = icu.stay_id

-- Add Vital Signs
LEFT JOIN(
  SELECT
      stay_id
    , resp_rate_mean
    , mbp_mean
    , heart_rate_mean
    , temperature_mean
    , spo2_mean
  FROM `db_name.mimiciv_derived.first_day_vitalsign`
) AS vs
ON vs.stay_id = icu.stay_id

-- Add Code
LEFT JOIN (
  SELECT
      stay_id
    , first_code
    , last_code
  FROM `db_name.my_MIMIC.pivoted_codes`
) AS codes
ON codes.stay_id = icu.stay_id

-- Add major surgery based on Alistair's OASIS implementation
LEFT JOIN (
 
 WITH surgflag as (
 SELECT ie.stay_id
        , MAX(CASE
            WHEN LOWER(curr_service) LIKE '%surg%' THEN 1
            WHEN curr_service = 'ORTHO' THEN 1
            ELSE NULL END) AS major_surgery
        
        , MAX(CASE
            WHEN first_careunit LIKE  "%SICU%" AND
            first_careunit NOT LIKE "%MICU/SICU%"  THEN 1
            ELSE NULL END) AS surgical_icu

    FROM mimiciv_icu.icustays ie

    LEFT JOIN mimiciv_hosp.services se
        ON ie.hadm_id = se.hadm_id
        AND se.transfertime < DATETIME_ADD(ie.intime, INTERVAL '2' DAY)
    GROUP BY ie.stay_id
 )  
  SELECT *
  FROM surgflag
  WHERE major_surgery = 1 OR surgical_icu = 1
) 
AS ms
ON ms.stay_id = icu.stay_id

-- Add comorbidities, conditions present on admission, and complications
LEFT JOIN `db_name.my_MIMIC.pivoted_comorbidities` AS com
ON com.hadm_id = icu.hadm_id

-- Add fluids' volume
LEFT JOIN fluids_table
ON fluids_table.stay_id = icu.stay_id

WHERE icu.los_icu > 0

ORDER BY icu.subject_id, icu.hadm_id, icu.stay_id


