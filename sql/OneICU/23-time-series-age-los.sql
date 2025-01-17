with
    age_stats as (
        select distinct
            icu_admission_year,
            'age' as field_name,
            percentile_cont(age, 0.5) over (partition by icu_admission_year) as median,
            percentile_cont(age, 0.25) over (
                partition by icu_admission_year
            ) as percentile_25,
            percentile_cont(age, 0.75) over (
                partition by icu_admission_year
            ) as percentile_75
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        where age is not null
    ),
    los_prep as (
        select
            icu_admission_year,
            round(
                cast(timestamp_diff(out_time, in_time, hour) as int64) / 24, 1
            ) as icu_los
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        where out_time is not null
    ),
    los_stats as (
        select distinct
            icu_admission_year,
            'los' as field_name,
            percentile_cont(icu_los, 0.5) over (
                partition by icu_admission_year
            ) as median,
            percentile_cont(icu_los, 0.25) over (
                partition by icu_admission_year
            ) as percentile_25,
            percentile_cont(icu_los, 0.75) over (
                partition by icu_admission_year
            ) as percentile_75
        from los_prep
    )
select *
from age_stats
union all
select *
from los_stats
order by field_name, icu_admission_year
