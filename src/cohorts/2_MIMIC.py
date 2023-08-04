import pandas as pd
import numpy as np
import os
from utils import get_demography, print_demo

# get parent directory of this file
script_dir = os.path.dirname(__file__)

# get root directory of this project (two levels up from this file)
root_dir = os.path.abspath(os.path.join(script_dir, os.pardir, os.pardir))

# MIMIC
df0 = pd.read_csv(os.path.join(root_dir, 'data', 'MIMIC_data.csv'))

print(len(df0), "Initial rows in extracted MIMIC\n")
df1 = df0[df0.sepsis3 == 1]
print(f"Removed {len(df0) - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

df2 = df1[df1.race_group != 'Other']
print(f"Removed {len(df1) - len(df2)} stays without specified race group")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} sepsis stays with specified race group \n({demo2})\n")

df3 = df2[~df2.lactate_day1.isnull()]
print(f"Removed {len(df2) - len(df3)} stays without lactate day 1")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} stays with sepsis and lactate day 1 \n({demo3})\n")

df4 = df3[df3.los_icu >= 1]
print(f"Removed {len(df3) - len(df4)} stays with less than 24 hours")
demo4 = print_demo(get_demography(df4))
print(f"{len(df4)} stays with sepsis, lactate day 1, and LoS > 24h \n({demo4})\n")

df5 = df4[df4.admission_age >= 18]
print(f"Removed {len(df4) - len(df5)} stays with non-adult patient")
demo5 = print_demo(get_demography(df5))
print(f"{len(df5)} stays with sepsis, lactate day 1, LoS > 24h, adult patient \n({demo5})\n")

df6 = df5.sort_values(by=["subject_id", "stay_id"], ascending=True).groupby(
    'subject_id').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df5) - len(df6)} recurrent stays")
demo6 = print_demo(get_demography(df6))
print(f"{len(df6)} adults with sepsis, lactate day 1, LoS > 24h, adult patient, 1 stay per patient \n({demo6})\n")

cols_na = ['major_surgery', 'hypertension_present', 'heart_failure_present', 
            'copd_present', 'asthma_present', 'cad_present', 'ckd_stages', 
            'connective_disease', 'pneumonia', 'uti', 'biliary', 'skin', 'respiration',
            'coagulation', 'cardiovascular', 'cns', 'liver']

for c in cols_na:
    df6[c] = df6[c].fillna(0)

lab_ranges = {'po2_min': [0, 90, 1000],
        'pco2_max': [0, 40, 200],
        'ph_min': [5, 7.35, 10],
        'lactate_max': [0, 1.05, 30],
        'glucose_max': [0, 95, 2000],
        'sodium_min': [0, 140, 160],
        'potassium_max': [0, 3.5, 9.9],
        'cortisol_min': [0, 20, 70],
        'fibrinogen_min': [0, 200, 1000],
        'inr_max': [0, 1.1, 10],
        'resp_rate_mean': [0, 15, 50],
        'heart_rate_mean': [0, 90, 250],
        'mbp_mean': [0, 85, 200],
        'temperature_mean': [32, 36.5, 45],
        'spo2_mean': [0, 95, 100]
}

for lab in lab_ranges.keys():
    df6[lab] = np.where(df6[lab] < lab_ranges[lab][0], 0, df6[lab])
    df6[lab] = np.where(df6[lab] > lab_ranges[lab][2], 0, df6[lab])
    df6[lab] = np.where(df6[lab] == 0, lab_ranges[lab][1], df6[lab])
    df6[lab] = df6[lab].fillna(lab_ranges[lab][1])

df6['hemoglobin_min'] = df6['hemoglobin_min'].apply(lambda x: 0 if x < 3 else x)
df6['hemoglobin_min'] = df6['hemoglobin_min'].apply(lambda x: 0 if x > 30 else x)
df6['hemoglobin_min'] = df6['hemoglobin_min'].fillna(0)
df6['hemoglobin_min'] = df6.apply(lambda row: 12 if (row.hemoglobin_min == 0) \
                                                        & (row.sex_female == 1) \
                                                    else row.hemoglobin_min, axis=1)

df6['hemoglobin_min'] = df6.apply(lambda row: 13.5 if (row.hemoglobin_min == 0) \
                                                        & (row.sex_female == 0) \
                                                        else row.hemoglobin_min, axis=1)

df6['fluids_volume_norm_by_los_icu'] = df6['fluids_volume_norm_by_los_icu'].fillna(df6['fluids_volume_norm_by_los_icu'].mean())

print(f"df6 length after confounder imputation {len(df6)}")

df6.to_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_MIMIC_lac1.csv'))

df7 = df6[~df6.lactate_day2.isnull()]
print(f"Removed {len(df6) - len(df7)} stays without lactate day 2")
print("Final cohort size lac_1:", len(df6))
print("Final cohort size lac_2:", len(df7))
demo7 = print_demo(get_demography(df7))
print(f"{len(df7)} stays with sepsis and lactate day 1 & 2 \n({demo7})\n")
df7.to_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_MIMIC_lac1_lac2.csv'))