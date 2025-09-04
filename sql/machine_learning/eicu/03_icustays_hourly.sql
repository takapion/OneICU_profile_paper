with
    generate_time_window_indices as (
        select
            patientunitstayid as icu_stay_id,
            unitadmitoffset as in_time,
            unitdischargeoffset as out_time,
            case
                when mod(unitdischargeoffset, 60) = 0
                then
                    generate_array(
                        0,
                        cast(unitdischargeoffset / 60 - 1 as int64)
                    )
                else
                    generate_array(
                        0,
                        cast(ceil(unitdischargeoffset / 60) - 1 as int64)
                    )
            end as time_window_indices
        from `physionet-data.eicu_crd_derived.icustay_detail`
        where unitdischargeoffset > 0
    ),
    generate_time_windows as (
        select
            icu_stay_id,
            in_time,
            out_time,
            time_window_index,
            time_window_index * 60 as start_time,
            (time_window_index + 1) * 60 as end_time
        from generate_time_window_indices twi
        cross join unnest(twi.time_window_indices) as time_window_index
    )
select *
from generate_time_windows
