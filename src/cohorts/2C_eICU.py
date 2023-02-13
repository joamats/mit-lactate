import pandas as pd
import numpy as np

# eICU
df1 = pd.read_csv("data/eICU_data3.csv")
print(f"\n200859 stays in the ICU")
print(f"Removed {200859 - len(df1)} stays without sepsis")
print(f"{len(df1)} sepsis stays")

df2 = df1[~df1.lactate_day1.isnull()]
print(f"Removed {len(df1) - len(df2)} stays without lactate day 1")
print(f"{len(df2)} stays with sepsis and lactate day 1")

df3 = df2[~df2.lactate_day2.isnull()]
print(f"Removed {len(df2) - len(df3)} stays without lactate day 2")
print(f"{len(df3)} stays with sepsis and lactate day 1 & 2")

df4 = df3[df3.los_icu_hours >= 24]
print(f"Removed {len(df3) - len(df4)} stays with less than 24 hours")
print(f"{len(df4)} stays with sepsis, lactate day 1 & 2, and LoS > 24h")

df5 = df4[df4.age >= 18]
print(f"Removed {len(df4) - len(df5)} stays with non-adult patient")
print(f"{len(df5)} stays with sepsis, lactate day 1 & 2, LoS > 24h, adult patient")

df6 = df5.sort_values(by=["patient_id","stay_number"], ascending=True).groupby('patient_id').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df5) - len(df6)} recurrent stays")
print(f"{len(df6)} adults with sepsis, lactate day 1 & 2, LoS > 24h, adult patient, 1 stay per patient")

df6.to_csv('data/cohort_eICU3.csv')
