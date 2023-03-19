with demographics as
(
  SELECT stay_id, rgt.string_field_1 as race_group,
 DATETIME_DIFF(ie.outtime, ie.intime, HOUR) AS los_icu_hours
, pat.anchor_age as age
, pat.anchor_year as year
, CASE
        WHEN pat.gender = 'F' THEN 1
        WHEN pat.gender = 'M' THEN 0
        -- ELSE NULL -- optional else clause in case of other values
      END AS gender
, adm.hospital_expire_flag as in_hosp_mort
-- , adm.race as race
FROM `physionet-data.mimiciv_icu.icustays` ie
LEFT JOIN `physionet-data.mimiciv_hosp.admissions` adm
    ON ie.hadm_id = adm.hadm_id
LEFT JOIN `physionet-data.mimiciv_hosp.patients` pat
    ON ie.subject_id = pat.subject_id
LEFT JOIN `aux.race_group` rgt
    ON adm.race = rgt.string_field_0

)
