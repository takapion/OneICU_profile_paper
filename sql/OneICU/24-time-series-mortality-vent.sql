with
    mortality_stats as (
        select
            icu_admission_year,
            round(
                100
                * countif(mortality in ('icu'))
                / countif(mortality in ('icu', 'in_hospital', 'survival')),
                1
            ) as icu_mortality,
            round(
                100
                * countif(mortality in ('icu', 'in_hospital'))
                / countif(mortality in ('icu', 'in_hospital', 'survival')),
                1
            ) as in_hospital_mortality
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
        where icu_admission_year <= 2024
        group by icu_admission_year
    ),
    mv_use as (
        select
            icu_admission_year,
            round(
                100 * count(distinct mv.icu_stay_id) / count(distinct ic.icu_stay_id), 1
            ) as mv_proportion
        from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` ic
        left join
            `medicu-biz.snapshots_one_icu.mechanical_ventilations_20250716` mv using (icu_stay_id)
        where icu_admission_year <= 2024
        group by icu_admission_year
    )
select *
from mortality_stats
inner join mv_use using (icu_admission_year)
order by icu_admission_year
