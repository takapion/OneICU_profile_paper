with
    weights as (
        select
            icu_stay_id,
            body_weight_imputed as body_weight,
            percentile_cont(body_weight_imputed, 0.5) over (
                partition by female
            ) as median_by_gender
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where icu_admission_year <= 2024
    ),
    weights_imputed as (
        select icu_stay_id, coalesce(body_weight, median_by_gender) as body_weight
        from weights
    ),
    ne as (
        select
            icu_stay_id,
            min_by(unit_per_hour, start_time) as initial_norepinephrine_rate
        from
            `medicu-biz.snapshots_one_icu_derived.infusion_injection_active_ingredient_rate_20250716`
        where active_ingredient_name = 'noradrenaline'
        group by icu_stay_id
    ),
    ne_standardized as (
        select
            icu_stay_id,
            round(
                initial_norepinephrine_rate / (body_weight * 0.06), 3
            ) as initial_norepinephrine_rate_standardized
        from ne
        inner join weights_imputed using (icu_stay_id)
    )
select distinct
    percentile_cont(initial_norepinephrine_rate_standardized, 0.5) over () as median,
    percentile_cont(initial_norepinephrine_rate_standardized, 0.25) over (
    ) as percentile_25,
    percentile_cont(initial_norepinephrine_rate_standardized, 0.75) over (
    ) as percentile_75
from ne_standardized
