with
    vital_measurements as (
        select *
        from `medicu-workspace-takapion.mimiciv_derived.vital_measurements_hourly`
    ),
    
    blood_gas as (
        select *
        from `medicu-workspace-takapion.mimiciv_derived.blood_gas_hourly`
    )

select
    v.icu_stay_id,
    v.time_window_index,
    v.invasive_mbp_median,
    v.hr_median,
    v.rr_median,
    v.spo2_median,
    bg.ph,
    bg.pao2,
    bg.paco2,
    bg.base_excess,
    bg.lactate,
    bg.sodium,
    bg.potassium
from vital_measurements v
left join blood_gas bg using (icu_stay_id, time_window_index)
order by v.icu_stay_id, v.time_window_index
