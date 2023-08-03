import pandas as pd
import numpy as np
import os
from ..utils import get_demography, print_demo

# get parent directory of this file
script_dir = os.path.dirname(__file__)
# get root directory of this project (two levels up from this file)
root_dir = os.path.abspath(os.path.join(script_dir, os.pardir, os.pardir))

# eICU
df1 = pd.read_csv(os.path.join(root_dir, 'data', 'eICU_data.csv'))
print(f"\n200859 stays in the ICU")
print(f"Removed {200859 - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

df2 = df1[~df1.lactate_day1.isnull()]
print(f"Removed {len(df1) - len(df2)} stays without lactate day 1")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} stays with sepsis and lactate day 1 \n({demo2})\n")

df3 = df2[df2.race_group!= 'Other']
print(f"Removed {len(df2) - len(df3)} patients belonging to other race groups")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} patients with sepsis and lactate day 1 and not in the other race groups \n({demo3})\n")

df4 = df3[df3.los_icu_hours >= 24]
print(f"Removed {len(df3) - len(df4)} stays with less than 24 hours")
demo4 = print_demo(get_demography(df4))
print(f"{len(df4)} stays with sepsis, lactate day 1 & 2, and LoS > 24h \n({demo4})\n")

df5 = df4[df4.age >= 18]
print(f"Removed {len(df4) - len(df5)} stays with non-adult patient")
demo5 = print_demo(get_demography(df5))
print(f"{len(df5)} stays with sepsis, lactate day 1 & 2, LoS > 24h, adult patient \n({demo5})\n")

df6 = df5.sort_values(by=["patient_id", "stay_number"], ascending=True).groupby(
    'patient_id').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df5) - len(df6)} recurrent stays")
demo6 = print_demo(get_demography(df6))
<<<<<<< Updated upstream
print(f"{len(df6)} stays with sepsis and lactate day 1 & 2 \n({demo6})\n")
df6.to_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_eICU_lac1_lac2.csv'))
=======
print(f"{len(df6)} adults with sepsis, lactate day 1 & 2, LoS > 24h, adult patient, 1 stay per patient \n({demo6})\n")

if os.path.exists('data/cohorts')==False:
    os.makedirs('data/cohorts')

df6.to_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_eICU_lac1.csv'))

df7 = df6[~df6.lactate_day2.isnull()]
print(f"Removed {len(df6) - len(df7)} stays without lactate day 2")
demo7 = print_demo(get_demography(df7))
print(f"{len(df7)} stays with sepsis and lactate day 1 & 2 \n({demo7})\n")
df7.to_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_eICU_lac1_lac2.csv'))



>>>>>>> Stashed changes
