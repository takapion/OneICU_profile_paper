with
    static_table as (
        select 
            stay_id as icu_stay_id,
            case
                when gender = 'F'
                then 1
                when gender = 'M'
                then 0
                else null
            end as female,
            admission_age as age
        from `physionet-data.mimiciv_3_1_derived.icustay_detail`
    )
select
    icu_stay_id,
    female,
    age
from `medicu-workspace-takapion.mimiciv_derived.inclusion_criteria`
inner join static_table using (icu_stay_id)
