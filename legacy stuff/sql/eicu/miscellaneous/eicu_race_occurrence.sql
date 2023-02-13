WITH
  table_ AS (
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
    ethnicity,
    unitDischargeStatus,
    hospitalDischargeStatus,
    unitDischargeOffset
  FROM
    `physionet-data.eicu_crd.patient`
  WHERE
    unitVisitNumber = 1),
  table_counts AS (
  SELECT
    uniquepid,
    COUNT(DISTINCT(ethnicity)) AS occ
  FROM
    table_
  GROUP BY
    uniquepid
  ORDER BY
    occ DESC)
SELECT
  a.uniquepid as id,
  a.ethnicity,
  b.occ as occ
FROM
  table_ AS a
JOIN
  table_counts AS b
ON
  a.uniquepid = b.uniquepid
ORDER BY
  occ DESC,
  id DESC