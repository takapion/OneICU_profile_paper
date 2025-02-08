with recategorize as (
  select
    icu_stay_id,
    case
      when category = 'infection' then 'sepsis_infection'
      when category = 'sepsis' then 'sepsis_infection'
      when category = 'poisoning' then 'toxicological_environmental_disorders'
      when category = 'burn' then 'toxicological_environmental_disorders'
      when category = 'temperature_disorder' then 'toxicological_environmental_disorders'
      when category = 'hanging_asphyxiation' then 'toxicological_environmental_disorders'
      when category = 'null' then null
      else category
      end as category
  from `medicu-beta.snapshots_one_icu_derived.extended_icu_diagnoses_20250206`
  where primary
),
overall_diag_cat as (
  select
    category,
    'overall' as icu_admission_year,
    count(*) as count,
    round(count(*) / (select count(distinct icu_stay_id) from `medicu-beta.snapshots_one_icu_derived.extended_icu_diagnoses_20250206` where category is not null), 1) as proportion
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
  inner join `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206` using(icu_stay_id)
  where category is not null
  group by category, icu_admission_year
),
yearly_counts as (
  select
    icu_admission_year,
    count(distinct icu_stay_id) as total_icu_stays
  from `medicu-beta.snapshots_one_icu_derived.extended_icu_stays_20250206`
  group by icu_admission_year
)
select
  category,
  icu_admission_year,
  count,
  round(100 * count / total_icu_stays, 1) as proportion
from diag_cat d
inner join yearly_counts using(icu_admission_year)
order by icu_admission_year asc, count desc
