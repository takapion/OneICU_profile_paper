with
    gender_standardized as (
        select
            patientunitstayid,
            case when gender = '' then 'Unknown' else gender end as gender,
            case
                when admissionweight <= 0 then null else admissionweight
            end as admissionweight
        from `physionet-data.eicu_crd.patient`
    ),
    weights as (
        select
            patientunitstayid,
            admissionweight,
            percentile_cont(admissionweight, 0.5) over (
                partition by gender
            ) as median_by_gender
        from gender_standardized
    ),
    weights_imputed as (
        select
            patientunitstayid,
            coalesce(admissionweight, median_by_gender) as body_weight
        from weights
    ),
    ne as (
        select
            patientunitstayid,
            infusionoffset,
            case
                when drugname like '%mcg/kg/min%'
                then infusionrate
                when drugname like '%mcg/kg/hr%'
                then infusionrate / 60
                when drugname like '%mcg/min%'
                then infusionrate / body_weight
                when drugname like '%mcg/hr%'
                then infusionrate / (60 * body_weight)
                when drugname like '%mg/min%'
                then 1000 * infusionrate / body_weight
                when drugname like '%units/min%'
                then 1000 * infusionrate / body_weight
                else infusionrate / (0.06 * body_weight)
            end as norepinephrine_rate_standardized
        from `physionet-data.eicu_crd.infusiondrug`
        inner join weights_imputed using (patientunitstayid)
        where
            drugname in (
                'Norepinephrine MAX 32 mg Dextrose 5% 250 ml (mcg/min)',
                'Norepinephrine MAX 32 mg Dextrose 5% 500 ml (mcg/min)',
                'Norepinephrine (mcg/hr)',
                'Norepinephrine (mcg/kg/hr)',
                'Norepinephrine (mcg/kg/min)',
                'Norepinephrine (mcg/min)',
                'Norepinephrine (mg/hr)',
                'Norepinephrine (mg/kg/min)',
                'Norepinephrine (mg/min)',
                'Norepinephrine (ml/hr)',
                'Norepinephrine STD 32 mg Dextrose 5% 282 ml (mcg/min)',
                'Norepinephrine STD 32 mg Dextrose 5% 500 ml (mcg/min)',
                'Norepinephrine STD 4 mg Dextrose 5% 250 ml (mcg/min)',
                'Norepinephrine STD 4 mg Dextrose 5% 500 ml (mcg/min)',
                'Norepinephrine STD 8 mg Dextrose 5% 250 ml (mcg/min)',
                'Norepinephrine STD 8 mg Dextrose 5% 500 ml (mcg/min)',
                'Norepinephrine (units/min)',
                'norepinephrine Volume (ml) (ml/hr)',
                -- levophed
                'Levophed (mcg/kg/min)',
                'levophed  (mcg/min)',
                'levophed (mcg/min)',
                'Levophed (mcg/min)',
                'Levophed (mg/hr)',
                'levophed (ml/hr)',
                'Levophed (ml/hr)',
                'NSS with LEVO (ml/hr)',
                'NSS w/ levo/vaso (ml/hr)'
            )
    ),
    ne_standardized as (
        select
            patientunitstayid,
            round(
                min_by(norepinephrine_rate_standardized, infusionoffset), 3
            ) as initial_norepinephrine_rate_standardized
        from ne
        group by patientunitstayid
    )
select distinct
    percentile_cont(initial_norepinephrine_rate_standardized, 0.5) over () as median,
    percentile_cont(initial_norepinephrine_rate_standardized, 0.25) over (
    ) as percentile_25,
    percentile_cont(initial_norepinephrine_rate_standardized, 0.75) over (
    ) as percentile_75
from ne_standardized
