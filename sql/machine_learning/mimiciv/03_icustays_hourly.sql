with
    generate_time_window_indices as (
        select
            stay_id as icu_stay_id,
            intime as in_time,
            outtime as out_time,
            case
                when outtime = datetime_trunc(outtime, hour)
                then
                    generate_array(
                        0,
                        cast(
                            floor(
                                datetime_diff(
                                    outtime, datetime_trunc(intime, hour), hour
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
                                datetime_diff(
                                    outtime, datetime_trunc(intime, hour), hour
                                )
                            ) as int64
                        )
                    )
            end as time_window_indices
        from `physionet-data.mimiciv_3_1_icu.icustays`
    ),
    generate_time_windows as (
        select
            icu_stay_id,
            in_time,
            out_time,
            time_window_index,
            datetime_add(
                datetime_trunc(in_time, hour), interval time_window_index hour
            ) as start_time,
            datetime_add(
                datetime_trunc(in_time, hour), interval time_window_index + 1 hour
            ) as end_time
        from generate_time_window_indices twi
        cross join unnest(twi.time_window_indices) as time_window_index
    )
select *
from generate_time_windows
