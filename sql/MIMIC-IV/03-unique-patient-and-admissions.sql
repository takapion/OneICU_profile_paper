select
    count(distinct subject_id) as unique_patients,
    count(distinct stay_id) as unique_admissions
from `mimiciv_derived.icustay_detail`
