with
    inclusion_criteria as (
        select stay_id as icu_stay_id
        from `physionet-data.mimiciv_3_1_derived.icustay_detail`
        where 
            gender is not null 
            and admission_age is not null
    ),
    vitalsign_counts as (
        select 
            stay_id,
            count(case when resp_rate is not null then 1 end) as rr_count,
            count(case when heart_rate is not null then 1 end) as hr_count,
            count(case when mbp is not null then 1 end) as invasive_mbp_count,
            count(case when spo2 is not null then 1 end) as spo2_count
        from `medicu-workspace-takapion.mimiciv_derived.vitalsign`
        group by stay_id
    ),
    vitalsign_include as (
        select stay_id as icu_stay_id
        from vitalsign_counts
        where
            rr_count > 0
            and hr_count > 0
            and invasive_mbp_count > 0
            and spo2_count > 0
    )

select distinct icu_stay_id
from inclusion_criteria
inner join vitalsign_include using (icu_stay_id)
