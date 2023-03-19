WITH transf as (
SELECT ce.stay_id --, amount --, valueuom --itemid
, max(
          CASE
                    WHEN ce.itemid IN ( 226368, 227070, 220996, 221013,226370
                                      ) THEN 1
                    ELSE 0
          END ) AS transfusion_yes
FROM  `physionet-data.mimiciv_icu.inputevents` ce
WHERE itemid IN (226368, 227070, 220996, 221013,226370) 
and amount is NOT NULL and amount >0 
GROUP BY stay_id
),
fluids as (
SELECT ce.stay_id --, amount --, valueuom --itemid
, max(
          CASE
                    WHEN ce.itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863
                                      ) THEN 1
                    ELSE 0
          END ) AS fluids_yes
FROM  `physionet-data.mimiciv_icu.inputevents` ce
WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
and amount is NOT NULL and amount >0 
GROUP BY stay_id
),

rrt as (WITH 
crrt_settings AS
(SELECT  ce.stay_id,
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
  SELECT stay_id, crrt as rrt_overall_yes FROM crrt_settings)
