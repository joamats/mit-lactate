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
  
  , yug.hospitaldischargeoffset / 1440 AS los_icu_hours
  , CASE 
      WHEN yug.unitdischargelocation = "Death"
        OR yug.unitdischargestatus = "Expired"
        OR yug.hospitaldischargestatus = "Expired"
      THEN 1
      ELSE 0
    END AS mortality_in 


FROM `db_name.my_eICU.yugang` AS yug


LEFT JOIN(
  SELECT patientunitstayid, unitvisitnumber, admissionweight, dischargeweight
  FROM `physionet-data.eicu_crd_derived.icustay_detail`
) 
AS icustay_detail
ON icustay_detail.patientunitstayid = yug.patientunitstayid

LEFT JOIN(
  SELECT patientunitstayid, MIN(adm_elective) AS adm_elective
  FROM `db_name.my_eICU.pivoted_elective`
  GROUP BY patientunitstayid
)
AS adm
ON adm.patientunitstayid = yug.patientunitstayid

LEFT JOIN(
  SELECT *
  FROM `db_name.my_eICU.pivoted_comorbidities`
)
AS coms
ON coms.patientunitstayid = yug.patientunitstayid

ORDER BY yug.hospitalid, yug.wardid, yug.patienthealthsystemstayid, yug.patientunitstayid, yug.unitvisitnumber
