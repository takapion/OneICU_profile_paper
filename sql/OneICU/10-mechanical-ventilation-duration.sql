with
    generate_time_window_indices as (
        select
            it.icu_stay_id,
            it.in_time,
            it.out_time,
            timestamp_add(timestamp_trunc(in_time, hour), interval 1 hour) as end_time,
            generate_array(
                0,
                cast(
                    timestamp_diff(
                        timestamp_trunc(it.out_time, hour),
                        timestamp_trunc(it.in_time, hour),
                        hour
                    ) as int64
                )
            ) as time_window_indices
        from `medicu-biz.snapshots_one_icu.icu_stays_20250716` it
        where icu_admission_year <= 2024
    ),
    generate_time_windows as (
        select
            icu_stay_id,
            in_time,
            out_time,
            time_window_index,
            timestamp_add(end_time, interval time_window_index hour) as end_time
        from generate_time_window_indices twi
        cross join unnest(twi.time_window_indices) as time_window_index
    ),
    calculate_start_time as (
        select
            icu_stay_id,
            in_time,
            out_time,
            time_window_index,
            timestamp_sub(end_time, interval 1 hour) as time_window_start_time,
            end_time as time_window_end_time
        from generate_time_windows
    ),
    mv_index as (
        select
            icu_stay_id,
            time_window_index,
            time_window_start_time,
            time_window_end_time,
            case
                when
                    time_window_start_time <= start_time
                    and start_time < time_window_end_time
                then 1
                when
                    time_window_start_time <= end_time
                    and end_time < time_window_end_time
                then 1
                when
                    start_time < time_window_start_time
                    and time_window_end_time <= end_time
                then 1
                else 0
            end as mechanical_ventilation_used
        from calculate_start_time
        inner join
            `medicu-biz.snapshots_one_icu.mechanical_ventilations_20250716` using (icu_stay_id)
        inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using(icu_stay_id)
        where icu_admission_year <= 2024
    ),
    mv_index_summarized as (
        select
            icu_stay_id,
            time_window_index,
            time_window_start_time,
            time_window_end_time,
            max(mechanical_ventilation_used) as mechanical_ventilation_used
        from mv_index
        group by
            icu_stay_id, time_window_index, time_window_start_time, time_window_end_time
    ),
    mv_patients_length as (
        select icu_stay_id, sum(mechanical_ventilation_used) as mv_length
        from mv_index_summarized
        group by icu_stay_id
    )
select distinct
    'mechanical_ventilation_duration' as field_name,
    round(percentile_cont(mv_length, 0.5) over () / 24, 1) as median,
    round(percentile_cont(mv_length, 0.25) over () / 24, 1) as percentile_25,
    round(percentile_cont(mv_length, 0.75) over () / 24, 1) as percentile_75,
from mv_patients_length
