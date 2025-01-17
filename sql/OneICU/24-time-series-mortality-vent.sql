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
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
        group by icu_admission_year
    ),
    mv_use as (
        select
            icu_admission_year,
            round(
                100 * count(distinct mv.icu_stay_id) / count(distinct ic.icu_stay_id), 1
            ) as mv_proportion
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays` ic
        left join
            `medicu-beta.latest_one_icu.mechanical_ventilations` mv using (icu_stay_id)
        group by icu_admission_year
    )
select *
from mortality_stats
inner join mv_use using (icu_admission_year)
order by icu_admission_year
