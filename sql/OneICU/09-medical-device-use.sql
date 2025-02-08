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
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.mechanical_ventilations_20250206`
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
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.non_invasive_positive_pressure_ventilations_20250206`
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
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.high_flow_oxygen_therapy_20250206`
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
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.renal_replacement_therapy_20250206`
        where type in ('hd', 'ecum', 'sled')
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
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.renal_replacement_therapy_20250206`
        where type in ('chdf', 'crrt', 'chd', 'chf')
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
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.renal_replacement_therapy_20250206`
        where type in ('pe')
    ),
    pmx as (
        select
            'pmx' as field_name,
            count(distinct icu_stay_id) as count,
            round(
                100
                * count(distinct icu_stay_id)
                / (
                    select count(*)
                    from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
                ),
                1
            ) as proportion
        from `medicu-beta.snapshots_one_icu.renal_replacement_therapy_20250206`
        where type = 'pmx'
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
union all
select *
from pmx
