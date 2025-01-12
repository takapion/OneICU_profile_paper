with
    apache3_stats as (
        select distinct
            'apache3' as field_name,
            percentile_cont(apsiii, 0.5) over () as median,
            percentile_cont(apsiii, 0.25) over () as percentile_25,
            percentile_cont(apsiii, 0.75) over () as percentile_75
        from `mimiciv_derived.apsiii`
        where apsiii is not null
    ),
    apache3_missing as (
        select
            'apache3' as field_name,
            countif(apsiii is null) as n_missing,
            round(100 * countif(apsiii is null) / count(*), 1) as proportion_missing
        from `mimiciv_derived.apsiii`
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apache3_stats
inner join apache3_missing using (field_name)
