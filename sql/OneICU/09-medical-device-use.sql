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
                    from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20251228`
                ),
                1
            ) as proportion
        from `medicu-biz.snapshots_one_icu.mechanical_ventilations_20251228`
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
                    from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20251228`
                ),
                1
            ) as proportion
        from `medicu-biz.snapshots_one_icu.non_invasive_positive_pressure_ventilations_20251228`
        inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using(icu_stay_id)
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
                    from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20251228`
                ),
                1
            ) as proportion
        from `medicu-biz.snapshots_one_icu.high_flow_oxygen_therapy_20251228`
        inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20251228` using(icu_stay_id)
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
                    from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20251228`
                ),
                1
            ) as proportion
        from `medicu-biz.snapshots_one_icu.renal_replacement_therapy_20251228`
        inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20251228` using(icu_stay_id)
        where type in ('chdf', 'crrt', 'chd', 'chf')
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
from crrt
order by field_name
