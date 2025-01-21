with
    apsiii_stats as (
        select distinct
            'apsiii' as field_name,
            percentile_cont(apsiii, 0.5) over () as median,
            percentile_cont(apsiii, 0.25) over () as percentile_25,
            percentile_cont(apsiii, 0.75) over () as percentile_75
        from `mimiciv_derived.apsiii`
        where apsiii is not null
    ),
    apsiii_missing as (
        select
            'apsiii' as field_name,
            (select count(distinct stay_id) from `mimiciv_derived.icustay_detail`)
            - count(distinct stay_id) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct stay_id)
                        from `mimiciv_derived.icustay_detail`
                    )
                    - count(distinct stay_id)
                )
                / (
                    select count(distinct stay_id) from `mimiciv_derived.icustay_detail`
                ),
                1
            ) as proportion_missing
        from `mimiciv_derived.apsiii`
        where apsiii is not null
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apsiii_stats
inner join apsiii_missing using (field_name)
