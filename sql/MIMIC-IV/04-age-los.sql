with
    age_stats as (
        select distinct
            'age' as field_name,
            floor(percentile_cont(admission_age, 0.5) over ()) as median,
            floor(percentile_cont(admission_age, 0.25) over ()) as percentile_25,
            floor(percentile_cont(admission_age, 0.75) over ()) as percentile_75
        from `mimiciv_derived.icustay_detail`
        where admission_age is not null
    ),
    age_missing as (
        select
            'age' as field_name,
            countif(admission_age is null) as n_missing,
            round(
                100 * countif(admission_age is null) / count(*), 1
            ) as proportion_missing
        from `mimiciv_derived.icustay_detail`
    ),
    los_stats as (
        select distinct
            'los' as field_name,
            round(percentile_cont(los_icu, 0.5) over (), 1) as median,
            round(percentile_cont(los_icu, 0.25) over (), 1) as percentile_25,
            round(percentile_cont(los_icu, 0.75) over (), 1) as percentile_75
        from `mimiciv_derived.icustay_detail`
        where los_icu is not null
    ),
    los_missing as (
        select
            'los' as field_name,
            countif(los_icu is null) as n_missing,
            round(100 * countif(los_icu is null) / count(*), 1) as proportion_missing
        from `mimiciv_derived.icustay_detail`
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from age_stats
inner join age_missing using (field_name)
union all
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from los_stats
inner join los_missing using (field_name)
