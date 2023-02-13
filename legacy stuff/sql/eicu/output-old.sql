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
    io.Outputtotal AS max_OutputTotal,
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
    io.OutputTotal AS min_OutputTotal,
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
   WHEN time.max_in != time.min_in THEN (max_i.max_OutputTotal - min_i.min_OutputTotal)/(time.max_in-time.min_in)*2880
   WHEN max_i.max_OutputTotal > 0 THEN max_i.max_OutputTotal
   ELSE 0
  END as adjusted_output
FROM
  maximum_intake AS max_i
JOIN
  minimum_intake AS min_i
ON
  max_i.patientunitstayid = min_i.patientunitstayid
JOIN 
  time 
ON max_i.patientunitstayid = time.patientunitstayid
