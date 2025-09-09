with
    ne_standardized as (
        select
            stay_id,
            round(
                min_by(norepinephrine, starttime), 3
            ) as initial_norepinephrine_rate_standardized
        from `medicu-workspace-takapion.mimiciv_derived.vasoactive_agent`
        group by stay_id
    )
select distinct
    percentile_cont(initial_norepinephrine_rate_standardized, 0.5) over () as median,
    percentile_cont(initial_norepinephrine_rate_standardized, 0.25) over (
    ) as percentile_25,
    percentile_cont(initial_norepinephrine_rate_standardized, 0.75) over (
    ) as percentile_75
from ne_standardized
