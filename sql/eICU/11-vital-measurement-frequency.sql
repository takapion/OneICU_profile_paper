with
    unique_vital_periodic as (
        select
            patientunitstayid,
            observationoffset,
            max(temperature) as bt,
            max(heartrate) as hr,
            max(respiration) as rr,
            min(systemicsystolic) as invasive_sbp,
            min(systemicmean) as invasive_mbp,
            min(systemicdiastolic) as invasive_dbp,
            min(sao2) as spo2
        from `physionet-data.eicu_crd.vitalperiodic`
        group by patientunitstayid, observationoffset
    ),
    unique_vital_aperiodic as (
        select
            patientunitstayid,
            observationoffset,
            min(noninvasivesystolic) as non_invasive_sbp,
            min(noninvasivemean) as non_invasive_mbp,
            min(noninvasivediastolic) as non_invasive_dbp
        from `physionet-data.eicu_crd.vitalaperiodic`
        group by patientunitstayid, observationoffset
    ),
    unique_vital as (
        select *
        from unique_vital_periodic
        full outer join
            unique_vital_aperiodic using (patientunitstayid, observationoffset)
    ),
    stayed_more_than_1_day as (
        select
            patientunitstayid,
            round(icu_los_hours, 1) as icu_stay_hour,
            observationoffset as time,
            bt,
            hr,
            rr,
            invasive_sbp,
            invasive_mbp,
            invasive_dbp,
            non_invasive_sbp,
            non_invasive_mbp,
            non_invasive_dbp,
            spo2
        from unique_vital
        inner join
            `physionet-data.eicu_crd_derived.icustay_detail` using (patientunitstayid)
        where
            icu_los_hours >= 24
            and observationoffset >= 0
            and observationoffset <= cast(floor(icu_los_hours * 60) as int64)
    ),
    vital_count as (
        select
            patientunitstayid,
            icu_stay_hour,
            count(bt) as bt_count,
            count(hr) as hr_count,
            count(rr) as rr_count,
            countif(
                invasive_sbp is not null
                and invasive_mbp is not null
                and invasive_dbp is not null
            ) as invasive_bp_count,
            countif(
                non_invasive_sbp is not null
                and non_invasive_mbp is not null
                and non_invasive_dbp is not null
            ) as non_invasive_bp_count,
            count(spo2) as spo2_count,
        from stayed_more_than_1_day
        group by patientunitstayid, icu_stay_hour
    )
select
    patientunitstayid as pid,
    round(bt_count / icu_stay_hour, 1) as bt_per_hour,
    round(hr_count / icu_stay_hour, 1) as hr_per_hour,
    round(rr_count / icu_stay_hour, 1) as rr_per_hour,
    round(invasive_bp_count / icu_stay_hour, 1) as invasive_bp_per_hour,
    round(non_invasive_bp_count / icu_stay_hour, 1) as non_invasive_bp_per_hour,
    round(spo2_count / icu_stay_hour, 1) as spo2_per_hour
from vital_count
