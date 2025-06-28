select
    icu_admission_year,
    count(distinct icu_stay_id) as unique_admissions,
    count(distinct subject_id) as unique_patients
from `snapshots_one_icu_derived.extended_icu_stays_20250628`
where icu_admission_year <= 2024
group by icu_admission_year
order by icu_admission_year
