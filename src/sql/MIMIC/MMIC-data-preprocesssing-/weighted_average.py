import pandas as pd

raw_data = pd.read_csv('stayid_charttime_vitals_ned_0-24hrs')
raw_data

raw_data.columns

"""# Weighted average"""

df=raw_data

import pandas as pd

def drop_duplicate_columns(df):
    duplicated_columns = df.columns[df.columns.duplicated()]
    return df.drop(columns=duplicated_columns)

df['charttime'] = pd.to_datetime(df['charttime'])
df = df.sort_values('charttime')
df['duration'] = df['charttime'].diff().dt.total_seconds()

time_weighted_averages = {}
for col in ['heart_rate', 'resp_rate', 'mbp', 'spo2', 'temp_degC', 'norepinephrine_equivalent_dose']:
    df['weighted_value'] = df[col] * df['duration']
    col_weighted_average = df.groupby('stay_id')[['weighted_value', 'duration']].sum()
    col_weighted_average['weighted_average'] = round(col_weighted_average['weighted_value'] / col_weighted_average['duration'], 2)
    col_weighted_average.loc[col_weighted_average['duration'] == 0, 'weighted_average'] = None
    time_weighted_averages[col] = col_weighted_average['weighted_average']

result_df = pd.DataFrame(time_weighted_averages)
result_df.reset_index(inplace=True)
result_df = df[['stay_id', 'charttime']].merge(result_df, on='stay_id')

# Add 'weighted_average' suffix to column names
result_df = result_df.add_suffix('_weighted_average')

# Drop duplicate columns
result_df = drop_duplicate_columns(result_df)

# Drop duplicates based on 'stay_id_weighted_average'
result_df.drop_duplicates(subset=['stay_id_weighted_average'], keep='first', inplace=True)

# Drop the column 'charttime_weighted_average'
result_df.drop('charttime_weighted_average', axis=1, inplace=True)
