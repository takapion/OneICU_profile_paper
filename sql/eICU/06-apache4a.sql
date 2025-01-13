with
    apache4a_stats as (
        select distinct
            'apache4a_score' as field_name,
            percentile_cont(apachescore, 0.5) over () as median,
            percentile_cont(apachescore, 0.25) over () as percentile_25,
            percentile_cont(apachescore, 0.75) over () as percentile_75
        from `physionet-data.eicu_crd.apachepatientresult`
        where apachescore is not null and apacheversion = 'IVa'
    ),
    apache4a_missing as (
        select
            'apache4a_score' as field_name,
            (
                select count(distinct patientunitstayid)
                from `physionet-data.eicu_crd_derived.icustay_detail`
            )
            - count(distinct patientunitstayid) as n_missing,
            round(
                100 * (
                    (
                        select count(distinct patientunitstayid)
                        from `physionet-data.eicu_crd_derived.icustay_detail`
                    )
                    - count(distinct patientunitstayid)
                )
                / (
                    select count(distinct patientunitstayid)
                    from `physionet-data.eicu_crd_derived.icustay_detail`
                ),
                1
            ) as proportion_missing
        from `physionet-data.eicu_crd.apachepatientresult`
    )
select field_name, median, percentile_25, percentile_75, n_missing, proportion_missing
from apache4a_stats
inner join apache4a_missing using (field_name)
