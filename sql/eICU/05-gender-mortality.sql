with
    gender_clean as (
        select
            case
                when gender = 1
                then 'male'
                when gender = 0
                then 'female'
                else 'gender_unknown'
            end as gender
        from `physionet-data.eicu_crd_derived.icustay_detail`
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
    mortality_clean as (
        select
            case
                when unitdischargestatus = 'Expired'
                then 'ICU_death'
                when unitdischargestatus = 'Alive'
                then 'ICU_survived'
                else 'ICU_mortality_unknown'
            end as icu_death,
            case
                when hospitaldischargestatus = 'Expired'
                then 'In_hospital_death'
                when hospitaldischargestatus = 'Alive'
                then 'In_hospital_survived'
                else 'In_hospital_mortality_unknown'
            end as in_hospital_death
        from `physionet-data.eicu_crd.patient`
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
from icu_mortality_proportions
union all
select *
from in_hospital_mortality_proportions
