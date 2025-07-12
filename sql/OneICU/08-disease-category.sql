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
      when category = 'null' then 'others'
      when category is null then 'others'
      else category
      end as category
  from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
  left join (
    select icu_stay_id, category
    from `medicu-biz.latest_one_icu_derived.unioned_icu_diagnoses`
    where primary
  ) using(icu_stay_id)
  where icu_admission_year <= 2024
)
select
  category,
  count(*) as count,
  round(count(*) * 100 / sum(count(*)) over(), 1) as proportion
from recategorize
group by category
order by proportion desc
