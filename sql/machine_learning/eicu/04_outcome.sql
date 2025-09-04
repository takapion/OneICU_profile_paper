with
    base_icustays_hourly as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            in_time,
            out_time
        from `medicu-workspace-takapion.eicu_crd_derived.icustays_hourly`
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
