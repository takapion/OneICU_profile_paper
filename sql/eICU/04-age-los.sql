with
    age_clean as (
        select case when age = '> 89' then 89 else safe_cast(age as int64) end as age
        from `physionet-data.eicu_crd_derived.icustay_detail`
    ),
    age_stats as (
        select distinct
            'age' as field_name,
            percentile_cont(age, 0.5) over () as median,
            percentile_cont(age, 0.25) over () as percentile_25,
            percentile_cont(age, 0.75) over () as percentile_75,
        from age_clean
        where age is not null
    ),
    age_missing as (
        select
            'age' as field_name,
            countif(age is null) as n_missing,
            round(100 * countif(age is null) / count(*), 1) as proportion_missing
        from age_clean
    ),
    los_stats as (
        select distinct
            'los' as field_name,
            percentile_cont(round(icu_los_hours / 24, 1), 0.5) over () as median,
            percentile_cont(round(icu_los_hours / 24, 1), 0.25) over (
            ) as percentile_25,
            percentile_cont(round(icu_los_hours / 24, 1), 0.75) over () as percentile_75
        from `physionet-data.eicu_crd_derived.icustay_detail`
        where icu_los_hours is not null
    ),
    los_missing as (
        select
            'los' as field_name,
            countif(icu_los_hours is null) as n_missing,
            round(
                100 * countif(icu_los_hours is null) / count(*), 1
            ) as proportion_missing
        from `physionet-data.eicu_crd_derived.icustay_detail`
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from age_stats
inner join age_missing using (field_name)
union all
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from los_stats
inner join los_missing using (field_name)
