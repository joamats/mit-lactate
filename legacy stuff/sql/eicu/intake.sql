WITH
  time AS (
  SELECT
    MAX(intakeoutputoffset) AS max_in,
    MIN(intakeoutputoffset) AS min_in,
    patientunitstayid
  FROM
    `physionet-data.eicu_crd.intakeoutput` -- --
  -- WHERE
    -- patientunitstayid = 206904
  GROUP BY
    patientunitstayid )
    
,maximum_intake as (
  SELECT
    io.intakeTotal AS max_intaketotal,
    time.patientunitstayid
  FROM
    `physionet-data.eicu_crd.intakeoutput` io
  JOIN
    time
  ON
    io.patientunitstayid = time.patientunitstayid
  WHERE
    io.intakeoutputoffset = time.max_in )
    
  , minimum_intake as (
  SELECT
    io.intakeTotal AS min_intaketotal,
    time.patientunitstayid
  FROM
    `physionet-data.eicu_crd.intakeoutput` io
  JOIN
    time
  ON
    io.patientunitstayid = time.patientunitstayid
  WHERE
    io.intakeoutputoffset = time.min_in )

  
SELECT
  max_i.patientunitstayid, 
  CASE 
   WHEN (time.max_in - time.min_in < 1440 AND time.min_in < 0) THEN (max_i.max_intaketotal - min_i.min_intaketotal)
   WHEN time.max_in - time.min_in < 1440 AND time.min_in >= 0 THEN max_i.max_intaketotal
   WHEN time.max_in != time.min_in THEN (max_i.max_intaketotal - min_i.min_intaketotal)/(time.max_in-time.min_in)*1440
   -- if only 1 measurement 
   WHEN max_i.max_intaketotal > 0 THEN max_i.max_intaketotal
   ELSE 0
  END as adjusted_input
FROM
  maximum_intake AS max_i
JOIN
  minimum_intake AS min_i
ON
  max_i.patientunitstayid = min_i.patientunitstayid
JOIN 
  time 
ON max_i.patientunitstayid = time.patientunitstayid
