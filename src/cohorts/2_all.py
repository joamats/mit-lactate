import pandas as pd
import numpy as np

# MIMIC
df0 = pd.read_csv("data/MIMIC.csv")
print(f"{len(df0)} stays in the ICU")

df1 = df0[df0.sepsis3 == 1]
print(f"Removed {len(df0) - len(df1)} stays without sepsis")
print(f"{len(df1)} stays with sepsis")

df2 = df1.drop_duplicates(subset=['subject_id'], keep='first')
print(f"Removed {len(df1) - len(df2)} non-first (relative) stays")
print(f"{len(df2)} patients with sepsis, and on first stay")

df2.to_csv('data/cohort_MIMIC_all.csv')

# eICU
df0 = pd.read_csv("data/eICU.csv")
print(f"\n200859 stays in the ICU")
print(f"Removed {200859 - len(df0)} stays without sepsis")
print(f"{len(df0)} sepsis stays")

df1 = df0[df0.unitvisitnumber == 1]
print(f"Removed {len(df0) - len(df1)} non-first (relative) stays")
print(f"{len(df1)} patients with sepsis, and on first stay")

df1.to_csv('data/cohort_eICU_all.csv')
