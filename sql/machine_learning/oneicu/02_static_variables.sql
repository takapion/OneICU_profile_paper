with
    static_table as (
        select
            e.icu_stay_id,
            s.subject_id,
            e.female,
            e.age
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` e
        left join `medicu-biz.snapshots_one_icu.icu_stays_20250716` s
            on e.icu_stay_id = s.icu_stay_id
    )
select
    icu_stay_id,
    subject_id,
    female,
    age
from `medicu-production.research_database_description_2024.01_inclusion_criteria`
inner join static_table using (icu_stay_id)
