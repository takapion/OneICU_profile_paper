with
    apsii_stats as (
        select distinct
            'apsii' as field_name,
            percentile_cont(apsii, 0.5) over () as median,
            percentile_cont(apsii, 0.25) over () as percentile_25,
            percentile_cont(apsii, 0.75) over () as percentile_75
        from `medicu-biz.latest_one_icu_derived.apache2`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where apsii is not null and icu_admission_year <= 2024
    ),
    apsii_missing as (
        select
            'apsii' as field_name,
            (
                select count(distinct icu_stay_id)
                from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                where icu_admission_year <= 2024
            )
            - count(distinct icu_stay_id) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct icu_stay_id)
                        from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                        where icu_admission_year <= 2024
                    )
                    - count(distinct icu_stay_id)
                )
                / (
                    select count(distinct icu_stay_id)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion_missing
        from `medicu-biz.latest_one_icu_derived.apache2`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where apsii is not null and icu_admission_year <= 2024
    ),
    apsiii_stats as (
        select distinct
            'apsiii' as field_name,
            percentile_cont(apsiii, 0.5) over () as median,
            percentile_cont(apsiii, 0.25) over () as percentile_25,
            percentile_cont(apsiii, 0.75) over () as percentile_75
        from `medicu-biz.latest_one_icu_derived.apache3`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where apsiii is not null and icu_admission_year <= 2024
    ),
    apsiii_missing as (
        select
            'apsiii' as field_name,
            (
                select count(distinct icu_stay_id)
                from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                where icu_admission_year <= 2024
            )
            - count(distinct icu_stay_id) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct icu_stay_id)
                        from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                        where icu_admission_year <= 2024
                    )
                    - count(distinct icu_stay_id)
                )
                / (
                    select count(distinct icu_stay_id)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion_missing
        from `medicu-biz.latest_one_icu_derived.apache3`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where apsiii is not null and icu_admission_year <= 2024
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apsii_stats
inner join apsii_missing using (field_name)
union all
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apsiii_stats
inner join apsiii_missing using (field_name)
