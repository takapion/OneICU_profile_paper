with
    inclusion_criteria as (
        select patientunitstayid as icu_stay_id
        from `physionet-data.eicu_crd_derived.icustay_detail`
        where 
            gender is not null 
            and safe_cast(age as int64) is not null
    ),
    vitalperiodic_counts as (
        select 
            patientunitstayid,
            count(case when respiration is not null then 1 end) as rr_count,
            count(case when heartrate is not null then 1 end) as hr_count,
            count(case when systemicmean is not null then 1 end) as invasive_mbp_count,
            count(case when sao2 is not null then 1 end) as spo2_count
        from `physionet-data.eicu_crd.vitalperiodic`
        group by patientunitstayid
    ),
    vitalaperiodic_counts as (
        select 
            patientunitstayid,
            count(case when noninvasivemean is not null then 1 end) as non_invasive_mbp_count
        from `physionet-data.eicu_crd.vitalaperiodic`
        group by patientunitstayid
    ),
    vitalsign_counts as (
        select 
            coalesce(vp.patientunitstayid, va.patientunitstayid) as patientunitstayid,
            coalesce(vp.rr_count, 0) as rr_count,
            coalesce(vp.hr_count, 0) as hr_count,
            coalesce(vp.invasive_mbp_count, 0) as invasive_mbp_count,
            coalesce(va.non_invasive_mbp_count, 0) as non_invasive_mbp_count,
            coalesce(vp.spo2_count, 0) as spo2_count
        from vitalperiodic_counts vp
        left join vitalaperiodic_counts va using (patientunitstayid)
    ),
    vitalsign_include as (
        select patientunitstayid as icu_stay_id
        from vitalsign_counts
        where
            rr_count > 0
            and hr_count > 0
            and (invasive_mbp_count > 0 or non_invasive_mbp_count > 0)
            and spo2_count > 0
    )

select distinct icu_stay_id
from inclusion_criteria
inner join vitalsign_include using (icu_stay_id)
