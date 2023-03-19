SELECT chartevents.*, icustays.intime,
ROW_NUMBER() OVER(PARTITION BY icustays.stay_id ORDER BY DATE_DIFF(charttime, intime, MINUTE) ASC) AS total_seq,
CASE WHEN DATE_DIFF(charttime, intime, MINUTE) >= -1440 AND DATE_DIFF(charttime, intime, MINUTE) < 1440   THEN 1
     WHEN DATE_DIFF(charttime, intime, MINUTE) >= 1440  AND DATE_DIFF(charttime, intime, MINUTE) < 1440*2 THEN 2
     ELSE NULL
END AS day
FROM physionet-data.mimiciv_icu.chartevents
LEFT JOIN physionet-data.mimiciv_icu.icustays 
ON chartevents.stay_id = icustays.stay_id
WHERE itemid = 225668 AND valuenum < 1000 and valuenum IS NOT NULL
),
lac_1 AS (

  SELECT 

    stay_id
  , MAX(valuenum) AS lactate_day1
  , COUNT(valuenum) AS lactate_freq_day1

  FROM lac
  WHERE day = 1
  GROUP BY stay_id
),

lac_2 AS (

  SELECT 

    stay_id
  , MAX(valuenum) AS lactate_day2
  , COUNT(valuenum) AS lactate_freq_day2

  FROM lac
  WHERE day = 2
  GROUP BY stay_id
)
