WITH sepsis3_stays as (
    SELECT sepsis3.*, icustays.intime
    FROM physionet-data.mimiciv_derived.sepsis3 sepsis3
    JOIN (SELECT DISTINCT subject_id, stay_id, intime from physionet-data.mimiciv_icu.icustays) icustays  --stay_id -> intime (1-1 relation)
    ON sepsis3.subject_id = icustays.subject_id
    AND sepsis3.stay_id = icustays.stay_id
  ),

  first_icu_stay as (
    SELECT subject_id, min(intime) as first_intime   --one subject_id -> many stay_id -> intime 
    FROM sepsis3_stays
    GROUP BY subject_id
  ),

  first_icu_stay_sepsis as (
    SELECT sepsis3_stays.*, first_icu_stay.first_intime
    FROM sepsis3_stays
    JOIN first_icu_stay 
    ON sepsis3_stays.subject_id = first_icu_stay.subject_id
    AND sepsis3_stays.intime = first_icu_stay.first_intime -- join on where intime matches on first_intime only
  ),

  icu_mort as (    --whether subject died in the icu
SELECT ie.subject_id, ie.hadm_id, ie.stay_id, adm.race
--, adm.hospital_expire_flag
, CASE when adm.deathtime between ie.intime and ie.outtime THEN 1 ELSE 0 END AS mort_icu
-- icu level factors
, ie.intime, ie.outtime
, ie.FIRST_CAREUNIT AS first_careunit
, DATETIME_DIFF(ie.outtime, ie.intime, DAY) AS los_icu
, pat.anchor_age
, pat.gender
FROM `physionet-data.mimiciv_icu.icustays` ie
LEFT JOIN `physionet-data.mimiciv_hosp.admissions` adm
    ON ie.hadm_id = adm.hadm_id
LEFT JOIN `physionet-data.mimiciv_hosp.patients` pat
    ON ie.subject_id = pat.subject_id
WHERE adm.race NOT IN ("UNKNOWN", "OTHER", "UNABLE TO OBTAIN")
  )

, final_table as 
(SELECT sepsis.subject_id
  --, chart.hadm_id
  , sepsis.stay_id
  , icu_mort.anchor_age
  , icu_mort.gender
  , charlson.charlson_comorbidity_index
  , icu_mort.mort_icu
  , icu_mort.race
  , min(ifnull(valuenum, 0)) as min_lactate_24_hr
  , max(ifnull(valuenum, 0)) as max_lactate_24_hr
  , avg(ifnull(valuenum, 0)) as avg_lactate_24_hr
  , STDDEV_POP(ifnull(valuenum, 0)) as std_lactate_24_hr   --WHERE lactate !=max_lactate
  , avg(ifnull(POWER(valuenum,3), 0)) as m_3
  , avg(ifnull(POWER(valuenum,4), 0)) as m_4
  , count(ifnull(valuenum, 0)) as n_measurements
  FROM first_icu_stay_sepsis sepsis
  LEFT JOIN (
    SELECT chartevents.*, icustays.intime
    FROM physionet-data.mimiciv_icu.chartevents
    LEFT JOIN physionet-data.mimiciv_icu.icustays 
    ON chartevents.stay_id = icustays.stay_id
      WHERE itemid = 225668 AND valuenum < 1000 --exclude lactate values that are greater than 1000
  AND DATE_DIFF(charttime, intime, HOUR) <= 24.0 ) chart -- limited to first 24 hours in ICU
  ON chart.subject_id = sepsis.subject_id
  AND chart.stay_id = sepsis.stay_id
  LEFT JOIN icu_mort
  ON sepsis.subject_id = icu_mort.subject_id
  AND sepsis.stay_id = icu_mort.stay_id
  left join (SELECT charlson.* , icustays.stay_id
              FROM `physionet-data.mimiciv_derived.charlson` as charlson
              JOIN (SELECT DISTINCT subject_id, stay_id, hadm_id from physionet-data.mimiciv_icu.icustays) icustays
              ON charlson.subject_id = icustays.subject_id
              AND charlson.hadm_id = icustays.hadm_id) charlson
  on sepsis.subject_id = charlson.subject_id
  AND sepsis.stay_id = charlson.stay_id
  GROUP BY sepsis.subject_id
  --, chart.hadm_id
  , sepsis.stay_id  
  , icu_mort.anchor_age
  , icu_mort.gender
  , charlson.charlson_comorbidity_index
  , icu_mort.mort_icu
  , icu_mort.race),

four_vasopressors_itemid_amount_rate AS
( 
  SELECT stay_id, 
        linkorderid,
        rate as vaso_rate,
        amount as vaso_amount,
        starttime,
        endtime,
        itemid
from `physionet-data.mimiciv_icu.inputevents`
where itemid in (221906,221289, 229617,221662,221749)
) -- norepinephrine,epinephrine,dopamine,phenylephrine

, add_label_column_to_four_vasopressors_from_d_items_table AS
(
    SELECT four_vasopressors_itemid_amount_rate.*, `physionet-data.mimiciv_icu.d_items`.*EXCEPT(itemid) 
        FROM four_vasopressors_itemid_amount_rate 
    LEFT JOIN `physionet-data.mimiciv_icu.d_items` 
        ON four_vasopressors_itemid_amount_rate.itemid = `physionet-data.mimiciv_icu.d_items`.itemid
)

, vaso_indicator AS (SELECT
    stay_id,
    label,
    CASE WHEN label IS NOT NULL THEN 1 ELSE 0 END AS vaso,
    FROM 
    add_label_column_to_four_vasopressors_from_d_items_table 
),

vaso_ as (SELECT final_table.stay_id, CAST(CAST(count(*) as BOOL) as int64) as vaso FROM  
vaso_indicator
RIGHT JOIN final_table ON final_table.stay_id = vaso_indicator.stay_id
GROUP BY final_table.stay_id
ORDER BY vaso ASC),

crrt_settings AS
(
  SELECT  ce.stay_id,
          max(
          CASE
                    WHEN ce.itemid IN ( 224144, -- Blood Flow (ml/min)
                                        224191  -- Hourly Patient Fluid Removal    
                                      ) THEN 1
                    ELSE 0
          END ) AS crrt
  FROM     `physionet-data.mimiciv_icu.chartevents` ce
  WHERE    ce.value IS NOT NULL and ce.itemid IN (224144, 224191) 
  AND      ce.valuenum IS NOT NULL AND  ce.valuenum >0
  GROUP BY stay_id)
  --ORDER BY max_lactate_24_hr DESC -- 32 greatest lactate value

--  f.charlson_comorbidity_index
SELECT  f.anchor_age as age, f.gender, m.short_v as ethnicity, f.mort_icu, f.n_measurements, f.min_lactate_24_hr, f.max_lactate_24_hr, f.avg_lactate_24_hr, f.m_3, f.m_4, f.std_lactate_24_hr, f.charlson_comorbidity_index cci, vaso_.vaso, CASE WHEN crrt_settings.crrt = 1 THEN 1 ELSE 0 END as crrt
FROM final_table as f
JOIN `something-355717.map_race.mappppp` as m
ON f.race = m.race
JOIN vaso_ on vaso_.stay_id = f.stay_id
LEFT JOIN crrt_settings on crrt_settings.stay_id = f.stay_id
ORDER BY f.n_measurements DESC
