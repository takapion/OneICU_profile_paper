with
    apsii_stats as (
        select distinct
            'apsii' as field_name,
            percentile_cont(apsii, 0.5) over () as median,
            percentile_cont(apsii, 0.25) over () as percentile_25,
            percentile_cont(apsii, 0.75) over () as percentile_75
        from `medicu-beta.snapshots_one_icu_derived.apache2_20250206`
        where apsii is not null
    ),
    apsii_missing as (
        select
            'apsii' as field_name,
            (
                select count(distinct icu_stay_id)
                from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
            )
            - count(distinct icu_stay_id) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct icu_stay_id)
                        from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                    )
                    - count(distinct icu_stay_id)
                )
                / (
                    select count(distinct icu_stay_id)
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion_missing
        from `medicu-beta.snapshots_one_icu_derived.apache2_20250206`
        where apsii is not null
    ),
    apsiii_stats as (
        select distinct
            'apsiii' as field_name,
            percentile_cont(apsiii, 0.5) over () as median,
            percentile_cont(apsiii, 0.25) over () as percentile_25,
            percentile_cont(apsiii, 0.75) over () as percentile_75
        from `medicu-beta.snapshots_one_icu_derived.apache3_20250206`
        where apsiii is not null
    ),
    apsiii_missing as (
        select
            'apsiii' as field_name,
            (
                select count(distinct icu_stay_id)
                from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
            )
            - count(distinct icu_stay_id) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct icu_stay_id)
                        from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                    )
                    - count(distinct icu_stay_id)
                )
                / (
                    select count(distinct icu_stay_id)
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion_missing
        from `medicu-beta.snapshots_one_icu_derived.apache3_20250206`
        where apsiii is not null
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apsii_stats
inner join apsii_missing using (field_name)
union all
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apsiii_stats
inner join apsiii_missing using (field_name)
