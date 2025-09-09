with
    mv as (
        select
            'mechanical_ventilation' as field_name,
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
        from `physionet-data.eicu_crd.treatment`
        where
            lower(treatmentstring) like '%mechanical ventilation%'
            and lower(treatmentstring) not like '%non-invasive ventilation%'
    ),
    nppv as (
        select 'nppv' as field_name, null as count, null as proportion from unnest([1])
    ),
    hfo as (
        select 'hfo' as field_name, null as count, null as proportion from unnest([1])
    ),
    crrt as (
        select
            'crrt' as field_name,
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
        from `physionet-data.eicu_crd.treatment`
        where
            treatmentstring like '%C V V H%'
            or treatmentstring like '%C V V H D%'
            or treatmentstring like '%ultrafiltration%'
            or treatmentstring like '%C A V H D%'
    )
select *
from mv
union all
select *
from nppv
union all
select *
from hfo
union all
select *
from crrt
order by field_name
