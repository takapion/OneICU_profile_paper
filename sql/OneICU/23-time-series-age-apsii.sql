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
        from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
        where age is not null
    ),
    apsii_stats as (
        select distinct
            icu_admission_year,
            'apsii' as field_name,
            percentile_cont(apsii, 0.5) over (
                partition by icu_admission_year
            ) as median,
            percentile_cont(apsii, 0.25) over (
                partition by icu_admission_year
            ) as percentile_25,
            percentile_cont(apsii, 0.75) over (
                partition by icu_admission_year
            ) as percentile_75
        from `medicu-beta.snapshots_one_icu_derived.apache2_20250206`
        inner join
            `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206` using (icu_stay_id)
    )
select *
from age_stats
union all
select *
from apsii_stats
order by field_name, icu_admission_year
