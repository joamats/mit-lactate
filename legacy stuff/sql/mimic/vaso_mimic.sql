WITH four_vasopressors_itemid_amount_rate AS
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
)


SELECT stay_id, CAST(CAST(count(*) as BOOL) as int64) as vaso FROM  
vaso_indicator
GROUP BY stay_id
ORDER BY stay_id
