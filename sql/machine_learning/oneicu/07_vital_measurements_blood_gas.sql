with
    vital_measurements as (
        select *
        from `medicu-production.research_database_description_2024.05_vital_measurements_hourly`
    ),
    
    blood_gas as (
        select *
        from `medicu-production.research_database_description_2024.06_blood_gas_hourly`
    )

select
    v.icu_stay_id,
    v.time_window_index,
    v.hr_median,
    v.rr_median,
    v.spo2_median,
    v.invasive_mbp_00, v.invasive_mbp_01, v.invasive_mbp_02, v.invasive_mbp_03, v.invasive_mbp_04,
    v.invasive_mbp_05, v.invasive_mbp_06, v.invasive_mbp_07, v.invasive_mbp_08, v.invasive_mbp_09,
    v.invasive_mbp_10, v.invasive_mbp_11, v.invasive_mbp_12, v.invasive_mbp_13, v.invasive_mbp_14,
    v.invasive_mbp_15, v.invasive_mbp_16, v.invasive_mbp_17, v.invasive_mbp_18, v.invasive_mbp_19,
    v.invasive_mbp_20, v.invasive_mbp_21, v.invasive_mbp_22, v.invasive_mbp_23, v.invasive_mbp_24,
    v.invasive_mbp_25, v.invasive_mbp_26, v.invasive_mbp_27, v.invasive_mbp_28, v.invasive_mbp_29,
    v.invasive_mbp_30, v.invasive_mbp_31, v.invasive_mbp_32, v.invasive_mbp_33, v.invasive_mbp_34,
    v.invasive_mbp_35, v.invasive_mbp_36, v.invasive_mbp_37, v.invasive_mbp_38, v.invasive_mbp_39,
    v.invasive_mbp_40, v.invasive_mbp_41, v.invasive_mbp_42, v.invasive_mbp_43, v.invasive_mbp_44,
    v.invasive_mbp_45, v.invasive_mbp_46, v.invasive_mbp_47, v.invasive_mbp_48, v.invasive_mbp_49,
    v.invasive_mbp_50, v.invasive_mbp_51, v.invasive_mbp_52, v.invasive_mbp_53, v.invasive_mbp_54,
    v.invasive_mbp_55, v.invasive_mbp_56, v.invasive_mbp_57, v.invasive_mbp_58, v.invasive_mbp_59,
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
