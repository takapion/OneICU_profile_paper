with
    stayed_more_than_1_day as (
        select stay_id, hr, respiration, coagulation, liver, cardiovascular, cns, renal
        from `mimiciv_derived.sofa`
        inner join `mimiciv_derived.icustay_detail` using (stay_id)
        where los_icu >= 1
    ),
    overall_stats as (
        select count(distinct stay_id) as n_patients from stayed_more_than_1_day
    ),
    respiration_stats as (
        select count(distinct stay_id) as respiration_notnull
        from stayed_more_than_1_day
        where hr >= 0 and hr < 24 and respiration is not null
    ),
    cardiovascular_stats as (
        select count(distinct stay_id) as cardiovascular_notnull
        from stayed_more_than_1_day
        where hr >= 0 and hr < 24 and cardiovascular is not null
    ),
    coagulation_stats as (
        select count(distinct stay_id) as coagulation_notnull
        from stayed_more_than_1_day
        where hr >= 0 and hr < 24 and coagulation is not null
    ),
    liver_stats as (
        select count(distinct stay_id) as liver_notnull
        from stayed_more_than_1_day
        where hr >= 0 and hr < 24 and liver is not null
    ),
    renal_stats as (
        select count(distinct stay_id) as renal_notnull
        from stayed_more_than_1_day
        where hr >= 0 and hr < 24 and renal is not null
    ),
    cns_stats as (
        select count(distinct stay_id) as cns_notnull
        from stayed_more_than_1_day
        where hr >= 0 and hr < 24 and cns is not null
    )
select
    n_patients,
    respiration_notnull,
    round(100 * respiration_notnull / n_patients, 1) as respiration_notnull_rate,
    cardiovascular_notnull,
    round(100 * cardiovascular_notnull / n_patients, 1) as cardiovascular_notnull_rate,
    coagulation_notnull,
    round(100 * coagulation_notnull / n_patients, 1) as coagulation_notnull_rate,
    liver_notnull,
    round(100 * liver_notnull / n_patients, 1) as liver_notnull_rate,
    renal_notnull,
    round(100 * renal_notnull / n_patients, 1) as renal_notnull_rate,
    cns_notnull,
    round(100 * cns_notnull / n_patients, 1) as cns_notnull_rate
from overall_stats
cross join respiration_stats
cross join cardiovascular_stats
cross join coagulation_stats
cross join liver_stats
cross join renal_stats
cross join cns_stats
