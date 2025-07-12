with
    mv as (
        select
            'mechanical_ventilation' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion
        from `medicu-biz.latest_one_icu.mechanical_ventilations`
    ),
    nppv as (
        select
            'nppv' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion
        from `medicu-biz.latest_one_icu.non_invasive_positive_pressure_ventilations`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where icu_admission_year <= 2024
    ),
    hfo as (
        select
            'hfo' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion
        from `medicu-biz.latest_one_icu.high_flow_oxygen_therapy`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where icu_admission_year <= 2024
    ),
    irrt as (
        select
            'irrt' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion
        from `medicu-biz.latest_one_icu.renal_replacement_therapy`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where type in ('hd', 'ecum', 'sled') and icu_admission_year <= 2024
    ),
    crrt as (
        select
            'crrt' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion
        from `medicu-biz.latest_one_icu.renal_replacement_therapy`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where type in ('chdf', 'crrt', 'chd', 'chf') and icu_admission_year <= 2024
    ),
    pe as (
        select
            'pe' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
                    where icu_admission_year <= 2024
                ),
                1
            ) as proportion
        from `medicu-biz.latest_one_icu.renal_replacement_therapy`
        inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
        where type in ('pe') and icu_admission_year <= 2024
    )
select *
from mv
union all
select *
from nppv
union all
select *
from hfo
union all
select *
from irrt
union all
select *
from crrt
union all
select *
from pe
