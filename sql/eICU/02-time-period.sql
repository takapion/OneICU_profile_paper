select
    min(hospitaldischargeyear) as start_year_of_data_collection,
    max(hospitaldischargeyear) as end_year_of_data_collection
from `physionet-data.eicu_crd_derived.icustay_detail`
