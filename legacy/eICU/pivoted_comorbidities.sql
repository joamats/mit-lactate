DROP TABLE IF EXISTS `db_name.my_eICU.pivoted_comorbidities`;
CREATE TABLE `db_name.my_eICU.pivoted_comorbidities` AS
  
  
  WITH temp_table AS (

  SELECT icu.patientunitstayid, 
  dx.*, ph.*

  FROM `db_name.eicu_crd_derived.icustay_detail` as icu

  -- get missing values from diagnosistring
  LEFT JOIN(
    SELECT patientunitstayid AS patientunitstayid_dx

    , STRING_AGG(icd9code) AS icd_codes

    , MAX(
      CASE
        WHEN LOWER(diagnosisstring) LIKE "%hypertension%"
        AND LOWER(diagnosisstring) NOT LIKE "%pulmonary hypertension%" THEN 1
        ELSE NULL
      END)
      AS hypertension_1

    ,MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%heart fail%" THEN 1
      ELSE NULL
    END)
    AS heart_failure_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 1%" THEN 1
      ELSE NULL
    END)
    AS renal_11

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 2%" THEN 2
      ELSE NULL
    END)
    AS renal_12

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 3%" THEN 3
      ELSE NULL
    END)
    AS renal_13

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 4%" THEN 4
      ELSE NULL
    END)
    AS renal_14

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 5%" THEN 5
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%esrd%" THEN 5
      ELSE NULL
    END)
    AS renal_15

    , MAX( 
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%copd%" THEN 1
      ELSE NULL
    END)
    AS copd_1

    , MAX( 
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%coronary%" THEN 1
      ELSE NULL
    END)
    AS cad_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%asthma%" THEN 1
      ELSE NULL
    END)
    AS asthma_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%diabetes mellitus|Type I%" THEN 1
      ELSE NULL
    END)
    AS diabetes_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%diabetes mellitus|Type II%" THEN 1
      ELSE NULL
    END)
    AS diabetes_2

    FROM `physionet-data.eicu_crd.diagnosis`
    GROUP BY patientunitstayid
  )
  AS dx
  ON dx.patientunitstayid_dx = icu.patientunitstayid


  -- get missing values from past history
  LEFT JOIN(
    SELECT patientunitstayid AS patientunitstayid_ph
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%hypertension%"
      AND LOWER(pasthistorypath) NOT LIKE "%pulmonary hypertension%" THEN 1
      ELSE NULL
    END)
    AS hypertension_2
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%heart fail%" THEN 1
      ELSE NULL
    END)
    AS heart_failure_2
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 1-2%" THEN 2
      ELSE NULL
    END)
    AS renal_22

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 2-3%" THEN 3
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 3-4%" THEN 3
      ELSE NULL
    END)
    AS renal_23

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 4-5%" THEN 4
      ELSE NULL
    END)
    AS renal_24

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine > 5%" THEN 5
      WHEN LOWER(pasthistorypath) LIKE "%renal failure%" THEN 5
      ELSE NULL
    END)
    AS renal_25
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%copd%" THEN 1
      ELSE NULL
    END)
    AS copd_2

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%coronary%" THEN 1
      ELSE NULL
    END)
    AS cad_2

    ,MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%asthma%" THEN 1
      ELSE NULL
    END)
    AS asthma_2

    ,MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%diabetes%" THEN 1
      ELSE NULL
    END)
    AS diabetes_3

    FROM `physionet-data.eicu_crd.pasthistory`
    GROUP BY patientunitstayid
  )
  AS ph
  ON ph.patientunitstayid_ph = icu.patientunitstayid

),

  cirrhosis AS (
    SELECT patientunitstayid, 1 AS cirrhosis_present
    FROM (
        SELECT distinct patientunitstayid 
        FROM `physionet-data.eicu_crd.pasthistory` 
        WHERE pasthistorypath
        IN ("notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/jaundice",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/UGI bleeding",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/encephalopathy",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/ascites",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/varices",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/biopsy proven",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/clinical diagnosis",
            "notes/Progress Notes/Past History/Organ Systems/Gastrointestinal (R)/Cirrhosis/coma"
        )
    UNION ALL
    SELECT distinct patientunitstayid
    FROM `physionet-data.eicu_crd.apachepredvar`
    WHERE cirrhosis = 1

    UNION ALL
    SELECT distinct patientunitstayid
    FROM `physionet-data.eicu_crd.diagnosis`
    WHERE diagnosisstring
    IN ("gastrointestinal|hepatic disease|hepatic dysfunction|with cirrhosis",
        "gastrointestinal|hepatic disease|hepatic dysfunction|with cirrhosis|biliary",
        "gastrointestinal|hepatic disease|hepatic dysfunction|with cirrhosis|alcoholic",
        "gastrointestinal|hepatic disease|hepatic dysfunction|with cirrhosis|cryptogenic"
       )
    )
)

SELECT temp_table.patientunitstayid

  , CASE
    WHEN hypertension_1 IS NOT NULL
    OR hypertension_2 IS NOT NULL 
    OR icd_codes LIKE "%I10%"
    OR icd_codes LIKE "%I11%"
    OR icd_codes LIKE "%I12%"
    OR icd_codes LIKE "%I13%"
    OR icd_codes LIKE "%I14%"
    OR icd_codes LIKE "%I15%"
    OR icd_codes LIKE "%I16%"
    OR icd_codes LIKE "%I70%"
    THEN 1
    ELSE 0
    END AS hypertension_present

  , CASE 
    WHEN heart_failure_1 IS NOT NULL
    OR heart_failure_2 IS NOT NULL 
    OR icd_codes LIKE "%I50%"
    OR icd_codes LIKE "%I110%"
    OR icd_codes LIKE "%I27%"
    OR icd_codes LIKE "%I42%"
    OR icd_codes LIKE "%I43%"
    OR icd_codes LIKE "%I517%"
    THEN 1
    ELSE 0
    END AS heart_failure_present

  , CASE 
    WHEN asthma_1 IS NOT NULL
    OR asthma_2 IS NOT NULL
    OR icd_codes LIKE "%J841%"
    THEN 1
    ELSE 0
    END AS asthma_present

  , CASE 
    WHEN copd_1 IS NOT NULL
    OR copd_2 IS NOT NULL
    OR icd_codes LIKE "%J41%"
    OR icd_codes LIKE "%J42%"
    OR icd_codes LIKE "%J43%"
    OR icd_codes LIKE "%J44%"
    OR icd_codes LIKE "%J45%"
    OR icd_codes LIKE "%J46%"
    OR icd_codes LIKE "%J47%"
    THEN 1
    ELSE 0
    END AS copd_present

  , CASE 
    WHEN cad_1 IS NOT NULL
    OR cad_2 IS NOT NULL
    OR icd_codes LIKE "%I20%"
    OR icd_codes LIKE "%I21%"
    OR icd_codes LIKE "%I22%"
    OR icd_codes LIKE "%I23%"
    OR icd_codes LIKE "%I24%"
    OR icd_codes LIKE "%I25%"
    THEN 1
    ELSE 0
    END AS cad_present

  , CASE 
    WHEN renal_11 IS NOT NULL
      OR icd_codes LIKE "%N181%" 
    THEN 1
    WHEN renal_12 IS NOT NULL
      OR renal_22 IS NOT NULL
      OR icd_codes LIKE "%N182%"
    THEN 2
    WHEN renal_13 IS NOT NULL
      OR renal_23 IS NOT NULL
      OR icd_codes LIKE "%N183%"
    THEN 3
    WHEN renal_14 IS NOT NULL
      OR renal_24 IS NOT NULL
      OR icd_codes LIKE "%N184%"
    THEN 4
    WHEN renal_15 IS NOT NULL
      OR renal_25 IS NOT NULL
      OR icd_codes LIKE "%N185%"
      OR icd_codes LIKE "%N186%"
    THEN 5
    ELSE 0
    END AS ckd_stages

  , CASE 
    WHEN diabetes_1 IS NOT NULL
      OR icd_codes LIKE "%E08%" 
      OR icd_codes LIKE "%E09%"
      OR icd_codes LIKE "%E10%"
      OR icd_codes LIKE "%E13%"
    THEN 1
    WHEN diabetes_2 IS NOT NULL
      OR diabetes_3 IS NOT NULL
      OR icd_codes LIKE "%E11%"
    THEN 2
    ELSE 0
    END AS diabetes_types
  
  , CASE
    WHEN cirrhosis.cirrhosis_present = 1
    THEN 1
    ELSE 0
    END AS cirrhosis_present

  FROM temp_table
  LEFT JOIN cirrhosis
  ON cirrhosis.patientunitstayid = temp_table.patientunitstayid


  ORDER BY patientunitstayid