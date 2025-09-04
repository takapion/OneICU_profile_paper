with
    base_icustays_hourly as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            in_time,
            out_time
        from `medicu-production.research_database_description_2024.03_icustays_hourly`
    ),

    vasopressor_first_use as (
        select
            icu_stay_id,
            min(start_time) as vasopressor_start_time
        from `medicu-biz.snapshots_one_icu_derived.infusion_injection_active_ingredient_rate_smoothed_20250716`
        where
            active_ingredient_name in ('dopamine', 'noradrenaline', 'adrenaline', 'phenylephrine', 'vasopressin')
        group by icu_stay_id
    ),

    invasive_mbp_measurements as (
        select
            b.icu_stay_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            v.invasive_mbp
        from base_icustays_hourly b
        left join `medicu-biz.snapshots_one_icu.vital_measurements_20250716` v
            on b.icu_stay_id = v.icu_stay_id
            and v.time >= b.start_time
            and v.time < b.end_time
            and v.invasive_mbp is not null
    ),

    invasive_mbp_by_window as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            percentile_cont(invasive_mbp, 0.5) over (
                partition by icu_stay_id, time_window_index
            ) as median_invasive_mbp,
            count(invasive_mbp) over (
                partition by icu_stay_id, time_window_index
            ) as invasive_mbp_count
        from invasive_mbp_measurements
        where invasive_mbp is not null
        qualify row_number() over (
            partition by icu_stay_id, time_window_index
            order by invasive_mbp
        ) = 1
    ),

    vasopressor_start_window as (
        select
            b.icu_stay_id,
            b.time_window_index,
            v.vasopressor_start_time
        from base_icustays_hourly b
        inner join vasopressor_first_use v
            on b.icu_stay_id = v.icu_stay_id
            and v.vasopressor_start_time >= b.start_time
            and v.vasopressor_start_time < b.end_time
    ),

    vasopressor_usage_after as (
        select distinct
            b.icu_stay_id,
            b.time_window_index
        from base_icustays_hourly b
        inner join vasopressor_start_window vsw
            on b.icu_stay_id = vsw.icu_stay_id
            and b.time_window_index > vsw.time_window_index
    ),

    outcome_labeled as (
        select
            b.icu_stay_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            case
                when vsw.time_window_index is not null then 1
                when vua.time_window_index is not null then null
                when mbp.median_invasive_mbp < 65 and mbp.invasive_mbp_count > 0 then 1
                when mbp.invasive_mbp_count = 0 or mbp.invasive_mbp_count is null then null
                else 0
            end as outcome
        from base_icustays_hourly b
        left join invasive_mbp_by_window mbp
            on b.icu_stay_id = mbp.icu_stay_id
            and b.time_window_index = mbp.time_window_index
        left join vasopressor_start_window vsw
            on b.icu_stay_id = vsw.icu_stay_id
            and b.time_window_index = vsw.time_window_index
        left join vasopressor_usage_after vua
            on b.icu_stay_id = vua.icu_stay_id
            and b.time_window_index = vua.time_window_index
    ),

    final_outcome as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            outcome,
            lead(outcome) over (
                partition by icu_stay_id
                order by time_window_index
            ) as outcome_lead
        from outcome_labeled
    )

select
    icu_stay_id,
    time_window_index,
    start_time,
    end_time,
    outcome,
    outcome_lead
from final_outcome
order by icu_stay_id, time_window_index
