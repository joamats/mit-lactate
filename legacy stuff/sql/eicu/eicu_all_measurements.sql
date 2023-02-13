WITH
  patients AS (
  SELECT
    --uniquepid,
    --patientHealthSystemStayID,
    patientUnitStayID,
    CAST(
      CASE
        WHEN gender LIKE '%Male%' THEN 'M'
        WHEN gender LIKE '%Female%' THEN 'F'
      ELSE
      'unknown'
    END
      AS string) AS gender,
    CAST(
      CASE
        WHEN age LIKE '%>%' THEN '90'
        WHEN age = '' THEN '0'
      ELSE
      age
    END
      AS numeric ) AS age,
    CASE
      WHEN ethnicity LIKE '%Hispanic%' THEN 'hispanic'
      WHEN ethnicity LIKE '%Caucasian%' THEN 'white'
      WHEN ethnicity LIKE '%African American%' THEN 'black'
      WHEN ethnicity LIKE '%Native%' THEN 'other'
      WHEN ethnicity LIKE '%Asian%' THEN 'asian'
    ELSE
    'unknown'
  END
    AS ethnicity,
    CAST(
      CASE
        WHEN unitDischargeStatus LIKE '%Alive%' THEN 0
        WHEN unitDischargeStatus LIKE '%Expired%' THEN 1
      ELSE
      1
    END
      AS int64) AS mort_icu,
    --hospitalDischargeStatus,
    --unitDischargeOffset
  FROM
    `physionet-data.eicu_crd.patient`
  WHERE
    unitVisitNumber = 1),
lactate AS (
  SELECT
    patientunitstayid,
    ifnull(labresult,0) AS lactate_24_hr,
    
  FROM
    `physionet-data.eicu_crd.lab` io
  WHERE
    (io.labname IS NULL
      OR io.labname LIKE '%lactate%')
    AND ((io.labresultoffset>=(-24*60))
      AND (io.labresultoffset <= (24*60)))
  ),

n_measurements AS (
  SELECT
    patientunitstayid,
    COUNT(*) AS n_measurements,
  FROM
    `physionet-data.eicu_crd.lab` io
  WHERE
    (io.labname IS NULL
      OR io.labname LIKE '%lactate%')
    AND ((io.labresultoffset>=(-24*60))
      AND (io.labresultoffset <= (24*60)))
  GROUP BY
    patientunitstayid),

eicu_table AS (
  SELECT
    p.patientUnitStayID,
    l.lactate_24_hr,
    p.ethnicity

  FROM
    patients AS p
  JOIN
    lactate AS l
  ON
    p.patientUnitStayID = l.patientUnitStayID
  JOIN n_measurements as n
  ON n.patientUnitStayID = l.patientUnitStayID
  WHERE n.n_measurements > 2
  )

SELECT * FROM eicu_table
