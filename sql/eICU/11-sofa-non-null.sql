with
    expanded_times as (
        select
            patientunitstayid,
            seqnum as sequence,
            seqnum * 60 as start_time,
            (seqnum + 1) * 60 as end_time
        from
            (
                select distinct patientunitstayid
                from `physionet-data.eicu_crd_derived.icustay_detail`
                where icu_los_hours >= 24
            )
        cross join unnest(generate_array(0, 23)) as seqnum
    ),

    -- respiration score
    fio2_respchart_as_float as (
        select
            patientunitstayid,
            respchartoffset as time,
            case
                when
                    (
                        0.21 <= safe_cast(respchartvalue as numeric)
                        and safe_cast(respchartvalue as numeric) <= 1
                    )
                then safe_cast(respchartvalue as numeric) * 100
                when
                    (
                        21 <= safe_cast(respchartvalue as numeric)
                        and safe_cast(respchartvalue as numeric) <= 100
                    )
                then safe_cast(respchartvalue as numeric)
                else null
            end as fio2
        from `physionet-data.eicu_crd.respiratorycharting`
        where 0 <= respchartoffset and respchartoffset < 1440
    ),
    fio2_nursechart_as_float as (
        select
            patientunitstayid,
            nursingchartentryoffset as time,
            case
                when
                    (
                        0.21 <= safe_cast(nursingchartvalue as numeric)
                        and safe_cast(nursingchartvalue as numeric) <= 1
                    )
                then safe_cast(nursingchartvalue as numeric) * 100
                when
                    (
                        21 <= safe_cast(nursingchartvalue as numeric)
                        and safe_cast(nursingchartvalue as numeric) <= 100
                    )
                then safe_cast(nursingchartvalue as numeric)
                else null
            end as fio2
        from `physionet-data.eicu_crd.nursecharting`
        where
            lower(nursingchartcelltypevallabel) like '%fio2%'
            and 0 <= nursingchartentryoffset
            and nursingchartentryoffset < 1440
    ),
    fio2_as_int as (
        select *
        from fio2_respchart_as_float
        where fio2 is not null and floor(fio2) = fio2
        union all
        select *
        from fio2_nursechart_as_float
        where fio2 is not null and floor(fio2) = fio2
    ),
    pao2_tab as (
        select patientunitstayid, labresultoffset as time, min(labresult) as pao2
        from `physionet-data.eicu_crd.lab`
        where
            lower(labname) = 'pao2' and 0 <= labresultoffset and labresultoffset < 1440
        group by patientunitstayid, labresultoffset
    ),
    respiration_components as (
        select
            et.patientunitstayid,
            start_time,
            end_time,
            case when fio2 is not null then fio2 else 21 end as fio2,
            pao2
        from expanded_times et
        left join
            fio2_as_int fo
            on et.patientunitstayid = fo.patientunitstayid
            and et.start_time <= fo.time
            and fo.time < et.end_time
        left join
            pao2_tab po
            on et.patientunitstayid = po.patientunitstayid
            and et.start_time <= po.time
            and po.time < et.end_time
    ),
    respiration_grouped as (
        select
            patientunitstayid,
            start_time,
            end_time,
            max(fio2) as fio2,
            min(pao2) as pao2
        from respiration_components
        group by patientunitstayid, start_time, end_time
    ),
    respiration as (
        select
            patientunitstayid,
            start_time,
            end_time,
            case
                when pao2 is not null and 100 * pao2 / fio2 <= 500 then 1 else 0
            end as respiration_notnull
        from respiration_grouped
    ),

    -- cardiovascular score
    map_tab as (
        select patientunitstayid, observationoffset as time, noninvasivemean as map
        from `physionet-data.eicu_crd.vitalaperiodic`
        where 0 <= observationoffset and observationoffset < 1440
        union all
        select patientunitstayid, observationoffset as time, systemicmean as map
        from `physionet-data.eicu_crd.vitalperiodic`
        where 0 <= observationoffset and observationoffset < 1440
    ),
    map_grouped as (
        select et.patientunitstayid, start_time, end_time, min(map) as map
        from expanded_times et
        left join
            map_tab mp
            on et.patientunitstayid = mp.patientunitstayid
            and et.start_time <= mp.time
            and mp.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),
    vasoactive_drug_tab as (
        select patientunitstayid, infusionoffset as time, 'dopamine' as vasoactive_drug
        from `physionet-data.eicu_crd.infusiondrug`
        where
            lower(drugname) like '%dopamine%'
            and 0 <= infusionoffset
            and infusionoffset < 1440
        union all
        select
            patientunitstayid,
            infusionoffset as time,
            'norepinephrine' as vasoactive_drug
        from `physionet-data.eicu_crd.infusiondrug`
        where
            lower(drugname) like '%norepinephrine%'
            and 0 <= infusionoffset
            and infusionoffset < 1440
        union all
        select
            patientunitstayid, infusionoffset as time, 'dobutamine' as vasoactive_drug
        from `physionet-data.eicu_crd.infusiondrug`
        where
            lower(drugname) like '%dobutamine%'
            and 0 <= infusionoffset
            and infusionoffset < 1440
    ),
    vasoactive_drug_grouped as (
        select
            et.patientunitstayid,
            start_time,
            end_time,
            max(vasoactive_drug) as vasoactive_drug
        from expanded_times et
        left join
            vasoactive_drug_tab va
            on et.patientunitstayid = va.patientunitstayid
            and et.start_time <= va.time
            and va.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),
    cardiovascular as (
        select
            mp.patientunitstayid,
            mp.start_time,
            mp.end_time,
            case
                when map is not null or vasoactive_drug is not null then 1 else 0
            end as cardiovascular_notnull
        from map_grouped mp
        inner join
            vasoactive_drug_grouped va
            on mp.patientunitstayid = va.patientunitstayid
            and mp.start_time = va.start_time
    ),

    -- coagulation score
    plt_tab as (
        select patientunitstayid, labresultoffset as time, min(labresult) as platelets
        from `physionet-data.eicu_crd.lab`
        where
            lower(labname) like '%platelets%'
            and 0 <= labresultoffset
            and labresultoffset < 1440
        group by patientunitstayid, labresultoffset
    ),
    coagulation as (
        select
            et.patientunitstayid,
            start_time,
            end_time,
            case
                when min(platelets) is not null then 1 else 0
            end as coagulation_notnull
        from expanded_times et
        left join
            plt_tab pt
            on et.patientunitstayid = pt.patientunitstayid
            and et.start_time <= pt.time
            and pt.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),

    -- liver score
    bil_tab as (
        select patientunitstayid, labresultoffset as time, max(labresult) as bilirubin
        from `physionet-data.eicu_crd.lab`
        where
            lower(labname) = 'total bilirubin'
            and 0 <= labresultoffset
            and labresultoffset < 1440
        group by patientunitstayid, labresultoffset
    ),
    liver as (
        select
            et.patientunitstayid,
            start_time,
            end_time,
            case when max(bilirubin) is not null then 1 else 0 end as liver_notnull
        from expanded_times et
        left join
            bil_tab bl
            on et.patientunitstayid = bl.patientunitstayid
            and et.start_time <= bl.time
            and bl.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),

    -- renal score
    cr_tab as (
        select patientunitstayid, labresultoffset as time, max(labresult) as creatinine
        from `physionet-data.eicu_crd.lab`
        where
            lower(labname) = 'creatinine'
            and 0 <= labresultoffset
            and labresultoffset < 1440
        group by patientunitstayid, labresultoffset
    ),
    cr_grouped as (
        select et.patientunitstayid, start_time, end_time, max(creatinine) as creatinine
        from expanded_times et
        left join
            cr_tab cr
            on et.patientunitstayid = cr.patientunitstayid
            and et.start_time <= cr.time
            and cr.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),
    uo_tab as (
        select patientunitstayid, intakeoutputoffset as time, sum(outputtotal) as urine
        from `physionet-data.eicu_crd.intakeoutput`
        where 0 <= intakeoutputoffset and intakeoutputoffset < 1440
        group by patientunitstayid, intakeoutputoffset
    ),
    uo_grouped as (
        select et.patientunitstayid, start_time, end_time, sum(urine) as urine
        from expanded_times et
        left join
            uo_tab uo
            on et.patientunitstayid = uo.patientunitstayid
            and et.start_time <= uo.time
            and uo.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),
    renal as (
        select
            cr.patientunitstayid,
            cr.start_time,
            cr.end_time,
            case
                when creatinine is not null or urine is not null then 1 else 0
            end as renal_notnull
        from cr_grouped cr
        inner join
            uo_grouped uo
            on cr.patientunitstayid = uo.patientunitstayid
            and cr.start_time = uo.start_time
    ),

    -- cns score
    gcs_e as (
        select
            patientunitstayid,
            physicalexamoffset as time,
            safe_cast(physicalexamvalue as int64) as gcs_e
        from `physionet-data.eicu_crd.physicalexam`
        where
            lower(physicalexampath) like '%gcs/eyes%'
            and safe_cast(physicalexamvalue as int64) >= 1
            and safe_cast(physicalexamvalue as int64) <= 4
            and 0 <= physicalexamoffset
            and physicalexamoffset < 1440
    ),
    gcs_v as (
        select
            patientunitstayid,
            physicalexamoffset as time,
            safe_cast(physicalexamvalue as int64) as gcs_v
        from `physionet-data.eicu_crd.physicalexam`
        where
            lower(physicalexampath) like '%gcs/verbal%'
            and safe_cast(physicalexamvalue as int64) >= 1
            and safe_cast(physicalexamvalue as int64) <= 5
            and 0 <= physicalexamoffset
            and physicalexamoffset < 1440
    ),
    gcs_m as (
        select
            patientunitstayid,
            physicalexamoffset as time,
            safe_cast(physicalexamvalue as int64) as gcs_m
        from `physionet-data.eicu_crd.physicalexam`
        where
            lower(physicalexampath) like '%gcs/motor%'
            and safe_cast(physicalexamvalue as int64) >= 1
            and safe_cast(physicalexamvalue as int64) <= 6
            and 0 <= physicalexamoffset
            and physicalexamoffset < 1440
    ),
    gcs_tab as (
        select
            gcs_e.patientunitstayid,
            gcs_e.time,
            gcs_e.gcs_e + gcs_v.gcs_v + gcs_m.gcs_m as gcs
        from gcs_e
        inner join
            gcs_v
            on gcs_e.patientunitstayid = gcs_v.patientunitstayid
            and gcs_e.time = gcs_v.time
        inner join
            gcs_m
            on gcs_e.patientunitstayid = gcs_m.patientunitstayid
            and gcs_e.time = gcs_m.time
    ),
    cns as (
        select
            et.patientunitstayid,
            start_time,
            end_time,
            case when max(gcs) is not null then 1 else 0 end as cns_notnull
        from expanded_times et
        left join
            gcs_tab gc
            on et.patientunitstayid = gc.patientunitstayid
            and et.start_time <= gc.time
            and gc.time < et.end_time
        group by patientunitstayid, start_time, end_time
    ),

    -- sofa score
    sofa_tab as (
        select
            rp.patientunitstayid,
            rp.start_time,
            rp.end_time,
            respiration_notnull,
            cardiovascular_notnull,
            coagulation_notnull,
            liver_notnull,
            renal_notnull,
            cns_notnull
        from respiration rp
        inner join
            cardiovascular cv
            on rp.patientunitstayid = cv.patientunitstayid
            and rp.start_time = cv.start_time
        inner join
            coagulation cg
            on rp.patientunitstayid = cg.patientunitstayid
            and rp.start_time = cg.start_time
        inner join
            liver lv
            on rp.patientunitstayid = lv.patientunitstayid
            and rp.start_time = lv.start_time
        inner join
            renal rn
            on rp.patientunitstayid = rn.patientunitstayid
            and rp.start_time = rn.start_time
        inner join
            cns cn
            on rp.patientunitstayid = cn.patientunitstayid
            and rp.start_time = cn.start_time
    ),
    sofa_24hr_nonnull as (
        select
            patientunitstayid,
            max(respiration_notnull) as respiration_notnull,
            max(cardiovascular_notnull) as cardiovascular_notnull,
            max(coagulation_notnull) as coagulation_notnull,
            max(liver_notnull) as liver_notnull,
            max(renal_notnull) as renal_notnull,
            max(cns_notnull) as cns_notnull
        from sofa_tab
        group by patientunitstayid
    )
select
    count(*) as n_patients,
    sum(respiration_notnull) as respiration_notnull,
    round(100 * sum(respiration_notnull) / count(*), 1) as respiration_nonnull_rate,
    sum(cardiovascular_notnull) as cardiovascular_notnull,
    round(
        100 * sum(cardiovascular_notnull) / count(*), 1
    ) as cardiovascular_notnull_rate,
    sum(coagulation_notnull) as coagulation_notnull,
    round(100 * sum(coagulation_notnull) / count(*), 1) as coagulation_notnull_rate,
    sum(liver_notnull) as liver_notnull,
    round(100 * sum(liver_notnull) / count(*), 1) as liver_notnull_rate,
    sum(renal_notnull) as renal_notnull,
    round(100 * sum(renal_notnull) / count(*), 1) as renal_notnull_rate,
    sum(cns_notnull) as cns_notnull,
    round(100 * sum(cns_notnull) / count(*), 1) as cns_notnull_rate
from sofa_24hr_nonnull
