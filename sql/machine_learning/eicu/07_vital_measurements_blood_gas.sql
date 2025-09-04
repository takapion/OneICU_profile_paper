with
    vital_measurements as (
        select *
        from `medicu-workspace-takapion.eicu_crd_derived.vital_measurements_hourly`
    ),
    
    blood_gas as (
        select *
        from `medicu-workspace-takapion.eicu_crd_derived.blood_gas_hourly`
    )

select
    v.icu_stay_id,
    v.time_window_index,
    v.hr_median,
    v.rr_median,
    v.spo2_median,
    v.invasive_mbp_00, v.invasive_mbp_05, v.invasive_mbp_10, v.invasive_mbp_15, v.invasive_mbp_20,
    v.invasive_mbp_25, v.invasive_mbp_30, v.invasive_mbp_35, v.invasive_mbp_40, v.invasive_mbp_45,
    v.invasive_mbp_50, v.invasive_mbp_55,
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
