SELECT 
  stay_id,
  TIMESTAMP_DIFF(outtime, intime, HOUR) AS los_icu_hours 
FROM 
  `physionet-data.mimic_icu.icustays`
