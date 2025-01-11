with
    apache2_stats as (
        select distinct
            'apache2_score' as field_name,
            percentile_cont(apache2_score, 0.5) over () as median,
            percentile_cont(apache2_score, 0.25) over () as percentile_25,
            percentile_cont(apache2_score, 0.75) over () as percentile_75
        from `medicu-beta.latest_one_icu_derived.apache2`
        where apache2_score is not null
    ),
    apache2_missing as (
        select
            'apache2_score' as field_name,
            countif(apache2_score is null) as n_missing,
            round(
                100 * countif(apache2_score is null) / count(*), 1
            ) as proportion_missing
        from `medicu-beta.latest_one_icu_derived.apache2`
    ),
    apache3_stats as (
        select distinct
            'apache3_score' as field_name,
            percentile_cont(apache3_score, 0.5) over () as median,
            percentile_cont(apache3_score, 0.25) over () as percentile_25,
            percentile_cont(apache3_score, 0.75) over () as percentile_75
        from `medicu-beta.latest_one_icu_derived.apache3`
        where apache3_score is not null
    ),
    apache3_missing as (
        select
            'apache3_score' as field_name,
            countif(apache3_score is null) as n_missing,
            round(
                100 * countif(apache3_score is null) / count(*), 1
            ) as proportion_missing
        from `medicu-beta.latest_one_icu_derived.apache3`
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apache2_stats
inner join apache2_missing using (field_name)
union all
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apache3_stats
inner join apache3_missing using (field_name)
