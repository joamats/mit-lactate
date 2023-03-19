weight as (select stay_id,valuenum as weight_kg from `physionet-data.mimiciv_icu.chartevents`
where itemid in 
(SELECT itemid FROM `physionet-data.mimiciv_icu.d_items` 
where lower(label) like '%admission weight (kg)%')
order by stay_id
