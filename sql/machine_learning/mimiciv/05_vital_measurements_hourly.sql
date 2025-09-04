with
    vital_data as (
        select
            i.icu_stay_id,
            i.time_window_index,
            v.mbp as invasive_mbp,
            v.heart_rate as hr,
            v.resp_rate as rr,
            v.spo2
        from `medicu-workspace-takapion.mimiciv_derived.icustays_hourly` as i
        join `medicu-workspace-takapion.mimiciv_derived.vitalsign` as v
            on i.icu_stay_id = v.stay_id
            and v.charttime >= i.start_time
            and v.charttime < i.end_time
        where v.mbp is not null
        qualify count(*) over (partition by i.icu_stay_id, i.time_window_index) > 0
    ),
    
    aggregated as (
        select
            icu_stay_id,
            time_window_index,
            percentile_cont(invasive_mbp, 0.5) over (partition by icu_stay_id, time_window_index) as invasive_mbp_median,
            percentile_cont(hr, 0.5) over (partition by icu_stay_id, time_window_index) as hr_median,
            percentile_cont(rr, 0.5) over (partition by icu_stay_id, time_window_index) as rr_median,
            percentile_cont(spo2, 0.5) over (partition by icu_stay_id, time_window_index) as spo2_median
        from vital_data
        qualify row_number() over (partition by icu_stay_id, time_window_index) = 1
    )

select
    icu_stay_id,
    time_window_index,
    invasive_mbp_median,
    hr_median,
    rr_median,
    spo2_median
from aggregated
order by icu_stay_id, time_window_index
