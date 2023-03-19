SELECT ce.stay_id, MIN(valuenum) as hemoglobin_stay_min --, valueuom --itemid
FROM  `physionet-data.mimiciv_icu.chartevents` ce
JOIN (SELECT DISTINCT subject_id, stay_id, intime, hadm_id from physionet-data.mimiciv_icu.icustays) icustays
ON ce.subject_id = icustays.subject_id
AND ce.hadm_id = icustays.hadm_id
WHERE itemid IN (220228) and valuenum IS NOT NULL --hem
AND DATE_DIFF(charttime, intime, MINUTE) > -1440 -- at least 1 day before the stay
GROUP BY stay_id 
ORDER BY stay_id
