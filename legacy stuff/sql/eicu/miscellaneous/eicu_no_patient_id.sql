SELECT
    uniquepid,
    patientHealthSystemStayID,
    patientUnitStayID,
    gender,
    age,
    CAST(
      CASE
        WHEN age LIKE '%>%' THEN '90'
        WHEN age = '' THEN '0'
      ELSE
      age
    END
      AS numeric ) AS agenum,
    CASE
        WHEN ethnicity LIKE '%Hispanic%' THEN 'hispanic'
        WHEN ethnicity LIKE '%Caucasian%' THEN 'white'
        WHEN ethnicity LIKE '%African American%' THEN 'black'
        WHEN ethnicity LIKE '%Native%' THEN 'other'
        WHEN ethnicity LIKE '%Asian%' THEN 'asian'
      ELSE
        'unknown'
    END
      AS ethnicity_corrected,
    ethnicity,
    unitDischargeStatus,
    hospitalDischargeStatus,
    unitDischargeOffset
  FROM
    `physionet-data.eicu_crd.patient`
  WHERE
    unitVisitNumber = 1
