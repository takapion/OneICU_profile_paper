with
    bg as (
        select
            pivoted_bg.icu_stay_id, pivoted_bg.time, pivoted_bg.ph, pivoted_bg.lactate,
        from
            (
                select icu_stay_id, time, field_name, value
                from `medicu-beta.latest_one_icu.blood_gas`
                where field_name in ('ph', 'lactate')
            )
            pivot (avg(value) for field_name in ('ph', 'lactate')) as pivoted_bg
    ),
    bg_count as (
        select icu_stay_id, count(ph) as ph_counts, count(lactate) as lactate_counts
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        left join bg using (icu_stay_id)
        where in_time <= time and time < out_time
        group by icu_stay_id
    ),
    lab as (
        select
            pivoted_lab.icu_stay_id,
            pivoted_lab.time,
            pivoted_lab.wbc,
            pivoted_lab.hemoglobin,
            pivoted_lab.sodium,
            pivoted_lab.albumin,
            pivoted_lab.international_normalized_ratio_of_prothrombin_time as inr,
            pivoted_lab.d_dimer,
        from
            (
                select icu_stay_id, time, field_name, value
                from `medicu-beta.latest_one_icu.laboratory_tests_blood`
                where
                    field_name in (
                        'wbc',
                        'hemoglobin',
                        'sodium',
                        'albumin',
                        'international_normalized_ratio_of_prothrombin_time',
                        'd_dimer'
                    )
            ) pivot (
                avg(value) for field_name in (
                    'wbc',
                    'hemoglobin',
                    'sodium',
                    'albumin',
                    'international_normalized_ratio_of_prothrombin_time',
                    'd_dimer'
                )
            ) as pivoted_lab
    ),
    lab_count as (
        select
            icu_stay_id,
            count(wbc) as wbc_counts,
            count(hemoglobin) as hemoglobin_counts,
            count(sodium) as sodium_counts,
            count(albumin) as albumin_counts,
            count(inr) as inr_counts,
            count(d_dimer) as d_dimer_counts
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        left join lab using (icu_stay_id)
        where in_time <= time and time < out_time
        group by icu_stay_id
    ),
    exact_stay_hour as (
        select
            icu_stay_id,
            cast(timestamp_diff(out_time, in_time, minute) as int64)
            / 60 as icu_stay_hour
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        where timestamp_diff(out_time, in_time, minute) >= 1440
    )
select
    icu_stay_id as pid,
    coalesce(round(24 * ph_counts / icu_stay_hour, 1), 0) as ph_per_day,
    coalesce(round(24 * lactate_counts / icu_stay_hour, 1), 0) as lactate_per_day,
    coalesce(round(24 * wbc_counts / icu_stay_hour, 1), 0) as wbc_per_day,
    coalesce(round(24 * hemoglobin_counts / icu_stay_hour, 1), 0) as hemoglobin_per_day,
    coalesce(round(24 * sodium_counts / icu_stay_hour, 1), 0) as sodium_per_day,
    coalesce(round(24 * albumin_counts / icu_stay_hour, 1), 0) as albumin_per_day,
    coalesce(round(24 * inr_counts / icu_stay_hour, 1), 0) as inr_per_day,
    coalesce(round(24 * d_dimer_counts / icu_stay_hour, 1), 0) as d_dimer_per_day
from exact_stay_hour
left join bg_count using (icu_stay_id)
left join lab_count using (icu_stay_id)
