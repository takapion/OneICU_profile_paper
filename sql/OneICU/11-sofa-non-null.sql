with
    stayed_more_than_1_day as (
        select
            icu_stay_id,
            time_window_index,
            respiration,
            coagulation,
            liver,
            cardiovascular,
            cns,
            renal
        from `medicu-beta.latest_one_icu_derived.sofa_hourly`
        inner join
            `medicu-beta.latest_one_icu_derived.extended_icu_stays` using (icu_stay_id)
        where icu_length_of_stay >= 1
    ),
    overall_stats as (
        select count(distinct icu_stay_id) as n_patients from stayed_more_than_1_day
    ),
    respiration_stats as (
        select count(distinct icu_stay_id) as respiration_notnull
        from stayed_more_than_1_day
        where
            time_window_index >= 0
            and time_window_index < 24
            and respiration is not null
    ),
    cardiovascular_stats as (
        select count(distinct icu_stay_id) as cardiovascular_notnull
        from stayed_more_than_1_day
        where
            time_window_index >= 0
            and time_window_index < 24
            and cardiovascular is not null
    ),
    coagulation_stats as (
        select count(distinct icu_stay_id) as coagulation_notnull
        from stayed_more_than_1_day
        where
            time_window_index >= 0
            and time_window_index < 24
            and coagulation is not null
    ),
    liver_stats as (
        select count(distinct icu_stay_id) as liver_notnull
        from stayed_more_than_1_day
        where time_window_index >= 0 and time_window_index < 24 and liver is not null
    ),
    renal_stats as (
        select count(distinct icu_stay_id) as renal_notnull
        from stayed_more_than_1_day
        where time_window_index >= 0 and time_window_index < 24 and renal is not null
    ),
    cns_stats as (
        select count(distinct icu_stay_id) as cns_notnull
        from stayed_more_than_1_day
        where time_window_index >= 0 and time_window_index < 24 and cns is not null
    )
select
    n_patients,
    respiration_notnull,
    round(100 * respiration_notnull / n_patients, 1) as respiration_nonnull_rate,
    coagulation_notnull,
    round(100 * cardiovascular_notnull / n_patients, 1) as cardiovascular_nonnull_rate,
    cns_notnull,
    round(100 * coagulation_notnull / n_patients, 1) as coagulation_nonnull_rate,
    liver_notnull,
    round(100 * liver_notnull / n_patients, 1) as liver_nonnull_rate,
    renal_notnull,
    round(100 * renal_notnull / n_patients, 1) as renal_nonnull_rate,
    cardiovascular_notnull,
    round(100 * cns_notnull / n_patients, 1) as cns_nonnull_rate
from overall_stats
cross join respiration_stats
cross join cardiovascular_stats
cross join coagulation_stats
cross join liver_stats
cross join renal_stats
cross join cns_stats
