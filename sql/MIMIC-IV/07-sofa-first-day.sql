with
    first_day_sofa_per_patients as (
        select max(sofa_24hours) as sofa
        from `mimiciv_derived.sofa`
        where sofa_24hours is not null and hr >= 0 and hr < 24
        group by stay_id
    ),
    sofa_stats as (
        select distinct
            'sofa' as field_name,
            percentile_cont(sofa, 0.5) over () as median,
            percentile_cont(sofa, 0.25) over () as percentile_25,
            percentile_cont(sofa, 0.75) over () as percentile_75
        from first_day_sofa_per_patients
    ),
    sofa_missing as (
        select
            'sofa' as field_name,
            (select count(distinct stay_id) from `mimiciv_derived.icustay_detail`)
            - count(distinct stay_id) as n_missing,
            round(
                (
                    (
                        select count(distinct stay_id)
                        from `mimiciv_derived.icustay_detail`
                    )
                    - count(distinct stay_id)
                ) / (
                    select count(distinct stay_id) from `mimiciv_derived.icustay_detail`
                ),
                1
            ) as proportion_missing
        from `mimiciv_derived.sofa`
        where sofa_24hours is not null and hr >= 0 and hr < 24
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from sofa_stats
inner join sofa_missing using (field_name)
