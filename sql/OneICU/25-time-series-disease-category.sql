with recategorize as (
  select
    icu_stay_id,
    case
      when category in ('infection', 'sepsis') then 'sepsis_infection'
      when category in ('poisoning', 'burn', 'temperature_disorder', 'hanging_asphyxiation') then 'toxicological_environmental_disorders'
      when category = 'null' then 'other'
      when category is null then 'other'
      else category
      end as category
  from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
  left join (
    select icu_stay_id, category
    from `medicu-biz.snapshots_one_icu_derived.unioned_icu_diagnoses_20250716`
    where primary
  ) using(icu_stay_id)
  where icu_admission_year <= 2024
),
overall_diag_cat as (
  select
    category,
    'overall' as icu_admission_year,
    count(*) as count,
    round(count(*) * 100 / sum(count(*)) over(), 1) as overall_proportion
  from recategorize
  group by category
),
yearly_stats as (
  select
    category,
    icu_admission_year,
    count(*) as count,
    round(count(*) * 100 / sum(count(*)) over(partition by icu_admission_year), 1) as proportion
  from recategorize
  inner join `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716` using(icu_stay_id)
  where category is not null and icu_admission_year <= 2024
  group by category, icu_admission_year
),
pivoted as (
  select
    category,
    max(case when icu_admission_year = 2013 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2013,
    max(case when icu_admission_year = 2014 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2014,
    max(case when icu_admission_year = 2015 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2015,
    max(case when icu_admission_year = 2016 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2016,
    max(case when icu_admission_year = 2017 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2017,
    max(case when icu_admission_year = 2018 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2018,
    max(case when icu_admission_year = 2019 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2019,
    max(case when icu_admission_year = 2020 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2020,
    max(case when icu_admission_year = 2021 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2021,
    max(case when icu_admission_year = 2022 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2022,
    max(case when icu_admission_year = 2023 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2023,
    max(case when icu_admission_year = 2024 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2024,
    max(case when icu_admission_year = 2025 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2025
  from yearly_stats
  group by category
)
select
  o.category,
  o.count as overall_count,
  o.overall_proportion,
  p.*
from overall_diag_cat o
join pivoted p on o.category = p.category
order by overall_count desc
