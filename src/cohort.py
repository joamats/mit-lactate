import pandas as pd
import numpy as np
import os
from utils import get_demography, print_demo

# get project directory path (1 level up)
PROJ_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
print(f"Project path: {PROJ_PATH}")

# MIMIC
df0 = pd.read_csv(os.path.join(PROJ_PATH, 'data', 'MIMIC_data.csv'))
print(f"\n{len(df0)} stays in the ICU")
df1 = df0[df0.sepsis3 == 1]
print(f"Removed {len(df0) - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

df2 = df1[~df1.lactate_day1.isnull()]
print(f"Removed {len(df1) - len(df2)} stays without lactate day 1")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} stays with sepsis and lactate day 1 \n({demo2})\n")


df3 = df2.sort_values(by=["subject_id", "hadm_id", "hospstay_seq", "icustay_seq"],
                      ascending=True).groupby('subject_id').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df2) - len(df3)} recurrent stays")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} adults with sepsis, lactate day 1 & 2, LoS > 1 day, adult patient, 1 stay per patient \n({demo3})\n")

df4 = df3[df3.los_icu >= 1]
print(f"Removed {len(df3) - len(df4)} stays with less than 1 day in ICU")
demo4 = print_demo(get_demography(df4))
print(f"{len(df3)} stays with sepsis, lactate day 1, and LoS > 1 day \n({demo4})\n")

outdir = os.path.join(PROJ_PATH, 'data', 'cohorts')
os.makedirs(outdir, exist_ok=True)
df4.to_csv(os.path.join(outdir, 'MIMIC_lac1.csv'), index=False)
