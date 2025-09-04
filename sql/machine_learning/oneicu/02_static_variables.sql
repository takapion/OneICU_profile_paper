with
    static_table as (
        select icu_stay_id, female, age
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
    )
select
    icu_stay_id,
    female,
    age
from `medicu-production.research_database_description_2024.01_inclusion_criteria`
inner join static_table using (icu_stay_id)
