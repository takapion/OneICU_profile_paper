select
    o.icu_stay_id,
    o.subject_id,
    o.time_window_index,
    v.invasive_mbp_median,
    v.hr_median,
    v.rr_median,
    v.spo2_median,
    v.ph,
    v.pao2,
    v.paco2,
    v.base_excess,
    v.lactate,
    v.sodium,
    v.potassium,
    o.outcome_vasopressor_start_lead,
    o.outcome_low_map_lead,
    o.outcome_lead,
    o.window_after_low_map_lead
from `medicu-workspace-takapion.mimiciv_derived.outcome` o
inner join `medicu-workspace-takapion.mimiciv_derived.vital_measurements_blood_gas` v
    on o.icu_stay_id = v.icu_stay_id
    and o.time_window_index = v.time_window_index
where o.outcome_lead is not null
order by o.icu_stay_id, o.time_window_index
