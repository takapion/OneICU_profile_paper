with
    per_minute as (
        select
            i.icu_stay_id,
            i.time_window_index,
            timestamp_diff(v.time, i.start_time, minute) as minute_idx,
            v.invasive_mbp,
            v.hr,
            v.rr,
            v.spo2
        from `medicu-production.research_database_description_2024.03_icustays_hourly` as i
        join `medicu-biz.snapshots_one_icu.vital_measurements_20250716` as v
            on i.icu_stay_id = v.icu_stay_id
            and v.time >= i.start_time
            and v.time < i.end_time
        where v.invasive_mbp is not null
        qualify count(*) over (partition by i.icu_stay_id, i.time_window_index) = 60
    ),
    
    med as (
        select
            icu_stay_id,
            time_window_index,
            percentile_cont(hr, 0.5) over (partition by icu_stay_id, time_window_index) as hr_median,
            percentile_cont(rr, 0.5) over (partition by icu_stay_id, time_window_index) as rr_median,
            percentile_cont(spo2, 0.5) over (partition by icu_stay_id, time_window_index) as spo2_median
        from per_minute
        qualify row_number() over (partition by icu_stay_id, time_window_index order by minute_idx) = 1
    ),
    
    pivot_src as (
        select
            icu_stay_id,
            time_window_index,
            format('%02d', minute_idx) as minute_str,
            invasive_mbp
        from per_minute
    ),
    
    pivoted as (
        select * from pivot_src
        pivot (max(invasive_mbp) for minute_str in (
            '00','01','02','03','04','05','06','07','08','09',
            '10','11','12','13','14','15','16','17','18','19',
            '20','21','22','23','24','25','26','27','28','29',
            '30','31','32','33','34','35','36','37','38','39',
            '40','41','42','43','44','45','46','47','48','49',
            '50','51','52','53','54','55','56','57','58','59'
        ))
    )

select
    p.icu_stay_id,
    p.time_window_index,
    m.hr_median,
    m.rr_median,
    m.spo2_median,
    `00` as invasive_mbp_00,
    `01` as invasive_mbp_01,
    `02` as invasive_mbp_02,
    `03` as invasive_mbp_03,
    `04` as invasive_mbp_04,
    `05` as invasive_mbp_05,
    `06` as invasive_mbp_06,
    `07` as invasive_mbp_07,
    `08` as invasive_mbp_08,
    `09` as invasive_mbp_09,
    `10` as invasive_mbp_10,
    `11` as invasive_mbp_11,
    `12` as invasive_mbp_12,
    `13` as invasive_mbp_13,
    `14` as invasive_mbp_14,
    `15` as invasive_mbp_15,
    `16` as invasive_mbp_16,
    `17` as invasive_mbp_17,
    `18` as invasive_mbp_18,
    `19` as invasive_mbp_19,
    `20` as invasive_mbp_20,
    `21` as invasive_mbp_21,
    `22` as invasive_mbp_22,
    `23` as invasive_mbp_23,
    `24` as invasive_mbp_24,
    `25` as invasive_mbp_25,
    `26` as invasive_mbp_26,
    `27` as invasive_mbp_27,
    `28` as invasive_mbp_28,
    `29` as invasive_mbp_29,
    `30` as invasive_mbp_30,
    `31` as invasive_mbp_31,
    `32` as invasive_mbp_32,
    `33` as invasive_mbp_33,
    `34` as invasive_mbp_34,
    `35` as invasive_mbp_35,
    `36` as invasive_mbp_36,
    `37` as invasive_mbp_37,
    `38` as invasive_mbp_38,
    `39` as invasive_mbp_39,
    `40` as invasive_mbp_40,
    `41` as invasive_mbp_41,
    `42` as invasive_mbp_42,
    `43` as invasive_mbp_43,
    `44` as invasive_mbp_44,
    `45` as invasive_mbp_45,
    `46` as invasive_mbp_46,
    `47` as invasive_mbp_47,
    `48` as invasive_mbp_48,
    `49` as invasive_mbp_49,
    `50` as invasive_mbp_50,
    `51` as invasive_mbp_51,
    `52` as invasive_mbp_52,
    `53` as invasive_mbp_53,
    `54` as invasive_mbp_54,
    `55` as invasive_mbp_55,
    `56` as invasive_mbp_56,
    `57` as invasive_mbp_57,
    `58` as invasive_mbp_58,
    `59` as invasive_mbp_59
from pivoted as p
join med as m using (icu_stay_id, time_window_index)
order by p.icu_stay_id, p.time_window_index
