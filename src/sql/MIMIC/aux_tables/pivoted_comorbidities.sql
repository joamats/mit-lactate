DROP TABLE IF EXISTS `db_name.my_MIMIC.pivoted_comorbidities`;
CREATE TABLE `db_name.my_MIMIC.pivoted_comorbidities` AS

SELECT DISTINCT
    icu.hadm_id,
    adm_dx.pneumonia, adm_dx.uti, adm_dx.biliary, adm_dx.skin,
    adm_dx.clabsi, adm_dx.cauti, adm_dx.ssi, adm_dx.vap


  , CASE WHEN (
       icd_codes LIKE "%I10%"
    OR icd_codes LIKE "%I11%"
    OR icd_codes LIKE "%I12%"
    OR icd_codes LIKE "%I13%"
    OR icd_codes LIKE "%I14%"
    OR icd_codes LIKE "%I15%"
    OR icd_codes LIKE "%I16%"
    OR icd_codes LIKE "%I70%"
  ) THEN 1
    ELSE NULL
  END AS hypertension_present

  , CASE WHEN (
       icd_codes LIKE "%I50%"
    OR icd_codes LIKE "%I110%"
    OR icd_codes LIKE "%I27%"
    OR icd_codes LIKE "%I42%"
    OR icd_codes LIKE "%I43%"
    OR icd_codes LIKE "%I517%"
  ) THEN 1
    ELSE NULL
  END AS heart_failure_present

  , CASE WHEN (
       icd_codes LIKE "%J41%"
    OR icd_codes LIKE "%J42%"
    OR icd_codes LIKE "%J43%"
    OR icd_codes LIKE "%J44%"
    OR icd_codes LIKE "%J45%"
    OR icd_codes LIKE "%J46%"
    OR icd_codes LIKE "%J47%"
  ) THEN 1
    ELSE NULL
  END AS copd_present

  , CASE WHEN 
      icd_codes LIKE "%J841%"
      THEN 1
      ELSE NULL
  END AS asthma_present

  , CASE WHEN (
       icd_codes LIKE "%I20%"
    OR icd_codes LIKE "%I21%"
    OR icd_codes LIKE "%I22%"
    OR icd_codes LIKE "%I23%"
    OR icd_codes LIKE "%I24%"
    OR icd_codes LIKE "%I25%"
  ) THEN 1
    ELSE NULL
  END AS cad_present

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
    ELSE NULL
  END AS ckd_stages

  , CASE 
      WHEN icd_codes LIKE "%E08%" THEN 1
      WHEN icd_codes LIKE "%E09%" THEN 1
      WHEN icd_codes LIKE "%E10%" THEN 1
      WHEN icd_codes LIKE "%E11%" THEN 2
      WHEN icd_codes LIKE "%E13%" THEN 1
    ELSE NULL
  END AS diabetes_types

-- connective tissue disease as defined in Elixhauser comorbidity score
  , CASE 
      WHEN icd_codes LIKE "%L940" THEN 1
      WHEN icd_codes LIKE "%L941" THEN 1
      WHEN icd_codes LIKE "%L943%" THEN 1
      WHEN icd_codes LIKE "%M05%" THEN 1
      WHEN icd_codes LIKE "%M06%" THEN 1
      WHEN icd_codes LIKE "%M08%" THEN 1
      WHEN icd_codes LIKE "%M120" THEN 1
      WHEN icd_codes LIKE "%M123" THEN 1
      WHEN icd_codes LIKE "%M30%" THEN 1
      WHEN icd_codes LIKE "%M310%" THEN 1
      WHEN icd_codes LIKE "%M311%" THEN 1
      WHEN icd_codes LIKE "%M312%" THEN 1
      WHEN icd_codes LIKE "%M313%" THEN 1
      WHEN icd_codes LIKE "%M32%" THEN 1
      WHEN icd_codes LIKE "%M33%" THEN 1
      WHEN icd_codes LIKE "%M34%" THEN 1
      WHEN icd_codes LIKE "%M35%" THEN 1
      WHEN icd_codes LIKE "%M45%" THEN 1
      WHEN icd_codes LIKE "%M461%" THEN 1
      WHEN icd_codes LIKE "%M468%" THEN 1
      WHEN icd_codes LIKE "%M469%" THEN 1
    ELSE NULL
  END AS connective_disease

FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu

LEFT JOIN(
  SELECT hadm_id, STRING_AGG(icd_codes) AS icd_codes
  FROM `db_name.my_MIMIC.aux_icd10codes`
  GROUP BY hadm_id
)
AS diagnoses_icd10 
ON diagnoses_icd10.hadm_id = icu.hadm_id

-- Diagnoses upon admission and hospital acquired infections
LEFT JOIN(
 
 WITH inf_s AS (
  SELECT *
  ,CASE 
      WHEN icd_code LIKE "%J09%" THEN 1
      WHEN icd_code LIKE "%J1%" THEN 1
      WHEN icd_code LIKE "%J85%" THEN 1
      WHEN icd_code LIKE "%J86%" THEN 1
      ELSE NULL
  END AS pneumonia

  ,CASE 
      WHEN icd_code LIKE "%N300%" THEN 1
      WHEN icd_code LIKE "%N390%" THEN 1       
      ELSE NULL
  END AS uti

  ,CASE 
      WHEN icd_code LIKE "%K81%" THEN 1
      WHEN icd_code LIKE "%K830%" THEN 1
      WHEN icd_code LIKE "%K851%" THEN 1  
      ELSE NULL
  END AS biliary

  ,CASE      
      WHEN icd_code LIKE "%L0%" THEN 1       
      ELSE NULL
  END AS skin

FROM `physionet-data.mimiciv_hosp.diagnoses_icd` 

WHERE seq_num <= 3 -- only consider top 3 diagnoses for importance
)

, inf_h AS (
  SELECT *
  , CASE 
      WHEN icd_code LIKE "%T80211%" THEN 1
      ELSE NULL
  END AS hospital_clabsi

 , CASE 
      WHEN icd_code LIKE "%T83511%" THEN 1
      ELSE NULL
  END AS hospital_cauti

 , CASE 
      WHEN icd_code LIKE "%T814%" THEN 1
      ELSE NULL
  END AS hospital_ssi

 , CASE 
      WHEN icd_code LIKE "%J95851%" THEN 1
      ELSE NULL
  END AS hospital_vap

FROM `physionet-data.mimiciv_hosp.diagnoses_icd` 

-- here we consider all possible diagnoses
)

-- Group by admission
SELECT DISTINCT inf_s.hadm_id, 
MAX(inf_s.pneumonia) AS pneumonia, MAX(inf_s.uti) AS uti, MAX(inf_s.biliary) AS biliary, MAX(inf_s.skin) AS skin,
MAX(inf_h.hospital_clabsi) AS clabsi, MAX(inf_h.hospital_cauti) AS cauti, MAX(inf_h.hospital_ssi) AS ssi, MAX(inf_h.hospital_vap) AS vap

FROM inf_s

LEFT JOIN inf_h
ON inf_s.hadm_id = inf_h.hadm_id

WHERE COALESCE(pneumonia, uti, biliary, skin) IS NOT NULL 
GROUP BY hadm_id

)
AS adm_dx 
ON adm_dx.hadm_id = icu.hadm_id
