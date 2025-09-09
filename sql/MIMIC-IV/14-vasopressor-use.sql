select
    'vasopressor' as field_name,
    count(distinct stay_id) as count,
    round(
        100
        * count(distinct stay_id)
        / (
            select count(distinct stay_id)
            from `physionet-data.mimiciv_3_1_derived.icustay_detail`
        ),
        1
    ) as proportion
from `medicu-workspace-takapion.mimiciv_derived.vasoactive_agent`
where
    dopamine > 0
    or epinephrine > 0
    or norepinephrine > 0
    or phenylephrine > 0
    or vasopressin > 0
