with
    bg as (
        select
            stay_id,
            ic.hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            count(ph) as ph_counts,
            count(lactate) as lactate_counts,
        from `mimiciv_derived.icustay_detail` ic
        left join
            `mimiciv_derived.bg` bg
            on ic.hadm_id = bg.hadm_id
            and ic.icu_intime <= bg.charttime
            and bg.charttime < ic.icu_outtime
        where los_icu >= 1
        group by stay_id, hadm_id, icu_intime, icu_outtime, los_icu
    ),
    cbc as (
        select
            stay_id,
            bg.hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            ph_counts,
            lactate_counts,
            count(wbc) as wbc_counts,
            count(cbc.hemoglobin) as hemoglobin_counts
        from bg
        left join
            `mimiciv_derived.complete_blood_count` cbc
            on bg.hadm_id = cbc.hadm_id
            and bg.icu_intime <= cbc.charttime
            and cbc.charttime < bg.icu_outtime
        group by
            stay_id,
            hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            ph_counts,
            lactate_counts
    ),
    ch as (
        select
            stay_id,
            cbc.hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            ph_counts,
            lactate_counts,
            wbc_counts,
            hemoglobin_counts,
            count(sodium) as sodium_counts,
            count(albumin) as albumin_counts
        from cbc
        left join
            `mimiciv_derived.chemistry` ch
            on cbc.hadm_id = ch.hadm_id
            and cbc.icu_intime <= ch.charttime
            and ch.charttime < cbc.icu_outtime
        group by
            stay_id,
            hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            ph_counts,
            lactate_counts,
            wbc_counts,
            hemoglobin_counts
    ),
    co as (
        select
            stay_id,
            ch.hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            ph_counts,
            lactate_counts,
            wbc_counts,
            hemoglobin_counts,
            sodium_counts,
            albumin_counts,
            count(inr) as inr_counts,
            count(d_dimer) as d_dimer_counts
        from ch
        left join
            `mimiciv_derived.coagulation` co
            on ch.hadm_id = co.hadm_id
            and ch.icu_intime <= co.charttime
            and co.charttime < ch.icu_outtime
        group by
            stay_id,
            hadm_id,
            icu_intime,
            icu_outtime,
            los_icu,
            ph_counts,
            lactate_counts,
            wbc_counts,
            hemoglobin_counts,
            sodium_counts,
            albumin_counts
    )
select
    stay_id as pid,
    round(ph_counts / los_icu, 1) as ph_per_day,
    round(lactate_counts / los_icu, 1) as lactate_per_day,
    round(wbc_counts / los_icu, 1) as wbc_per_day,
    round(hemoglobin_counts / los_icu, 1) as hemoglobin_per_day,
    round(sodium_counts / los_icu, 1) as sodium_per_day,
    round(albumin_counts / los_icu, 1) as albumin_per_day,
    round(inr_counts / los_icu, 1) as inr_per_day,
    round(d_dimer_counts / los_icu, 1) as d_dimer_per_day
from co
