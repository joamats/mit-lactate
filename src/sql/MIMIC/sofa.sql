   SELECT ih.stay_id, ie.hadm_id
        , hr
        -- start/endtime can be used to filter to values within this hour
        , DATETIME_SUB(ih.endtime, INTERVAL '1' HOUR) AS starttime
        , ih.endtime
    FROM `physionet-data.mimiciv_derived.icustay_hourly` ih
    INNER JOIN `physionet-data.mimiciv_icu.icustays` ie
        ON ih.stay_id = ie.stay_id
)

, pafi AS (
    -- join blood gas to ventilation durations to determine if patient was vent
    SELECT ie.stay_id
        , bg.charttime
        -- because pafi has an interaction between vent/PaO2:FiO2,
        -- we need two columns for the score
        -- it can happen that the lowest unventilated PaO2/FiO2 is 68,
        -- but the lowest ventilated PaO2/FiO2 is 120
        -- in this case, the SOFA score is 3, not 4.
        , CASE
            WHEN vd.stay_id IS NULL THEN pao2fio2ratio ELSE null
        END AS pao2fio2ratio_novent
        , CASE
            WHEN vd.stay_id IS NOT NULL THEN pao2fio2ratio ELSE null
        END AS pao2fio2ratio_vent
    FROM `physionet-data.mimiciv_icu.icustays` ie
    INNER JOIN `physionet-data.mimiciv_derived.bg` bg
        ON ie.subject_id = bg.subject_id
    LEFT JOIN `physionet-data.mimiciv_derived.ventilation` vd
        ON ie.stay_id = vd.stay_id
            AND bg.charttime >= vd.starttime
            AND bg.charttime <= vd.endtime
            AND vd.ventilation_status = 'InvasiveVent'
    WHERE specimen = 'ART.'
)

, vs AS (

    SELECT co.stay_id, co.hr
        -- vitals
        , MIN(vs.mbp) AS meanbp_min
    FROM co
    LEFT JOIN `physionet-data.mimiciv_derived.vitalsign` vs
        ON co.stay_id = vs.stay_id
            AND co.starttime < vs.charttime
            AND co.endtime >= vs.charttime
    GROUP BY co.stay_id, co.hr
)

, gcs AS (
    SELECT co.stay_id, co.hr
        -- gcs
        , MIN(gcs.gcs) AS gcs_min
    FROM co
    LEFT JOIN `physionet-data.mimiciv_derived.gcs` gcs
        ON co.stay_id = gcs.stay_id
            AND co.starttime < gcs.charttime
            AND co.endtime >= gcs.charttime
    GROUP BY co.stay_id, co.hr
)

, bili AS (
    SELECT co.stay_id, co.hr
        , MAX(enz.bilirubin_total) AS bilirubin_max
    FROM co
    LEFT JOIN `physionet-data.mimiciv_derived.enzyme` enz
        ON co.hadm_id = enz.hadm_id
            AND co.starttime < enz.charttime
            AND co.endtime >= enz.charttime
    GROUP BY co.stay_id, co.hr
)

, cr AS (    SELECT co.stay_id, co.hr
        , MAX(chem.creatinine) AS creatinine_max
    FROM co
    LEFT JOIN `physionet-data.mimiciv_derived.chemistry` chem
        ON co.hadm_id = chem.hadm_id
            AND co.starttime < chem.charttime
            AND co.endtime >= chem.charttime
    GROUP BY co.stay_id, co.hr
)

, plt AS (
    SELECT co.stay_id, co.hr
        , MIN(cbc.platelet) AS platelet_min
    FROM co
    LEFT JOIN `physionet-data.mimiciv_derived.complete_blood_count` cbc
        ON co.hadm_id = cbc.hadm_id
            AND co.starttime < cbc.charttime
            AND co.endtime >= cbc.charttime
    GROUP BY co.stay_id, co.hr
)

, pf AS (
    SELECT co.stay_id, co.hr
        , MIN(pafi.pao2fio2ratio_novent) AS pao2fio2ratio_novent
        , MIN(pafi.pao2fio2ratio_vent) AS pao2fio2ratio_vent
    FROM co
    -- bring in blood gases that occurred during this hour
    LEFT JOIN pafi
        ON co.stay_id = pafi.stay_id
            AND co.starttime < pafi.charttime
            AND co.endtime >= pafi.charttime
    GROUP BY co.stay_id, co.hr
)

-- sum uo separately to prevent duplicating values
, uo AS (
    SELECT co.stay_id, co.hr
        -- uo
        , MAX(
            CASE WHEN uo.uo_tm_24hr >= 22 AND uo.uo_tm_24hr <= 30
                THEN uo.urineoutput_24hr / uo.uo_tm_24hr * 24
            END) AS uo_24hr
    FROM co
    LEFT JOIN `physionet-data.mimiciv_derived.urine_output_rate` uo
        ON co.stay_id = uo.stay_id
            AND co.starttime < uo.charttime
            AND co.endtime >= uo.charttime
    GROUP BY co.stay_id, co.hr
)
