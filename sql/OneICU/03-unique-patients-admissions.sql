select
    count(distinct subject_id) as unique_patients,
    count(distinct icu_stay_id) as unique_admissions,
from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
