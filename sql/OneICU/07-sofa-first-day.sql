with
    first_day_sofa_per_patients as (
        select max(sofa_24hours) as sofa
        from `medicu-biz.snapshots_one_icu_derived.sofa_hourly_20250716`
        inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using(icu_stay_id)
        where
            sofa_24hours is not null
            and time_window_index >= 0
            and time_window_index < 24
            and icu_admission_year <= 2024
        group by icu_stay_id
    ),
    sofa_stats as (
        select distinct
            'sofa' as field_name,
            percentile_cont(sofa, 0.5) over () as median,
            percentile_cont(sofa, 0.25) over () as percentile_25,
            percentile_cont(sofa, 0.75) over () as percentile_75
        from first_day_sofa_per_patients
    ),
    sofa_missing as (
        select
            'sofa' as field_name,
            (
                select count(distinct icu_stay_id)
                from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
                where icu_admission_year <= 2024
            )
            - count(distinct icu_stay_id) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct icu_stay_id)
                        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
                        where icu_admission_year <= 2024
                    )
                    - count(distinct icu_stay_id)
                )
                / (
                    select count(distinct icu_stay_id)
                    from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion_missing
        from `medicu-biz.snapshots_one_icu_derived.sofa_hourly_20250716`
        inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using(icu_stay_id)
        where
            sofa_24hours is not null
            and time_window_index >= 0
            and time_window_index < 24
            and icu_admission_year <= 2024
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from sofa_stats
inner join sofa_missing using (field_name)
