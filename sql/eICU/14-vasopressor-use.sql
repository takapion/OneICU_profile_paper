with
    vasopressor_from_treatment as (
        select patientunitstayid
        from `physionet-data.eicu_crd_derived.pivoted_treatment_vasopressor`
    ),

    vasopressor_from_infusion as (
        select patientunitstayid
        from `physionet-data.eicu_crd_derived.pivoted_infusion`
        where
            dopamine = 1
            or norepinephrine = 1
            or phenylephrine = 1
            or epinephrine = 1
            or vasopressin = 1
    ),
    vasopressor_unioned as (
        select patientunitstayid
        from vasopressor_from_treatment
        union distinct
        select patientunitstayid
        from vasopressor_from_infusion
    )
select
    'vasopressor' as field_name,
    count(distinct patientunitstayid) as count,
    round(
        100
        * count(distinct patientunitstayid)
        / (
            select count(distinct patientunitstayid)
            from `physionet-data.eicu_crd_derived.icustay_detail`
        ),
        1
    ) as proportion
from vasopressor_unioned
