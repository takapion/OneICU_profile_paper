with
    calc_shift as (
        select
            subject_id,
            anchor_year
            - cast(substr(anchor_year_group, 1, 4) as int64) as years_to_shift
        from `physionet-data.mimiciv_3_1_hosp.patients`
    ),
    back_to_real_time_range as (
        select
            subject_id,
            stay_id,
            concat(
                cast(
                    extract(
                        year
                        from datetime_sub(icu_intime, interval years_to_shift + 3 year)
                    ) as string
                ),
                '-',
                cast(
                    extract(
                        year from datetime_sub(icu_intime, interval years_to_shift year)
                    ) as string
                )
            ) as year_range
        from `mimiciv_derived.icustay_detail`
        left join calc_shift using (subject_id)
    )
select distinct year_range
from back_to_real_time_range
order by year_range
