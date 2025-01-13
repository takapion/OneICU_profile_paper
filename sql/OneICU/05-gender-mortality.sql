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
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
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
                when mortality = 'er'
                then 'ER_death'
                when mortality is null
                then 'ER_mortality_unknown'
                else 'ER_survived'
            end as er_mortality
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
    ),
    er_mortality_counts as (
        select er_mortality as field_name, count(*) as count
        from er_mortality_clean
        group by er_mortality
    ),
    er_mortality_proportions as (
        select
            field_name,
            count,
            round(
                100 * count / (select sum(count) from er_mortality_counts), 1
            ) as proportion
        from er_mortality_counts
    ),
    mortality_clean as (
        select
            case
                when mortality = 'icu'
                then 'ICU_death'
                when mortality is null
                then 'ICU_mortality_unknown'
                else 'ICU_survived'
            end as icu_death,
            case
                when mortality in ('icu', 'in_hospital')
                then 'In_hospital_death'
                when mortality is null
                then 'In_hospital_mortality_unknown'
                else 'In_hospital_survived'
            end as in_hospital_death
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        where mortality is null or mortality != 'er'
    ),
    icu_mortality_counts as (
        select icu_death as field_name, count(*) as count
        from mortality_clean
        group by icu_death
    ),
    icu_mortality_proportions as (
        select
            field_name,
            count,
            round(
                100 * count / (select sum(count) from icu_mortality_counts), 1
            ) as proportion
        from icu_mortality_counts
    ),
    in_hospital_mortality_counts as (
        select in_hospital_death as field_name, count(*) as count
        from mortality_clean
        group by in_hospital_death
    ),
    in_hospital_mortality_proportions as (
        select
            field_name,
            count,
            round(
                100 * count / (select sum(count) from in_hospital_mortality_counts), 1
            ) as proportion
        from in_hospital_mortality_counts
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
