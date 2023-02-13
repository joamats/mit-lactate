WITH lac AS (

  SELECT 
    patientunitstayid
  , chartoffset
  , lactate
  , ROW_NUMBER() OVER(PARTITION BY patientunitstayid ORDER BY chartoffset ASC) AS total_seq
  , CASE
      WHEN chartoffset >= -1440 AND chartoffset < 240    THEN 0 -- we'll take day 0 up to first 4 hours
      WHEN chartoffset >= 240   AND chartoffset < 1440   THEN 1
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
  , yug.sofa_admit as sofa_day1 

  , CASE WHEN adm.adm_elective = 1 THEN "Elective" ELSE "Emergency" END AS admit_type
  , yug.hospitaladmitsource AS admit_source

  , coms.cirrhosis_present
  , coms.heart_failure_present 
  , coms.ckd_stages

  , COALESCE(icustay_detail.admissionweight, icustay_detail.dischargeweight) AS weight
  
  , lactate_day0
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

  , COALESCE(transfusion_1.transfusion_yes, transfusion_2.transfusion_yes) AS transfusion_yes
  , transfusion_units_day1
  , transfusion_units_day2


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

LEFT JOIN(
  SELECT *
  FROM `protean-chassis-368116.my_eICU.pivoted_comorbidities`
)
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

LEFT JOIN transfusion_1
ON transfusion_1.patientunitstayid = yug.patientunitstayid

LEFT JOIN transfusion_2
ON transfusion_2.patientunitstayid = yug.patientunitstayid

-- Inclusion Criteria for later
-- WHERE lactate_day0 IS NOT NULL
-- AND lactate_day1 IS NOT NULL
-- AND lactate_day2 IS NOT NULL
-- AND yug.hospitaldischargeoffset >= 1440

ORDER BY yug.hospitalid, yug.wardid, yug.patienthealthsystemstayid, yug.patientunitstayid, yug.unitvisitnumber