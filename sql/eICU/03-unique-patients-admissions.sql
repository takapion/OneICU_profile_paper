select
    count(distinct uniquepid) as unique_patients,
    count(distinct patientunitstayid) as unique_admissions
from `physionet-data.eicu_crd_derived.icustay_detail`
