
with
    inclusion_criteria as (
        select icu_stay_id
        from `medicu-biz.snapshots_one_icu.icu_stays_20250716`
        inner join `medicu-biz.snapshots_one_icu.patients_20250716` using (subject_id)
        where female is not null and date_of_birth is not null
    ),
    vitalsign_include as (
        select icu_stay_id
        from `medicu-biz.snapshots_one_icu_derived.aggregated_vital_measurements_20250716`
        where
            rr_count > 0
            and hr_count > 0
            and (invasive_mbp_count > 0 or non_invasive_mbp_count > 0)
            and spo2_count > 0
    )

select distinct icu_stay_id
from inclusion_criteria
inner join vitalsign_include using (icu_stay_id)
