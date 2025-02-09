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
diag_cat as (
  select
    category,
    count(*) as count,
  from recategorize
  where category is not null
  group by category
),
n_patients_with_diag as (
  select count(distinct icu_stay_id) as n_patients
  from recategorize
  where category is not null
)
select
  category,
  count,
  round(100 * count / n_patients, 1) as proportion,
from diag_cat
cross join n_patients_with_diag
order by count desc
