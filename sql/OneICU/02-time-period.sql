select
  min(icu_admission_year) as start_year_of_data_collection,
  max(icu_admission_year) as end_year_of_data_collection
from `medicu-biz.latest_one_icu_derived.extended_icu_stays`
