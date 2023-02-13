-- Dobutamine patient list
-- Xiaoli Liu, Arnaud Petit, Dana Moukheiber
with infusiondrug_new_0 as (
    select
        infusiondrugid,
        patientunitstayid,
        infusionoffset,
        drugname,
        cast(drugrate as numeric) as drugrate,
        infusionrate,
        drugamount,
        volumeoffluid,
        patientweight
    from
        `physionet-data.eicu_crd.infusiondrug`
    where
        (
            drugname like '%Dobutamine%'
            or drugname like '%DOBUTamine%'
        )
        and drugrate != ''
)
SELECT
    DISTINCT(patientunitstayid)
FROM
    infusiondrug_new_0