/* dialysis
 
 
 cvvh : Continuous Veno-Venous Hemofiltration
 cvvhdf : Continuous veno-venous hemodiafiltration
 cvvhd : Continuous Veno-Venous Hemodialysis
 cavh : continuous arteriovenous hemofiltration
 
 Xiaoli Liu, Arnaud Petit, Dana Moukheiber
 */
WITH dialysis_chart_tmp AS (
  SELECT
    DISTINCT patientunitstayid as icustay_id,
    treatmentoffset AS charttime,
    1 AS label,
    'treatment' AS linksto
  FROM
    `physionet-data.eicu_crd.treatment` --treatmentstring
  WHERE
    LOWER(treatmentstring) LIKE '%dialysis%'
    or (
      (
        LOWER(treatmentstring) LIKE '%cvvhd%'
        or LOWER(treatmentstring) LIKE '%cvvdh%'
      )
      and (LOWER(treatmentstring) not LIKE '%cvvdhf%')
    )
    AND patientunitstayid is not null
  UNION
  ALL
  SELECT
    DISTINCT patientunitstayid as icustay_id,
    intakeoutputoffset AS charttime,
    1 AS label,
    'intakeoutput' AS linksto
  FROM
    `physionet-data.eicu_crd.intakeoutput` --cellpath
  WHERE
    LOWER(cellpath) LIKE '%dialysis%'
    or (
      (
        LOWER(cellpath) LIKE '%cvvhd%'
        or LOWER(cellpath) LIKE '%cvvdh%'
      )
      and (LOWER(cellpath) not LIKE '%cvvdhf%')
    )
    AND patientunitstayid is not null
  UNION
  ALL
  SELECT
    DISTINCT patientunitstayid as icustay_id,
    noteoffset AS charttime,
    1 AS label,
    'note' AS linksto
  FROM
    `physionet-data.eicu_crd.note` --cellpath
  WHERE
    (
      LOWER(noteText) LIKE '%dialysis%'
      OR LOWER(noteType) LIKE '%dialysis%'
      OR LOWER(notePath) LIKE '%dialysis%'
      OR LOWER(noteValue) LIKE '%dialysis%'
      or LOWER(noteText) LIKE '%cvvhd%'
      or LOWER(noteType) LIKE '%cvvhd%'
      OR LOWER(notePath) LIKE '%cvvhd%'
      or LOWER(noteValue) LIKE '%cvvhd%'
      OR LOWER(noteText) LIKE '%cvvdh%'
      or LOWER(noteType) LIKE '%cvvdh%'
      OR LOWER(notePath) LIKE '%cvvdh%'
      or LOWER(noteValue) LIKE '%cvvdh%'
    ) --and (LOWER(noteText) not LIKE '%cvvdhf%' and LOWER(noteType) not LIKE '%cvvdhf%' and LOWER(notePath) not LIKE '%cvvdhf%' and LOWER(noteValue) not LIKE '%cvvdhf%')
    AND patientunitstayid is not null --AND dialysistotal != 0
    --AND LOWER(cellpath) LIKE '%chronic%'
    --GROUP BY patientunitstayid
    -- -> 0
    --LOWER(noteText) not LIKE '%cvvhd%' or LOWER(noteType) not LIKE '%cvvhd%' OR LOWER(notePath) not LIKE '%cvvhd%' or LOWER(noteValue) not LIKE '%cvvhd%' OR
    --LOWER(noteText) not LIKE '%cvvdh%' or LOWER(noteType) not LIKE '%cvvdh%' OR LOWER(notePath) not LIKE '%cvvdh%' or LOWER(noteValue) not LIKE '%cvvdh%')
    --and (LOWER(noteText)  LIKE '%cvvdhf%' and LOWER(noteType) LIKE '%cvvdhf%' and LOWER(notePath) LIKE '%cvvdhf%' and LOWER(noteValue) LIKE '%cvvdhf%')
    --AND patientunitstayid is not null
)
SELECT
  DISTINCT(dialysis_chart_tmp.icustay_id), dialysis_chart_tmp.label as crrt
FROm
  dialysis_chart_tmp
