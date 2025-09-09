select
    'vasopressor' as field_name,
    count(distinct icu_stay_id) as count,
    round(
        100
        * count(distinct icu_stay_id)
        / (
            select count(distinct icu_stay_id)
            from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
            where icu_admission_year <= 2024
        ),
        1
    ) as proportion
from
    `medicu-biz.snapshots_one_icu_derived.infusion_injection_active_ingredient_rate_smoothed_20250716`
inner join
    `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using (
        icu_stay_id
    )
where
    icu_admission_year <= 2024
    and active_ingredient_name
    in ('dopamine', 'noradrenaline', 'adrenaline', 'phenylephrine', 'vasopressin')
