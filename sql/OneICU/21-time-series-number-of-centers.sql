select icu_admission_year, count(distinct hospital_id) as number_of_centers
from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
where icu_admission_year <= 2024
group by icu_admission_year
order by icu_admission_year
