with
    static_table as (
        select 
            patientunitstayid as icu_stay_id,
            case
                when gender = 1
                then 0
                when gender = 0
                then 1
                else null
            end as female,
            age
        from `physionet-data.eicu_crd_derived.icustay_detail`
    )
select
    icu_stay_id,
    female,
    age
from `medicu-workspace-takapion.eicu_crd_derived.inclusion_criteria`
inner join static_table using (icu_stay_id)
