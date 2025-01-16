with
    bg as (
        select
            ic.patientunitstayid,
            unitdischargeoffset / 1440 as los_icu,
            count(ph) as ph_counts
        from `physionet-data.eicu_crd_derived.icustay_detail` ic
        left join
            `physionet-data.eicu_crd_derived.pivoted_bg` bg
            on ic.patientunitstayid = bg.patientunitstayid
            and 0 <= bg.chartoffset
            and bg.chartoffset < ic.unitdischargeoffset
        where unitdischargeoffset >= 1440
        group by patientunitstayid, unitdischargeoffset
    ),
    lab as (
        select
            ic.patientunitstayid,
            unitdischargeoffset / 1440 as los_icu,
            count(lactate) as lactate_counts,
            count(wbc) as wbc_counts,
            count(hemoglobin) as hemoglobin_counts,
            count(sodium) as sodium_counts,
            count(albumin) as albumin_counts,
            count(inr) as inr_counts,
            0 as d_dimer_counts
        from `physionet-data.eicu_crd_derived.icustay_detail` ic
        left join
            `physionet-data.eicu_crd_derived.pivoted_lab` lab
            on ic.patientunitstayid = lab.patientunitstayid
            and 0 <= lab.chartoffset
            and lab.chartoffset < ic.unitdischargeoffset
        where unitdischargeoffset >= 1440
        group by patientunitstayid, unitdischargeoffset
    )
select
    patientunitstayid as pid,
    round(ph_counts / bg.los_icu, 1) as ph_per_day,
    round(lactate_counts / bg.los_icu, 1) as lactate_per_day,
    round(wbc_counts / bg.los_icu, 1) as wbc_per_day,
    round(hemoglobin_counts / bg.los_icu, 1) as hemoglobin_per_day,
    round(sodium_counts / bg.los_icu, 1) as sodium_per_day,
    round(albumin_counts / bg.los_icu, 1) as albumin_per_day,
    round(inr_counts / bg.los_icu, 1) as inr_per_day,
    round(d_dimer_counts / bg.los_icu, 1) as d_dimer_per_day
from bg
inner join lab using (patientunitstayid)
