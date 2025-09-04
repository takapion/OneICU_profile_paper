select
    o.icu_stay_id,
    o.time_window_index,
    v.hr_median,
    v.rr_median,
    v.spo2_median,
    v.invasive_mbp_00, v.invasive_mbp_05, v.invasive_mbp_10, v.invasive_mbp_15, v.invasive_mbp_20,
    v.invasive_mbp_25, v.invasive_mbp_30, v.invasive_mbp_35, v.invasive_mbp_40, v.invasive_mbp_45,
    v.invasive_mbp_50, v.invasive_mbp_55,
    v.ph,
    v.pao2,
    v.paco2,
    v.base_excess,
    v.lactate,
    v.sodium,
    v.potassium,
    o.outcome_lead
from `medicu-workspace-takapion.eicu_crd_derived.outcome` o
inner join `medicu-workspace-takapion.eicu_crd_derived.vital_measurements_blood_gas` v
    on o.icu_stay_id = v.icu_stay_id
    and o.time_window_index = v.time_window_index
where o.outcome_lead is not null
order by o.icu_stay_id, o.time_window_index
