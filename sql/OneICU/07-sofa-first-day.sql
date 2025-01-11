with
    first_day_sofa_per_patients as (
        select max(sofa_24hours) as sofa
        from `medicu-beta.latest_one_icu_derived.sofa_hourly`
        where
            sofa_24hours is not null
            and time_window_index >= 0
            and time_window_index < 24
        group by icu_stay_id
    )
select distinct
    'sofa' as field_name,
    percentile_cont(sofa, 0.5) over () as median,
    percentile_cont(sofa, 0.25) over () as percentile_25,
    percentile_cont(sofa, 0.75) over () as percentile_75
from first_day_sofa_per_patients
