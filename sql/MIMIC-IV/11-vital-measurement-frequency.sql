with
    stayed_more_than_1_day as (
        select
            stay_id,
            round(los_icu * 24, 1) as icu_stay_hour,
            charttime as time,
            temperature as bt,
            heart_rate as hr,
            resp_rate as rr,
            sbp as invasive_sbp,
            mbp as invasive_mbp,
            dbp as invasive_dbp,
            sbp_ni as non_invasive_sbp,
            mbp_ni as non_invasive_mbp,
            dbp_ni as non_invasive_dbp,
            spo2,
        from `mimiciv_derived.vitalsign`
        inner join `mimiciv_derived.icustay_detail` using (stay_id)
        where los_icu >= 1
    ),
    vital_count as (
        select
            stay_id,
            icu_stay_hour,
            count(bt) as bt_count,
            count(hr) as hr_count,
            count(rr) as rr_count,
            countif(
                invasive_sbp is not null
                and invasive_mbp is not null
                and invasive_dbp is not null
            ) as invasive_bp_count,
            countif(
                non_invasive_sbp is not null
                and non_invasive_mbp is not null
                and non_invasive_dbp is not null
            ) as non_invasive_bp_count,
            count(spo2) as spo2_count,
        -- icu_stay_hour
        from stayed_more_than_1_day
        group by stay_id, icu_stay_hour
    )
select
    stay_id as pid,
    round(bt_count / icu_stay_hour, 1) as bt_per_hour,
    round(hr_count / icu_stay_hour, 1) as hr_per_hour,
    round(rr_count / icu_stay_hour, 1) as rr_per_hour,
    round(invasive_bp_count / icu_stay_hour, 1) as invasive_bp_per_hour,
    round(non_invasive_bp_count / icu_stay_hour, 1) as non_invasive_bp_per_hour,
    round(spo2_count / icu_stay_hour, 1) as spo2_per_hour
from vital_count
