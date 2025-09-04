with
    per_minute as (
        select
            i.icu_stay_id,
            i.time_window_index,
            cast(floor((v.observationoffset - i.start_time) / 5) * 5 as int64) as minute_idx,
            v.systemicmean as invasive_mbp,
            v.heartrate as hr,
            v.respiration as rr,
            v.sao2 as spo2
        from `medicu-workspace-takapion.eicu_crd_derived.icustays_hourly` as i
        join `physionet-data.eicu_crd.vitalperiodic` as v
            on i.icu_stay_id = v.patientunitstayid
            and v.observationoffset >= i.start_time
            and v.observationoffset < i.end_time
        where v.systemicmean is not null
        qualify count(*) over (partition by i.icu_stay_id, i.time_window_index) = 12
    ),
    
    med as (
        select
            icu_stay_id,
            time_window_index,
            percentile_cont(hr, 0.5) over (partition by icu_stay_id, time_window_index) as hr_median,
            percentile_cont(rr, 0.5) over (partition by icu_stay_id, time_window_index) as rr_median,
            percentile_cont(spo2, 0.5) over (partition by icu_stay_id, time_window_index) as spo2_median
        from per_minute
        qualify row_number() over (partition by icu_stay_id, time_window_index order by minute_idx) = 1
    ),
    
    pivot_src as (
        select
            icu_stay_id,
            time_window_index,
            format('%02d', minute_idx) as minute_str,
            invasive_mbp
        from per_minute
    ),
    
    pivoted as (
        select * from pivot_src
        pivot (max(invasive_mbp) for minute_str in (
            '00','05','10','15','20','25','30','35','40','45','50','55'
        ))
    )

select
    p.icu_stay_id,
    p.time_window_index,
    m.hr_median,
    m.rr_median,
    m.spo2_median,
    `00` as invasive_mbp_00,
    `05` as invasive_mbp_05,
    `10` as invasive_mbp_10,
    `15` as invasive_mbp_15,
    `20` as invasive_mbp_20,
    `25` as invasive_mbp_25,
    `30` as invasive_mbp_30,
    `35` as invasive_mbp_35,
    `40` as invasive_mbp_40,
    `45` as invasive_mbp_45,
    `50` as invasive_mbp_50,
    `55` as invasive_mbp_55
from pivoted as p
join med as m using (icu_stay_id, time_window_index)
where `00` is not null and `05` is not null and `10` is not null 
      and `15` is not null and `20` is not null and `25` is not null
      and `30` is not null and `35` is not null and `40` is not null
      and `45` is not null and `50` is not null and `55` is not null
order by p.icu_stay_id, p.time_window_index
