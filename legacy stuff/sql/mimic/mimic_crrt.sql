WITH crrt_settings AS
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

SELECT * FROM crrt_settings