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
    mortality_stats as (
        select
            case
                when mortality = 'er'
                then 'ER_death'
                when mortality = 'icu'
                then 'ICU_death'
                when mortality = 'in_hospital'
                then 'In_hospital_death'
                when mortality is null
                then 'mortality_unknown'
                else mortality
            end as mortality
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
    ),
    mortality_counts as (
        select mortality as field_name, count(*) as count
        from mortality_stats
        group by mortality
    ),
    mortality_proportions as (
        select
            field_name,
            count,
            round(
                100 * count / (select sum(count) from mortality_counts), 1
            ) as proportion
        from mortality_counts
    )
select *
from gender_proportions
union all
select *
from mortality_proportions
