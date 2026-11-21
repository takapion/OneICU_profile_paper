with
    patient_demographics as (
        select
            patientunitstayid as icu_stay_id,
            uniquepid as subject_id,
            safe_cast(age as float64) as age,
            regexp_replace(cast(age as string), r'\s+', '') = '>89'
                as is_age_over_89
        from `physionet-data.eicu_crd.patient`
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
                when d.is_age_over_89 then 65
                when d.age >= 0 and d.age < 1 then 55
                when d.age >= 1 and d.age < 2 then 60
                when d.age >= 2 and d.age < 5 then 62
                when d.age >= 5 then 65
                else null
            end as map_threshold
        from `medicu-workspace-takapion.eicu_crd_derived.icustays_hourly` b
        left join patient_demographics d
            on b.icu_stay_id = d.icu_stay_id
    ),

    vasopressor_from_treatment as (
        select
            patientunitstayid as icu_stay_id,
            min(chartoffset) as vasopressor_start_time
        from `physionet-data.eicu_crd_derived.pivoted_treatment_vasopressor`
        group by patientunitstayid
    ),

    vasopressor_from_infusion as (
        select
            patientunitstayid as icu_stay_id,
            min(chartoffset) as vasopressor_start_time
        from `physionet-data.eicu_crd_derived.pivoted_infusion`
        where
            dopamine = 1 or norepinephrine = 1 or phenylephrine = 1 or epinephrine = 1 or vasopressin = 1
        group by patientunitstayid
    ),

    vasopressor_first_use as (
        select
            icu_stay_id,
            min(vasopressor_start_time) as vasopressor_start_time
        from (
            select icu_stay_id, vasopressor_start_time from vasopressor_from_treatment
            union all
            select icu_stay_id, vasopressor_start_time from vasopressor_from_infusion
        )
        group by icu_stay_id
    ),

    invasive_mbp_measurements as (
        select
            b.icu_stay_id,
            b.time_window_index,
            b.start_time,
            b.end_time,
            v.systemicmean as invasive_mbp
        from base_icustays_hourly b
        left join `physionet-data.eicu_crd.vitalperiodic` v
            on b.icu_stay_id = v.patientunitstayid
            and v.observationoffset >= b.start_time
            and v.observationoffset < b.end_time
            and v.systemicmean is not null
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

    first_low_map as (
        select
            *,
            -- First observed low-MAP hourly median, including censored windows.
            -- Compute this before LEAD and before filtering on feature availability.
            min(case when low_map_observed = 1 then time_window_index end) over (
                partition by icu_stay_id
            ) as first_low_map_time_window_index,
            min(case when low_map_observed = 1 then start_time end) over (
                partition by icu_stay_id
            ) as first_low_map_start_time
        from outcome_labeled
    ),

    first_low_map_labeled as (
        select
            *,
            case
                when time_window_index = first_low_map_time_window_index then 1
                else 0
            end as is_first_low_map
        from first_low_map
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
            ) as outcome_lead,
            lead(is_first_low_map, 2) over (
                partition by icu_stay_id
                order by time_window_index
            ) as is_first_low_map_lead
        from first_low_map_labeled
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
    is_first_low_map,
    is_first_low_map_lead
from final_outcome
order by icu_stay_id, time_window_index
