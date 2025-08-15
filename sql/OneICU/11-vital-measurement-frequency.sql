with
    stayed_more_than_1_day as (
        select
            icu_stay_id,
            cast(timestamp_diff(out_time, in_time, minute) as int64)
            / 60 as icu_stay_hour,
            time,
            coalesce(bt_core, bt_surface) as bt,
            hr,
            rr,
            invasive_sbp,
            invasive_mbp,
            invasive_dbp,
            non_invasive_sbp,
            non_invasive_mbp,
            non_invasive_dbp,
            spo2
        from `medicu-biz.snapshots_one_icu.vital_measurements_20250716`
        inner join
            `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using (icu_stay_id)
        where icu_length_of_stay >= 1 and time >= in_time and time < out_time
        and icu_admission_year <= 2024
    ),
    vital_count as (
        select
            icu_stay_id,
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
        from stayed_more_than_1_day
        group by icu_stay_id, icu_stay_hour
    )
select
    icu_stay_id as pid,
    round(bt_count / icu_stay_hour, 1) as bt_per_hour,
    round(hr_count / icu_stay_hour, 1) as hr_per_hour,
    round(rr_count / icu_stay_hour, 1) as rr_per_hour,
    round(invasive_bp_count / icu_stay_hour, 1) as invasive_bp_per_hour,
    round(non_invasive_bp_count / icu_stay_hour, 1) as non_invasive_bp_per_hour,
    round(spo2_count / icu_stay_hour, 1) as spo2_per_hour
from vital_count
