with
    generate_time_window_indices as (
        select
            icu_stay_id,
            in_time,
            out_time,
            case
                when out_time = timestamp_trunc(out_time, hour)
                then
                    generate_array(
                        0,
                        cast(
                            floor(
                                timestamp_diff(
                                    out_time, timestamp_trunc(in_time, hour), hour
                                )
                            )
                            - 1 as int64
                        )
                    )
                else
                    generate_array(
                        0,
                        cast(
                            floor(
                                timestamp_diff(
                                    out_time, timestamp_trunc(in_time, hour), hour
                                )
                            ) as int64
                        )
                    )
            end as time_window_indices
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
    ),
    generate_time_windows as (
        select
            icu_stay_id,
            in_time,
            out_time,
            time_window_index,
            cast(
                timestamp_add(
                    timestamp_trunc(in_time, hour), interval time_window_index hour
                ) as timestamp
            ) as start_time,
            cast(
                timestamp_add(
                    timestamp_trunc(in_time, hour), interval time_window_index + 1 hour
                ) as timestamp
            ) as end_time
        from generate_time_window_indices twi
        cross join unnest(twi.time_window_indices) as time_window_index
    )
select *
from generate_time_windows
