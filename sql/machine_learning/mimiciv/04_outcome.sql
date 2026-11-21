with
    patient_demographics as (
        select
            stay_id as icu_stay_id,
            subject_id,
            safe_cast(admission_age as float64) as age
        from `physionet-data.mimiciv_3_1_derived.icustay_detail`
    ),

    base_icustays_hourly as (
        select
            b.icu_stay_id,
            d.subject_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            b.in_time,
            b.out_time,
            case
                when d.age >= 0 and d.age < 1 then 55
                when d.age >= 1 and d.age < 2 then 60
                when d.age >= 2 and d.age < 5 then 62
                when d.age >= 5 then 65
                else null
            end as map_threshold
        from `medicu-workspace-takapion.mimiciv_derived.icustays_hourly` b
        left join patient_demographics d
            on b.icu_stay_id = d.icu_stay_id
    ),

    vasopressor_first_use as (
        select
            stay_id as icu_stay_id,
            min(starttime) as vasopressor_start_time
        from `medicu-workspace-takapion.mimiciv_derived.vasoactive_agent`
        where
            dopamine > 0 or epinephrine > 0 or norepinephrine > 0 or phenylephrine > 0 or vasopressin > 0
        group by stay_id
    ),

    invasive_mbp_measurements as (
        select
            b.icu_stay_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            v.mbp as invasive_mbp
        from base_icustays_hourly b
        left join `medicu-workspace-takapion.mimiciv_derived.vitalsign` v
            on b.icu_stay_id = v.stay_id
            and v.charttime >= b.start_time
            and v.charttime < b.end_time
            and v.mbp is not null
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

    observed_outcomes as (
        select
            b.icu_stay_id,
            b.subject_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            b.map_threshold,
            mbp.median_invasive_mbp,
            coalesce(mbp.invasive_mbp_count, 0) as invasive_mbp_count,
            case
                when b.map_threshold is null then null
                when mbp.invasive_mbp_count is null
                    or mbp.invasive_mbp_count = 0 then null
                when mbp.median_invasive_mbp < b.map_threshold then 1
                else 0
            end as low_map_observed,
            case
                when vsw.time_window_index is not null then 1
                when vua.time_window_index is not null then null
                else 0
            end as outcome_vasopressor_start,
            case
                when vua.time_window_index is not null then 1
                else 0
            end as is_after_vasopressor_start
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

    component_outcomes as (
        select
            * except (is_after_vasopressor_start),
            -- Keep the original censoring after the first vasopressor-start window.
            case
                when is_after_vasopressor_start = 1 then null
                else low_map_observed
            end as outcome_low_map
        from observed_outcomes
    ),

    outcome_labeled as (
        select
            *,
            -- Retain the existing composite column name for downstream use.
            case
                when outcome_vasopressor_start = 1 or outcome_low_map = 1 then 1
                when outcome_vasopressor_start = 0 and outcome_low_map = 0 then 0
                else null
            end as outcome
        from component_outcomes
    ),

    final_outcome as (
        select
            *,
            -- Each target is the single hourly window at index + 2.
            lead(outcome_vasopressor_start, 2) over (
                partition by icu_stay_id
                order by time_window_index
            ) as outcome_vasopressor_start_lead,
            lead(outcome_low_map, 2) over (
                partition by icu_stay_id
                order by time_window_index
            ) as outcome_low_map_lead,
            lead(outcome, 2) over (
                partition by icu_stay_id
                order by time_window_index
            ) as outcome_lead
        from outcome_labeled
    ),

    outcome_with_window_flag as (
        select
            *,
            -- Keep the first positive low-MAP target row: its flag is 0.
            -- All later rows in this ICU stay have flag 1, even after MAP recovers.
            -- Compute this before filtering on features or composite outcomes.
            coalesce(
                max(case when outcome_low_map_lead = 1 then 1 else 0 end) over (
                    partition by icu_stay_id
                    order by time_window_index
                    rows between unbounded preceding and 1 preceding
                ),
                0
            ) as window_after_low_map_lead
        from final_outcome
    )

select
    icu_stay_id,
    subject_id,
    time_window_index,
    start_time,
    end_time,
    outcome_vasopressor_start,
    outcome_low_map,
    outcome,
    outcome_vasopressor_start_lead,
    outcome_low_map_lead,
    outcome_lead,
    window_after_low_map_lead
from outcome_with_window_flag
order by icu_stay_id, time_window_index
