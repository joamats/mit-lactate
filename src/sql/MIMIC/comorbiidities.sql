WITH icd9_to_10 AS (WITH icd_10 as (SELECT 
    icd_code,
    long_title
  FROM `physionet-data.mimiciv_hosp.d_icd_diagnoses`
  WHERE icd_version = 10), 

  icd_9 as (
    SELECT 
    icd_code,
    long_title
  FROM `physionet-data.mimiciv_hosp.d_icd_diagnoses`
  WHERE icd_version = 9
  )

  select icd_10.icd_code as icd10 , icd_9.icd_code as icd9 ,icd_9.long_title,icd_10.long_title
  from icd_10
  inner join
  icd_9 
  ON icd_9.long_title= icd_10.long_title),

  ICD10_CODES AS (
    SELECT 
    subject_id
    , hadm_id
    , CASE
       WHEN icd_version = 9 THEN icd_conv
       ELSE icd_code
      END AS icd_codes
      
FROM `physionet-data.mimiciv_hosp.diagnoses_icd`
  AS dx
  LEFT JOIN(
    SELECT icd9, icd10 AS icd_conv
    FROM icd9_to_10
  )
  AS conv
  ON conv.icd9 = dx.icd_code
  ),

  coms as (SELECT DISTINCT
    icu.hadm_id

  , CASE WHEN (
       icd_codes LIKE "%I50%"
    OR icd_codes LIKE "%I110%"
    OR icd_codes LIKE "%I27%"
    OR icd_codes LIKE "%I42%"
    OR icd_codes LIKE "%I43%"
    OR icd_codes LIKE "%I517%"
  ) THEN 1
    ELSE 0
  END AS heart_failure_present,


  CASE WHEN 
  icd_codes in  (SELECT icd_code
  FROM `physionet-data.mimiciv_hosp.d_icd_diagnoses`
  WHERE long_title like '%cirrhosis%' 
  AND icd_version= 10)
  THEN 1
  ELSE 0 
  END AS cirrhosis_present

  , CASE 
      WHEN icd_codes LIKE "%N181%" THEN 1
      WHEN icd_codes LIKE "%N182%" THEN 2
      WHEN icd_codes LIKE "%N183%" THEN 3
      WHEN icd_codes LIKE "%N184%" THEN 4
      WHEN (
           icd_codes LIKE "%N185%" 
        OR icd_codes LIKE "%N186%"
      )
      THEN 5
    ELSE 0
  END AS ckd_stages

FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu

LEFT JOIN(
  SELECT hadm_id, STRING_AGG(icd_codes) AS icd_codes
  FROM ICD10_CODES
  GROUP BY hadm_id
)
AS diagnoses_icd10 
ON diagnoses_icd10.hadm_id = icu.hadm_id

),

final_coms as (select icu.stay_id ,coms.* from coms 
inner join
`physionet-data.mimic_icu.icustays` icu
ON coms.hadm_id= icu.hadm_id)
