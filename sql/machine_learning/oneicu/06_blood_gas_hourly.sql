with
    base_icustays_hourly as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time
        from `medicu-production.research_database_description_2024.03_icustays_hourly`
    ),
    
    blood_gas_pivot as (
        select
            i.icu_stay_id,
            i.time_window_index,
            i.start_time,
            i.end_time,
            bg.time,
            bg.ph,
            bg.po2 as pao2,
            bg.pco2 as paco2,
            bg.base_excess,
            bg.lactate,
            bg.sodium,
            bg.potassium
        from base_icustays_hourly i
        left join (
            select
                icu_stay_id,
                time,
                ph,
                po2,
                pco2,
                base_excess,
                lactate,
                sodium,
                potassium
            from (
                select
                    icu_stay_id,
                    time,
                    field_name,
                    value
                from `medicu-biz.snapshots_one_icu.blood_gas_20250716`
                where sample_type = 'arterial_blood_gas'
                  and field_name in ('ph', 'po2', 'pco2', 'base_excess', 'lactate', 'sodium', 'potassium')
            )
            pivot (
                max(value) for field_name in (
                    'ph',
                    'po2', 
                    'pco2',
                    'base_excess',
                    'lactate',
                    'sodium',
                    'potassium'
                )
            )
        ) bg
            on i.icu_stay_id = bg.icu_stay_id
            and bg.time >= i.start_time
            and bg.time < i.end_time
    ),
    
    aggregated_blood_gas as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            min(ph) as ph,
            min(pao2) as pao2,
            max(paco2) as paco2,
            min(base_excess) as base_excess,
            max(lactate) as lactate,
            min(sodium) as sodium,
            max(potassium) as potassium
        from blood_gas_pivot
        where ph is not null or pao2 is not null or paco2 is not null 
              or base_excess is not null or lactate is not null 
              or sodium is not null or potassium is not null
        group by icu_stay_id, time_window_index, start_time, end_time
    ),
    
    with_forward_fill as (
        select
            b.icu_stay_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            coalesce(
                a.ph,
                last_value(a.ph ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as ph,
            coalesce(
                a.pao2,
                last_value(a.pao2 ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as pao2,
            coalesce(
                a.paco2,
                last_value(a.paco2 ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as paco2,
            coalesce(
                a.base_excess,
                last_value(a.base_excess ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as base_excess,
            coalesce(
                a.lactate,
                last_value(a.lactate ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as lactate,
            coalesce(
                a.sodium,
                last_value(a.sodium ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as sodium,
            coalesce(
                a.potassium,
                last_value(a.potassium ignore nulls) over (
                    partition by b.icu_stay_id 
                    order by b.time_window_index 
                    rows unbounded preceding
                )
            ) as potassium
        from base_icustays_hourly b
        left join aggregated_blood_gas a using (icu_stay_id, time_window_index)
    )

select *
from with_forward_fill
order by icu_stay_id, time_window_index
