with
    gender_clean as (
        select
            case
                when female = 0
                then 'male'
                when female = 1
                then 'female'
                else 'gender_unknown'
            end as gender
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where icu_admission_year <= 2024
    ),
    gender_counts as (
        select gender as field_name, count(*) as count from gender_clean group by gender
    ),
    gender_proportions as (
        select
            field_name,
            count,
            round(100 * count / (select sum(count) from gender_counts), 1) as proportion
        from gender_counts
    ),
    er_mortality_clean as (
        select
            case
                when er_mortality then 'ER_death'
                when er_mortality is false then 'ER_survived'
                else 'ER_mortality_unknown'
            end as er_death,
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where icu_admission_year <= 2024
    ),
    er_mortality_proportions as (
        select
          er_death as field_name,
          count(*) as count,
          round(count(*) * 100 / sum(count(*)) over (), 1) as proportion
        from er_mortality_clean
        group by er_death
    ),
    mortality_clean as (
        select
            case
                when icu_mortality then 'ICU_death'
                when icu_mortality is false then 'ICU_survived'
                else 'ICU_mortality_unknown'
            end as icu_death,
            case
                when mortality in ('icu', 'in_hospital')
                then 'In_hospital_death'
                when mortality is null
                then 'In_hospital_mortality_unknown'
                else 'In_hospital_survived'
            end as in_hospital_death
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where er_mortality is not TRUE
        and icu_admission_year <= 2024
    ),
    icu_mortality_proportions as (
        select
          icu_death as field_name,
          count(*) as count,
          round(count(*) * 100 / sum(count(*)) over (), 1) as proportion
        from mortality_clean
        group by icu_death
    ),
    in_hospital_mortality_proportions as (
        select
          in_hospital_death as field_name,
          count(*) as count,
          round(count(*) * 100 / sum(count(*)) over (), 1) as proportion
        from mortality_clean
        group by in_hospital_death
    )
select *
from gender_proportions
union all
select *
from er_mortality_proportions
union all
select *
from icu_mortality_proportions
union all
select *
from in_hospital_mortality_proportions
order by field_name
