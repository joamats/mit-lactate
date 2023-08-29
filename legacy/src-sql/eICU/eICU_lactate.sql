WITH lac AS (

  SELECT 
    patientunitstayid
  , chartoffset
  , lactate
  , ROW_NUMBER() OVER(PARTITION BY patientunitstayid ORDER BY chartoffset ASC) AS total_seq
  , CASE
      --WHEN chartoffset >= -1440 AND chartoffset < 240    THEN 0 -- we'll take day 0 up to first 4 hours
      --WHEN chartoffset >= 240   AND chartoffset < 1440   THEN 1
      WHEN chartoffset >= -1440 AND chartoffset < 1440   THEN 1
      WHEN chartoffset >= 1440  AND chartoffset < 1440*2 THEN 2
      ELSE NULL
    END AS day

  FROM `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE lactate IS NOT NULL

),

-- add sequence within the day, but inverted
lacs AS (

  SELECT *

  , ROW_NUMBER() OVER(PARTITION BY patientunitstayid, day ORDER BY chartoffset DESC) AS day_prox

  FROM lac

),

lac_0 AS (

  SELECT 

    patientunitstayid
  , lactate AS lactate_day0

  FROM lacs
  WHERE day = 0
  AND day_prox = 1 -- aka the closest value to our upper time threshold
),

lac_1 AS (

  SELECT 

    patientunitstayid
  , MAX(lactate) AS lactate_day1
  , COUNT(lactate) AS lactate_freq_day1

  FROM lacs
  WHERE day = 1
  GROUP BY patientunitstayid
),

lac_2 AS (

  SELECT 

    patientunitstayid
  , MAX(lactate) AS lactate_day2
  , COUNT(lactate) AS lactate_freq_day2

  FROM lacs
  WHERE day = 2
  GROUP BY patientunitstayid
),

hb AS (

  SELECT
    patientunitstayid
  , MIN(hemoglobin) AS hemoglobin_stay_min

  FROM `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE hemoglobin IS NOT NULL
  AND chartoffset > -1440 -- at least 1 day before the stay
  GROUP BY patientunitstayid
  ORDER BY patientunitstayid

),

transf AS (
  SELECT
      patientunitstayid
    , intakeoutputoffset
    , CASE
        WHEN intakeoutputoffset >= 0     AND intakeoutputoffset < 1440   THEN 1
        WHEN intakeoutputoffset >= 1440  AND intakeoutputoffset < 1440*2 THEN 2
      ELSE NULL
    END AS day
    , cellvaluenumeric

  FROM `physionet-data.eicu_crd.intakeoutput`

  WHERE celllabel = "Volume (ml)-Transfuse - Leukoreduced Packed RBCs"
     OR celllabel = "Volume-Transfuse red blood cells"
     OR LOWER(celllabel) LIKE "%rbc%"
),

transfusion_overall AS (

  SELECT

    patientunitstayid
  , 1 AS transfusion_overall_yes

  FROM transf

  GROUP BY patientunitstayid
),

transfusion_1 AS (

  SELECT

    patientunitstayid
  , 1 AS transfusion_yes
  , SUM(cellvaluenumeric) AS transfusion_units_day1

  FROM transf
  WHERE day = 1

  GROUP BY patientunitstayid
),

transfusion_2 AS (

  SELECT

    patientunitstayid
  , 1 AS transfusion_yes
  , SUM(cellvaluenumeric) AS transfusion_units_day2

  FROM transf
  WHERE day = 2

  GROUP BY patientunitstayid
),

fluids AS (
  SELECT
      patientunitstayid
    , intakeoutputoffset
    , CASE
        WHEN intakeoutputoffset >= 0     AND intakeoutputoffset < 1440   THEN 1
        WHEN intakeoutputoffset >= 1440  AND intakeoutputoffset < 1440*2 THEN 2
      ELSE NULL
    END AS day
    , cellvaluenumeric

  FROM `physionet-data.eicu_crd.intakeoutput`

  WHERE celllabel IN(
    "5% Albumin"
  , "25% Albumin"
  , "albumin"
  , "Colloids Total"
  , "Crystalloid"
  , "Crystalloids"
  , "Albumin 5%"
  , "25% Albumin 50 ml"
  , "5% Albumin 500 ml"
  , "Albumin 25%"
  , "25% Albumin 100 ml"
  , "Albumin Intake"
  , "Saline Flush (mL)"
  , "Lactated Ringers Volume"
  , "Volume (mL)-lactated ringers infusion"
  , "Volume (mL)-albumin human 5 % injection"
  , "Volume (mL)-SODIUM CHLORIDE 0.9 % IV SOLN"
  , "Volume (mL)-lactated ringers bolus 500 mL"
  , "Volume (mL)-sodium chloride 0.9% infusion"
  , "Volume (mL)-0.9 % sodium chloride solution"
  , "Volume (mL)-0.45 % sodium chloride solution"
  , "Volume (mL)-lactated ringers bolus 1,000 mL"
  , "Volume (mL)-sodium chloride 0.45 % infusion"
  , "Volume (mL)-albumin human 5 % injection 25 g"
  , "Volume (mL)-0.45 % sodium chloride infusion"
  , "Volume (mL)-0.9 %  sodium chloride infusion"
  , "Volume (mL)-albumin human 5 % injection 12.5 g"
  , "Volume (mL)-lactated ringers infusion 1,000 mL"
  , "Volume (mL)-albumin human 25 % solution 25 g"
  , "Volume (mL)-lactated ringers infusion 500 mL"
  , "Volume (mL)-albumin human 25 % injection 25 g"
  , "Volume (mL)-albumin human 5 % solution 12.5 g"
  , "Volume (mL)-albumin human 5 % solution 250 mL"
  , "Volume (mL)-sodium chloride 0.9 % bolus 250 mL"
  , "Volume (mL)-sodium chloride 0.9 % bolus 500 mL"
  , "Volume (mL)-sodium chloride 0.9 % 250 mL IV bolus"
  , "Volume (mL)-sodium chloride 0.9 % 500 mL IV bolus"
  , "Volume (mL)-albumin human 25 % injection 12.5 g"
  , "Volume (mL)-sodium chloride 0.9 % bolus 1,000 mL"
  , "Volume (mL)-albumin human (SPA) 25 % injection 25 g"
  , "Volume (mL)-sodium chloride 0.9 % 1,000 mL IV bolus"
  , "Volume (mL)-sodium chloride 0.9 % 1,000 mL infusion"
  , "Volume (mL)-sodium chloride 0.9 % 2,000 mL IV bolus"
  , "Volume (mL)-sodium chloride 0.9 % flush IVPB 250 mL"
  , "Volume (mL)-sodium chloride 0.9 % flush IVPB 500 mL"
  , "Volume (mL)-albumin human 5 % injection 12.5-25 g"
  , "Volume (mL)-ALBUMIN HUMAN 5 % IV SOLN Pyxis Override"
  , "Volume (mL)-albumin human (SPA) 25 % injection 12.5 g"
  , "Volume (mL)-sodium chloride 0.45 % 1,000 mL infusion"
  , "Volume (mL)-SODIUM CHLORIDE 0.9 % IV SOLN Pyxis Override"
  , "Volume (mL)-sodium chloride (NORMAL SALINE) 0.9 % bolus 250 mL"
  , "Volume (mL)-sodium chloride (NORMAL SALINE) 0.9 % bolus 500 mL"
  , "Volume (mL)-sodium chloride (NORMAL SALINE) 0.9 % bolus 1,000 mL"
  )
),

fluids_overall AS (

  SELECT

    patientunitstayid
  , 1 AS fluids_overall_yes

  FROM fluids

  GROUP BY patientunitstayid
),

fluids_1 AS (

  SELECT

    patientunitstayid
  , 1 AS fluids_yes
  , SUM(cellvaluenumeric) AS fluids_sum_day1

  FROM fluids
  WHERE day = 1

  GROUP BY patientunitstayid
),

fluids_2 AS (

  SELECT

    patientunitstayid
  , 1 AS fluids_yes
  , SUM(cellvaluenumeric) AS fluids_sum_day2

  FROM fluids
  WHERE day = 2

  GROUP BY patientunitstayid
),

rrt AS (

   SELECT DISTINCT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(treatmentOffset) AS rrt_start_delta
   FROM `physionet-data.eicu_crd.treatment`

   WHERE treatmentstring LIKE "renal|dialysis|C%"
      OR treatmentstring LIKE "renal|dialysis|hemodialysis|emergent%"
      OR treatmentstring LIKE "renal|dialysis|hemodialysis|for acute renal failure"
      OR treatmentstring LIKE "renal|dialysis|hemodialysis"
   AND treatmentOffset > -1440

   GROUP BY patientunitstayid

   UNION DISTINCT

   SELECT DISTINCT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(intakeOutputOffset) AS rrt_start_delta
   FROM `physionet-data.eicu_crd.intakeoutput`

   WHERE dialysistotal <> 0
   AND intakeOutputOffset > -1440

   GROUP BY patientunitstayid

   UNION DISTINCT

   SELECT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(noteoffset) as rrt_start_delta
   FROM `physionet-data.eicu_crd.note` 

   WHERE noteoffset > -1440 
   AND (notetype ="Dialysis Catheter" OR  notetype ="Dialysis Catheter Change")

   GROUP BY patientunitstayid

  UNION DISTINCT

   SELECT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(startoffset) as rrt_start_delta
   FROM `physionet-data.eicu_crd_derived.crrt_dataset` 
   
   WHERE startoffset > -1440 
 
   GROUP BY patientunitstayid
),

rrt_overall AS (

  SELECT 
      patientunitstayid
    , MAX(rrt_yes) AS rrt_overall_yes
    , MIN(rrt_start_delta) AS rrt_start_delta

  FROM rrt
  GROUP BY patientunitstayid

)


SELECT DISTINCT

    1 AS sepsis3 -- all patients from Yugang's table are already septic
  , yug.hospitalid AS hospital_id
  , yug.wardid AS icu_id
  , yug.patienthealthsystemstayid AS patient_id
  , yug.patientunitstayid AS stay_id

  , yug.unitvisitnumber AS stay_number
  , yug.hospitaldischargeyear AS year

  , CASE WHEN yug.age = "> 89" THEN "91" ELSE yug.age END AS age
  , CASE WHEN yug.gender = 'Female' THEN 1 ELSE 0 END AS sex_female

  , yug.ethnicity as race
  , CASE 
      WHEN (
        LOWER(yug.ethnicity) LIKE "%caucasian%" 
      ) THEN "White"
      WHEN (
        LOWER(yug.ethnicity) LIKE "%african american%"
      ) THEN "Black"
      WHEN (
         LOWER(yug.ethnicity) LIKE "%hispanic%"
      ) THEN "Hispanic"
      WHEN (
         LOWER(yug.ethnicity) LIKE "%asian%"
      ) THEN "Asian"
      ELSE "Other"
    END AS race_group

  , yug.Charlson as charlson_ci
  , CASE 
      WHEN ( yug.Charlson >= 0 AND yug.Charlson <= 3) THEN "0-3"
      WHEN ( yug.Charlson >= 4 AND yug.Charlson <= 6) THEN "4-6" 
      WHEN ( yug.Charlson >= 7 AND yug.Charlson <= 10) THEN "7-10" 
      WHEN ( yug.Charlson > 10) THEN ">10" 
    END AS CCI_ranges

  , yug.sofa_admit as sofa_day1 
  , CASE 
      WHEN ( yug.sofa_admit >= 0 AND yug.sofa_admit <= 3) THEN "0-3"
      WHEN ( yug.sofa_admit >= 4 AND yug.sofa_admit <= 6) THEN "4-6" 
      WHEN ( yug.sofa_admit >= 7 AND yug.sofa_admit <= 10) THEN "7-10" 
      WHEN ( yug.sofa_admit > 10) THEN ">10" 
    END AS SOFA_ranges

  , CASE WHEN adm.adm_elective = 1 THEN "Elective" ELSE "Emergency" END AS admit_type
  , yug.hospitaladmitsource AS admit_source

  , coms.cirrhosis_present
  , coms.heart_failure_present 
  , coms.ckd_stages

  , COALESCE(icustay_detail.admissionweight, icustay_detail.dischargeweight) AS weight
  
  --, lactate_day0
  , lactate_day1
  , lactate_freq_day1
  , lactate_day2
  , lactate_freq_day2
  
  , hemoglobin_stay_min 

  , CASE 
      WHEN yug.unitdischargelocation = "Death"
        OR yug.unitdischargestatus = "Expired"
        OR yug.hospitaldischargestatus = "Expired"
      THEN 1
      ELSE 0
    END AS mortality_in 
  , yug.hospitaldischargeoffset / 60 AS los_icu_hours


-- Treatments and their offsets
  , CASE 
      WHEN 
           yug.vent IS TRUE
        OR vent_yes > 0
      THEN 1
      ELSE 0
    END AS mech_vent

  , CASE 
      WHEN 
           yug.rrt IS TRUE
        OR rrt_yes > 0
      THEN 1
      ELSE 0
    END AS rrt

  , CASE 
      WHEN 
           yug.vasopressor IS TRUE
        OR vp_yes > 0
      THEN 1
      ELSE 0
    END AS vasopressor
  
  -- , vent_start_offset
  -- , rrt_start_offset
  -- , vp_start_offset

-- Convert offset from minutes to fraction of day
  , SAFE_DIVIDE(vent_start_offset,(24*60)) AS MV_init_offset_d_abs -- convert from minutes to days, in MIMIC it's from hours to days
  , SAFE_DIVIDE(rrt_start_offset,(24*60)) AS RRT_init_offset_d_abs
  , SAFE_DIVIDE(vp_start_offset,(24*60)) AS VP_init_offset_d_abs
 -- , SAFE_DIVIDE(SAFE_DIVIDE(vent_duration,(24*60)),yug.los_icu) AS MV_time_perc_of_stay
 -- , SAFE_DIVIDE(SAFE_DIVIDE(vp_time_d,(24*60)),yug.los_icu) AS VP_time_perc_of_stay -- omitted as not easily feasible in eICU

  -- Blood Transfusion
  , CASE WHEN transfusion_overall_yes = 1 THEN 1 ELSE 0 END AS transfusion_overall_yes
  , COALESCE(transfusion_1.transfusion_yes, transfusion_2.transfusion_yes, 0) AS transfusion_yes
  , transfusion_units_day1
  , transfusion_units_day2

  -- Fluids
  , CASE WHEN fluids_overall_yes = 1 THEN 1 ELSE 0 END AS fluids_overall_yes
  , COALESCE(fluids_1.fluids_yes, fluids_2.fluids_yes, 0) AS fluids_yes
  , fluids_sum_day1
  , fluids_sum_day2


FROM `protean-chassis-368116.my_eICU.yugang` AS yug

LEFT JOIN(
  SELECT patientunitstayid, unitvisitnumber, admissionweight, dischargeweight
  FROM `physionet-data.eicu_crd_derived.icustay_detail`
) 
AS icustay_detail
ON icustay_detail.patientunitstayid = yug.patientunitstayid

LEFT JOIN(
  SELECT patientunitstayid, MIN(adm_elective) AS adm_elective
  FROM `protean-chassis-368116.my_eICU.pivoted_elective`
  GROUP BY patientunitstayid
)
AS adm
ON adm.patientunitstayid = yug.patientunitstayid

LEFT JOIN `protean-chassis-368116.my_eICU.pivoted_comorbidities`
AS coms
ON coms.patientunitstayid = yug.patientunitstayid

LEFT JOIN hb
ON hb.patientunitstayid = yug.patienthealthsystemstayid

LEFT JOIN lac_0
ON lac_0.patientunitstayid = yug.patientunitstayid

LEFT JOIN lac_1
ON lac_1.patientunitstayid = yug.patientunitstayid

LEFT JOIN lac_2
ON lac_2.patientunitstayid = yug.patientunitstayid

LEFT JOIN transfusion_overall
ON transfusion_overall.patientunitstayid = yug.patientunitstayid

LEFT JOIN transfusion_1
ON transfusion_1.patientunitstayid = yug.patientunitstayid

LEFT JOIN transfusion_2
ON transfusion_2.patientunitstayid = yug.patientunitstayid

LEFT JOIN fluids_overall
ON fluids_overall.patientunitstayid = yug.patientunitstayid

LEFT JOIN fluids_1
ON fluids_1.patientunitstayid = yug.patientunitstayid

LEFT JOIN fluids_2
ON fluids_2.patientunitstayid = yug.patientunitstayid

LEFT JOIN rrt_overall
ON rrt_overall.patientunitstayid = yug.patientunitstayid
AND rrt_overall.rrt_start_delta > -1440 -- only considering RRT initiated in 1 day before ICU admission

LEFT JOIN `protean-chassis-368116.my_eICU.aux_treatments`
AS treatments
ON treatments.patientunitstayid = yug.patientunitstayid

-- Inclusion Criteria for later
-- WHERE lactate_day0 IS NOT NULL
-- AND lactate_day1 IS NOT NULL
-- AND lactate_day2 IS NOT NULL
-- AND yug.hospitaldischargeoffset >= 1440

ORDER BY yug.hospitalid, yug.wardid, yug.patienthealthsystemstayid, yug.patientunitstayid, yug.unitvisitnumber
