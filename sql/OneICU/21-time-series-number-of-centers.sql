select icu_admission_year, count(distinct hospital_id) as number_of_centers
from `medicu-biz.snapshots_one_icu_derived.extended_icu_stays_20250716`
where icu_admission_year <= 2024
group by icu_admission_year
order by icu_admission_year
