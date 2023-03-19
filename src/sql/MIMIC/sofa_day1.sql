 SELECT scorecomp.*
        -- Respiration
        , CASE
            WHEN pao2fio2ratio_vent < 100 THEN 4
            WHEN pao2fio2ratio_vent < 200 THEN 3
            WHEN pao2fio2ratio_novent < 300 THEN 2
            WHEN pao2fio2ratio_vent < 300 THEN 2
            WHEN pao2fio2ratio_novent < 400 THEN 1
            WHEN pao2fio2ratio_vent < 400 THEN 1
            WHEN
                COALESCE(
                    pao2fio2ratio_vent, pao2fio2ratio_novent
                ) IS NULL THEN null
            ELSE 0
        END AS respiration

        -- Coagulation
        , CASE
            WHEN platelet_min < 20 THEN 4
            WHEN platelet_min < 50 THEN 3
            WHEN platelet_min < 100 THEN 2
            WHEN platelet_min < 150 THEN 1
            WHEN platelet_min IS NULL THEN null
            ELSE 0
        END AS coagulation

        -- Liver
        , CASE
            -- Bilirubin checks in mg/dL
            WHEN bilirubin_max >= 12.0 THEN 4
            WHEN bilirubin_max >= 6.0 THEN 3
            WHEN bilirubin_max >= 2.0 THEN 2
            WHEN bilirubin_max >= 1.2 THEN 1
            WHEN bilirubin_max IS NULL THEN null
            ELSE 0
        END AS liver

        -- Cardiovascular
        , CASE
            WHEN rate_dopamine > 15
                OR rate_epinephrine > 0.1
                OR rate_norepinephrine > 0.1
                THEN 4
            WHEN rate_dopamine > 5
                OR rate_epinephrine <= 0.1
                OR rate_norepinephrine <= 0.1
                THEN 3
            WHEN rate_dopamine > 0
                OR rate_dobutamine > 0
                THEN 2
            WHEN meanbp_min < 70 THEN 1
            WHEN
                COALESCE(
                    meanbp_min
                    , rate_dopamine
                    , rate_dobutamine
                    , rate_epinephrine
                    , rate_norepinephrine
                ) IS NULL THEN null
            ELSE 0
        END AS cardiovascular

        -- Neurological failure (GCS)
        , CASE
            WHEN (gcs_min >= 13 AND gcs_min <= 14) THEN 1
            WHEN (gcs_min >= 10 AND gcs_min <= 12) THEN 2
            WHEN (gcs_min >= 6 AND gcs_min <= 9) THEN 3
            WHEN gcs_min < 6 THEN 4
            WHEN gcs_min IS NULL THEN null
            ELSE 0
        END AS cns

        -- Renal failure - high creatinine or low urine output
        , CASE
            WHEN (creatinine_max >= 5.0) THEN 4
            WHEN uo_24hr < 200 THEN 4
            WHEN (creatinine_max >= 3.5 AND creatinine_max < 5.0) THEN 3
            WHEN uo_24hr < 500 THEN 3
            WHEN (creatinine_max >= 2.0 AND creatinine_max < 3.5) THEN 2
            WHEN (creatinine_max >= 1.2 AND creatinine_max < 2.0) THEN 1
            WHEN COALESCE(uo_24hr, creatinine_max) IS NULL THEN null
            ELSE 0
        END AS renal
    FROM scorecomp
)

, score_final AS (
    SELECT s.*
        -- Combine all the scores to get SOFA
        -- Impute 0 if the score is missing
        -- the window function takes the max over the last 24 hours
        , COALESCE(
            MAX(respiration) OVER w
            , 0) AS respiration_24hours
        , COALESCE(
            MAX(coagulation) OVER w
            , 0) AS coagulation_24hours
        , COALESCE(
            MAX(liver) OVER w
            , 0) AS liver_24hours
        , COALESCE(
            MAX(cardiovascular) OVER w
            , 0) AS cardiovascular_24hours
        , COALESCE(
            MAX(cns) OVER w
            , 0) AS cns_24hours
        , COALESCE(
            MAX(renal) OVER w
            , 0) AS renal_24hours

        -- sum together data for final SOFA
        , COALESCE(
            MAX(respiration) OVER w
            , 0)
        + COALESCE(
            MAX(coagulation) OVER w
            , 0)
        + COALESCE(
            MAX(liver) OVER w
            , 0)
        + COALESCE(
            MAX(cardiovascular) OVER w
            , 0)
        + COALESCE(
            MAX(cns) OVER w
            , 0)
        + COALESCE(
            MAX(renal) OVER w
            , 0)
        AS sofa_24hours
    FROM scorecalc s
    WINDOW w AS
        (
            PARTITION BY stay_id
            ORDER BY hr
            ROWS BETWEEN 23 PRECEDING AND 0 FOLLOWING
        )
)
SELECT stay_id, max(sofa_24hours) as sofa_day1 FROM score_final
WHERE hr >= 0
group by stay_id
