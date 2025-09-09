with
    tm as (
        select stay_id, charttime
        from `mimiciv_derived.ventilator_setting`
        union distinct
        select stay_id, charttime
        from `physionet-data.mimiciv_3_1_derived.oxygen_delivery`
    ),
    vs as (
        select
            tm.stay_id,
            tm.charttime,
            -- source data columns, here for debug
            o2_delivery_device_1,
            coalesce(ventilator_mode, ventilator_mode_hamilton) as vent_mode,
            -- case statement determining the type of intervention
            -- done in order of priority: trach > mech vent > NIV > high flow > o2
            case
                -- tracheostomy
                when
                    o2_delivery_device_1 in (
                        'Tracheostomy tube',
                        -- 1135 observations for T-Piece
                        -- could be either InvasiveVent or Tracheostomy, so omit
                        -- 'T-piece',
                        'Trach mask '  -- 16435 observations
                    )
                then 'Tracheostomy'
                -- mechanical / invasive ventilation
                when
                    o2_delivery_device_1 in ('Endotracheal tube')
                    or ventilator_mode in (
                        '(S) CMV',
                        'APRV',
                        'APRV/Biphasic+ApnPress',
                        'APRV/Biphasic+ApnVol',
                        'APV (cmv)',
                        'Ambient',
                        'Apnea Ventilation',
                        'CMV',
                        'CMV/ASSIST',
                        'CMV/ASSIST/AutoFlow',
                        'CMV/AutoFlow',
                        'CPAP/PPS',
                        'CPAP/PSV',
                        'CPAP/PSV+Apn TCPL',
                        'CPAP/PSV+ApnPres',
                        'CPAP/PSV+ApnVol',
                        'MMV',
                        'MMV/AutoFlow',
                        'MMV/PSV',
                        'MMV/PSV/AutoFlow',
                        'P-CMV',
                        'PCV+',
                        'PCV+/PSV',
                        'PCV+Assist',
                        'PRES/AC',
                        'PRVC/AC',
                        'PRVC/SIMV',
                        'PSV/SBT',
                        'SIMV',
                        'SIMV/AutoFlow',
                        'SIMV/PRES',
                        'SIMV/PSV',
                        'SIMV/PSV/AutoFlow',
                        'SIMV/VOL',
                        'SYNCHRON MASTER',
                        'SYNCHRON SLAVE',
                        'VOL/AC'
                    )
                    or ventilator_mode_hamilton in (
                        'APRV',
                        'APV (cmv)',
                        'Ambient',
                        '(S) CMV',
                        'P-CMV',
                        'SIMV',
                        'APV (simv)',
                        'P-SIMV',
                        'VS',
                        'ASV'
                    )
                then 'InvasiveVent'
                -- NIV
                when
                    o2_delivery_device_1 in (
                        'Bipap mask ',  -- 8997 observations
                        'CPAP mask '  -- 5568 observations
                    )
                    or ventilator_mode_hamilton in ('DuoPaP', 'NIV', 'NIV-ST')
                then 'NonInvasiveVent'
                -- high flow nasal cannula
                when
                    o2_delivery_device_1 in (
                        'High flow nasal cannula'  -- 925 observations
                    )
                then 'HFNC'
                -- non rebreather
                when
                    o2_delivery_device_1 in (
                        'Non-rebreather',  -- 5182 observations
                        'Face tent',  -- 24601 observations
                        'Aerosol-cool',  -- 24560 observations
                        'Venti mask ',  -- 1947 observations
                        'Medium conc mask ',  -- 1888 observations
                        'Ultrasonic neb',  -- 9 observations
                        'Vapomist',  -- 3 observations
                        'Oxymizer',  -- 1301 observations
                        'High flow neb',  -- 10785 observations
                        'Nasal cannula'
                    )
                then 'SupplementalOxygen'
                when o2_delivery_device_1 in ('None')
                then 'None'
                -- not categorized: other
                else null
            end as ventilation_status
        from tm
        left join
            `mimiciv_derived.ventilator_setting` vs
            on tm.stay_id = vs.stay_id
            and tm.charttime = vs.charttime
        left join
            `physionet-data.mimiciv_3_1_derived.oxygen_delivery` od
            on tm.stay_id = od.stay_id
            and tm.charttime = od.charttime
    ),
    mv as (
        select
            'mechanical_ventilation' as field_name,
            count(distinct stay_id) as count,
            round(
                100
                * count(distinct stay_id)
                / (
                    select count(distinct stay_id)
                    from `physionet-data.mimiciv_3_1_derived.icustay_detail`
                ),
                1
            ) as proportion
        from vs
        where ventilation_status in ('InvasiveVent', 'Tracheostomy')
    ),
    nppv as (
        select
            'nppv' as field_name,
            count(distinct stay_id) as count,
            round(
                100
                * count(distinct stay_id)
                / (
                    select count(distinct stay_id)
                    from `physionet-data.mimiciv_3_1_derived.icustay_detail`
                ),
                1
            ) as proportion
        from vs
        where ventilation_status = ('NonInvasiveVent')
    ),
    hfo as (
        select
            'hfo' as field_name,
            count(distinct stay_id) as count,
            round(
                100
                * count(distinct stay_id)
                / (
                    select count(distinct stay_id)
                    from `physionet-data.mimiciv_3_1_derived.icustay_detail`
                ),
                1
            ) as proportion
        from vs
        where ventilation_status = ('HFNC')
    ),
    crrt as (
        select
            'crrt' as field_name,
            count(distinct stay_id) as count,
            round(
                100
                * count(distinct stay_id)
                / (
                    select count(distinct stay_id)
                    from `physionet-data.mimiciv_3_1_derived.icustay_detail`
                ),
                1
            ) as proportion
        from `physionet-data.mimiciv_3_1_derived.crrt`
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
