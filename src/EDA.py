import pandas as pd
import numpy as np
import os
from matplotlib import pyplot as plt
from collections import OrderedDict
import plotly.express as px
from matplotlib.patches import Rectangle

# get parent directory of this file
script_dir = os.path.dirname(__file__)

# get root directory of this project (one level up from this file)
root_dir = os.path.abspath(os.path.join(script_dir, os.pardir))

# MIMIC
df = pd.read_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_MIMIC_no_lactate.csv'))
#df['fluids_normalized']=df['fluids_volume']/df['los_icu']
columns=['admission_age', 'SOFA', 'charlson_comorbidity_index', 'lactate_day1', 'lactate_freq_day1', 
         'lactate_day2', 'lactate_freq_day2', 'hemoglobin_min', 'los_icu', 'transfusion_overall', 
         'fluids_volume_norm_by_los_icu']

#Normality check

# Subplot has 4 rows and 3 columns
r=4
c=3
figure1, axes1 = plt.subplots(nrows=r, ncols=c, figsize=(20, 20))

# Creating histogram matrix
for i in range(0, r):
    #if i!=0:
    index=c*i
    columns_copy=columns[index:]
    for col, j in zip(columns_copy, range(0,c)):   
        axes1[i, j].hist(df[col])
        axes1[i, j].set_xlabel(col)

# Plotting and saving the histogram matrix
figure1.suptitle('Histograms to check the distribution of columns', fontsize=16)
#figure1.show()
#figure1.savefig(os.path.join(root_dir, 'results/EDA', 'normality_check.png'))

figure1_1= px.box(df, y=df['fluids_volume_norm_by_los_icu'])
#figure1_1.show()
figure1_1.write_html(os.path.join(root_dir, 'results/EDA', 'boxplot_fluids.html'))

# Checking for null values in lactate measurement frequency
#print(df['lactate_freq_day1'].isna().sum())
#print(df['lactate_freq_day2'].isna().sum())

# Filling the null values
df['lactate_freq_day1'].fillna(0)
df['lactate_freq_day2'].fillna(0)
#df = df[~df.lactate_day1.isnull()]
#df = df[~df.lactate_day2.isnull()]
#print(len(df))

# Normalizing the lactate measurement frequency
#df['lactate_freq_LOS']=(df['lactate_freq_day1']+df['lactate_freq_day2'])/df['los_icu']

# Plot histogram for lactate_freq_LOS
figure2, axes2 = plt.subplots(figsize=(12, 10))
axes2.hist(df['lactate_freq_LOS'])
axes2.set_xlabel('Lactate measurement frquency/Length of stay')
figure2.suptitle('Histogram of lactate measurement frequency normalized by LoS', fontsize=16)
#figure2.show()
#figure2.savefig(os.path.join(root_dir, 'results/EDA', 'lactate_freq_LOS.png'))


# Bar plots of mean lactate of day1 according to lactate bin and stratified by white vs non-white

# MIMIC dataset lactate 1 values
df2 = pd.read_csv(os.path.join(root_dir, 'data/cohorts', 'cohort_MIMIC_lactate_1.csv'))
df2['race_group']=df2['race_group'].map({'White':'White', 'Black': 'Non-white', 'Asian': 'Non-white', 'Hispanic':'Non-white'})

# Subplot has 2 rows and 2 columns
r=2
c=2
figure3, axes3 = plt.subplots(nrows=r, ncols=c, figsize=(12, 10))

bin_names = ['0-2', '2-4', '4-6', '>6']

# Creating bar plot matrix
for i in range(0, r):
    index=0
    bin_names_1=bin_names[index:]
    if i!=0:
        index=c*i
        bin_names_1=bin_names[index:]
    for col, j in zip(bin_names_1, range(0,c)):   
        data=df2[df2['lactate_range']==col]
        axes3[i, j].bar(data['race_group'].unique(), data.groupby('race_group')['lactate_day1'].mean())
        axes3[i, j].set_xlabel(col)

figure3.suptitle('Bar plots of mean lactate of day 1 for each lactate bin stratified by race', fontsize=16)
#figure3.show()
#figure3.savefig(os.path.join(root_dir, 'results/EDA', 'mean_lactate_by_race.png'))


# Creating histogram matrix
figure4, axes4 = plt.subplots(nrows=r, ncols=c, figsize=(12, 10))

for i in range(0, r):
    if i!=0:
        index=c*i
        bin_names=bin_names[index:]
    for col, j in zip(bin_names, range(0,c)):   
        data=df2[df2['lactate_range']==col]
        lac_white=data[data['race_group']=='White'].lactate_day1
        lac_nonwhite=data[data['race_group']=='Non-white'].lactate_day1

        cmap = plt.get_cmap('viridis')

        axes4[i, j].hist(lac_white, label='White', alpha=0.5, color='red', density=True)
        CI_lower_white = round(np.percentile(lac_white, 2.5), 2)
        CI_upper_white = round(np.percentile(lac_white, 97.5), 2)
        l_lower_white = axes4[i, j].axvline(CI_lower_white, color=cmap(0.25))
        l_upper_white = axes4[i, j].axvline(CI_upper_white, color=cmap(0.5))

        axes4[i, j].hist(lac_nonwhite, label='Non-white', alpha=0.5, color='yellow', density=True)
        CI_lower_nw = round(np.percentile(lac_nonwhite, 2.5), 2)
        CI_upper_nw = round(np.percentile(lac_nonwhite, 97.5), 2)
        l_lower_nw = axes4[i, j].axvline(CI_lower_nw, color=cmap(0.75))
        l_upper_nw = axes4[i, j].axvline(CI_upper_nw, color=cmap(1))

        #create legend for confidence intervals
        handles = [Rectangle((0,0),1,1,color=c) for c in [cmap(0.25), cmap(0.5), cmap(0.75), 
                                                          cmap(1)]]
        labels= ["CI_lower_white={}".format(CI_lower_white), "CI_upper_white={}".format(CI_upper_white), 
         "CI_lower_nw={}".format(CI_lower_nw), "CI_upper_nw={}".format(CI_upper_nw)]
        axes4[i, j].legend(handles, labels)
        
        axes4[i, j].set_xlabel(col)


handles, labels = figure4.gca().get_legend_handles_labels()
by_label = OrderedDict(zip(labels, handles))
figure4.legend(by_label.values(), by_label.keys())
figure4.suptitle('Histogram of lactate day 1 values for each lactate bin stratified by race \n(Showing the 95% confidence intervals)', fontsize=16)
#figure4.show()
#figure4.savefig(os.path.join(root_dir, 'results/EDA', 'lactate_day1_by_race.png'))