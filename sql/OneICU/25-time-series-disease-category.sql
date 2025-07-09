with recategorize as (
  select
    icu_stay_id,
    case
      when category = 'infection' or category = 'sepsis' then 'sepsis_infection'
      when category in ('poisoning', 'burn', 'temperature_disorder', 'hanging_asphyxiation') then 'toxicological_environmental_disorders'
      when category = 'null' then null
      else category
      end as category
  from `medicu-biz.latest_one_icu_derived.extended_icu_diagnoses`
  where primary
),
overall_diag_cat as (
  select
    category,
    'overall' as icu_admission_year,
    count(*) as count,
    round(count(*) / (select count(distinct icu_stay_id) from recategorize where category is not null) * 100, 1) as overall_proportion
  from recategorize
  where category is not null
  group by category
),
diag_cat as (
  select
    category,
    icu_admission_year,
    count(*) as count,
  from recategorize
  inner join `medicu-biz.latest_one_icu_derived.extended_icu_stays` using(icu_stay_id)
  where category is not null
  group by category, icu_admission_year
),
yearly_counts as (
  select
    icu_admission_year,
    count(distinct icu_stay_id) as total_icu_stays
  from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
  group by icu_admission_year
),
yearly_stats as (
  select
    d.category,
    d.icu_admission_year,
    d.count,
    round(100 * d.count / yc.total_icu_stays, 1) as proportion
  from diag_cat d
  inner join yearly_counts yc using(icu_admission_year)
),
pivoted as (
  select
    category,
    max(case when icu_admission_year = 2012 then concat(cast(count as string), ' (', cast(proportion as string), '%)') end) as year_2012,
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