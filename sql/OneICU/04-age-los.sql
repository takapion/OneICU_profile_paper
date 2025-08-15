with
    age_stats as (
        select distinct
            'age' as field_name,
            percentile_cont(age, 0.5) over () as median,
            percentile_cont(age, 0.25) over () as percentile_25,
            percentile_cont(age, 0.75) over () as percentile_75
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where age is not null and icu_admission_year <= 2024
    ),
    age_missing as (
        select
            'age' as field_name,
            countif(age is null) as n_missing,
            round(100 * countif(age is null) / count(*), 1) as proportion_missing
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where icu_admission_year <= 2024
    ),
    los_prep as (
        select
            round(
                cast(timestamp_diff(out_time, in_time, hour) as int64) / 24, 1
            ) as icu_los
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where out_time is not null and icu_admission_year <= 2024
    ),
    los_stats as (
        select distinct
            'los' as field_name,
            percentile_cont(icu_los, 0.5) over () as median,
            percentile_cont(icu_los, 0.25) over () as percentile_25,
            percentile_cont(icu_los, 0.75) over () as percentile_75
        from los_prep
    ),
    los_missing as (
        select
            'los' as field_name,
            countif(out_time is null) as n_missing,
            round(100 * countif(out_time is null) / count(*), 1) as proportion_missing
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where icu_admission_year <= 2024
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from age_stats
inner join age_missing using (field_name)
union all
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from los_stats
inner join los_missing using (field_name)
