import os

import numpy as np
import pandas as pd
from utils import get_demography, print_demo

# get parent directory of this file
script_dir = os.path.dirname(__file__)

# get root directory of this project (two levels up from this file)
root_dir = os.path.abspath(os.path.join(script_dir, os.pardir, os.pardir))

# Reading the MIMIC data
df0 = pd.read_csv(os.path.join(root_dir, "data", "MIMIC_data.csv"))
demo0 = print_demo(get_demography(df0))
print(f"\n({demo0})\n")

# Removing non-septic patients
print(len(df0), "Initial rows in extracted MIMIC\n")
df1 = df0[df0.sepsis3 == 1]
print(f"Removed {len(df0) - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

# Data preprocessing

# Treatments for 24/72h
df1["mv_24hr"] = np.where(
    (df1["mech_vent_overall"] == 1) & (df1["MV_init_offset_abs"] <= 1), 1, 0
)
df1["vp_24hr"] = np.where(
    (df1["vasopressor_overall"] == 1) & (df1["VP_init_offset_abs"] <= 1), 1, 0
)
df1["rrt_72hr"] = np.where(
    (df1["rrt_overall"] == 1) & (df1["RRT_init_offset_abs"] <= 3), 1, 0
)

# Encoding lactate measurements for overall stay and day 1
df1["lactate_overall_yes_no"] = np.where(
    (df1["lactate_freq_day1"].notnull()) & (df1["lactate_freq_day2"].notnull()), 1, 0
)
df1["lactate_day1_yes_no"] = np.where((df1["lactate_freq_day1"].notnull()), 1, 0)

# Lactate frequency normalized by los
df1["lactate_freq_LOS"] = (df1["lactate_freq_day1"] + df1["lactate_freq_day2"]) / df1[
    "los_icu"
]

# Replacing ? in language columns as No English
df1["language"].replace("?", "No English", inplace=True)

# Removing Other race groups
df2 = df1[df1.race_group != "Other"]
print(f"Removed {len(df1) - len(df2)} stays without specified race group")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} sepsis stays with specified race group \n({demo2})\n")

# Removing patients who spent less that 24 hours in ICU
df3 = df2[df2.los_icu >= 1]
print(f"Removed {len(df2) - len(df3)} stays with less than 24 hours")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} stays with sepsis, lactate day 1, and LoS > 24h \n({demo3})\n")

# Removing non-adult petients
df4 = df3[df3.admission_age >= 18]
print(f"Removed {len(df3) - len(df4)} stays with non-adult patient")
demo4 = print_demo(get_demography(df4))
print(
    f"{len(df4)} stays with sepsis, lactate day 1, LoS > 24h, adult patient \n({demo4})\n"
)

# Removing patients with recurrent stays
df5 = (
    df4.sort_values(by=["subject_id", "stay_id"], ascending=True)
    .groupby("subject_id")
    .apply(lambda group: group.iloc[0, 1:])
)
print(f"Removed {len(df4) - len(df5)} recurrent stays")
demo5 = print_demo(get_demography(df5))
print(
    f"{len(df5)} adults with sepsis, lactate day 1, LoS > 24h, adult patient, 1 stay per patient \n({demo5})\n"
)

# Data imputation

cols_na = [
    "major_surgery",
    "hypertension_present",
    "heart_failure_present",
    "copd_present",
    "asthma_present",
    "cad_present",
    "ckd_stages",
    "connective_disease",
    "pneumonia",
    "uti",
    "biliary",
    "skin",
    "respiration",
    "coagulation",
    "cardiovascular",
    "cns",
    "liver",
]

for c in cols_na:
    df5[c] = df5[c].fillna(0)

lab_ranges = {
    "po2_min": [0, 90, 1000],
    "pco2_max": [0, 40, 200],
    "ph_min": [5, 7.35, 10],
    "lactate_max": [0, 1.05, 30],
    "glucose_max": [0, 95, 2000],
    "sodium_min": [0, 140, 160],
    "potassium_max": [0, 3.5, 9.9],
    "cortisol_min": [0, 20, 70],
    "fibrinogen_min": [0, 200, 1000],
    "inr_max": [0, 1.1, 10],
    "resp_rate_mean": [0, 15, 50],
    "heart_rate_mean": [0, 90, 250],
    "mbp_mean": [0, 85, 200],
    "temperature_mean": [32, 36.5, 45],
    "spo2_mean": [0, 95, 100],
}

for lab in lab_ranges.keys():
    df5[lab] = np.where(df5[lab] < lab_ranges[lab][0], 0, df5[lab])
    df5[lab] = np.where(df5[lab] > lab_ranges[lab][2], 0, df5[lab])
    df5[lab] = np.where(df5[lab] == 0, lab_ranges[lab][1], df5[lab])
    df5[lab] = df5[lab].fillna(lab_ranges[lab][1])

df5["hemoglobin_min"] = df5["hemoglobin_min"].apply(lambda x: 0 if x < 3 else x)
df5["hemoglobin_min"] = df5["hemoglobin_min"].apply(lambda x: 0 if x > 30 else x)
df5["hemoglobin_min"] = df5["hemoglobin_min"].fillna(0)
df5["hemoglobin_min"] = df5.apply(
    lambda row: 12
    if (row.hemoglobin_min == 0) & (row.sex_female == 1)
    else row.hemoglobin_min,
    axis=1,
)

df5["hemoglobin_min"] = df5.apply(
    lambda row: 13.5
    if (row.hemoglobin_min == 0) & (row.sex_female == 0)
    else row.hemoglobin_min,
    axis=1,
)

df5["fluids_volume_norm_by_los_icu"].fillna(
    df5["fluids_volume_norm_by_los_icu"].mean(), inplace=True
)

df5["renal"].fillna(0, inplace=True)

df5["lactate_freq_LOS"].fillna(
    0, inplace=True
)  # drop null values instead of filling with 0s?

print(f"df5 length after confounder imputation {len(df5)}")

# Saving cohort for all records after exclusion criteria is applied
df5.to_csv(os.path.join(root_dir, "data/cohorts", "cohort_MIMIC_entire_los1.csv"))

# Removing patients without a lactate day 1 value
df6 = df5[~df5.lactate_day1.isnull()]
print(f"Removed {len(df5) - len(df6)} stays without lactate day 1")
demo6 = print_demo(get_demography(df3))
print(f"{len(df6)} stays with sepsis and lactate day 1 \n({demo6})\n")

# Saving cohort for all records after removing missing lactate day 1 values
df6.to_csv(os.path.join(root_dir, "data/cohorts", "cohort_MIMIC_lac11.csv"))
