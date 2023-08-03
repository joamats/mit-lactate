import pandas as pd
import numpy as np
import os
from argparse import ArgumentParser
from scipy import stats
from pathlib import Path

# Read the different axes from txt
with open("config/axis.txt", "r") as f:
    axes = f.read().splitlines()
axes.remove("axis")


def get_binned_data(df, axis):
    """
    split the data into bins by lactate, 
    bins: All, 0-2, 2-4, 4-6, >6
    bins are subdivided by race
    """
    # switch this to lactate_day2 if you want to use that instead
    lacs = df.lactate_day1

    #Mapping the race groups as white and non-white
    #races = ["White", "Non-white"]
    df['race_group']=df['race_group'].map({'White':'White', 'Black': 'Non-white', 'Asian': 'Non-white', 'Hispanic':'Non-white'})
    df['sex_female']=df['sex_female'].map({1:'Female', 0:'Male'})
    df['eng_prof']=df['eng_prof'].map({1:'Proficient in English', 0:'Not proficient in English'})
  
    bins = [0, 2, 4, 6]
    dfs = {}
    axis_values=df[axis].unique()
    
    for a in axis_values:
        dfs[f"All\n{a}"] = df[df[axis] == a]
        for i in range(len(bins)-1):
            dfs[f"{bins[i]}-{bins[i+1]}\n{a}"] = df[df[axis]
                                                      == a][(lacs >= bins[i]) & (lacs < bins[i+1])]
        dfs[f">6\n{a}"] = df[df[axis] == a][lacs >= bins[-1]]
        
    # sort the dictionary by key
    dfs = {k: dfs[k] for k in sorted(dfs.keys())}
    return dfs


def get_table2(dfs):
    # Create a table with the following columns:
    # the column names will be the bins of lactate_day1

    cols = ["N", "mortality_in", "mortality_90", "los_icu", "los_hospital", "mv_24hr", "vp_24hr", "rrt_72hr"]
    table = pd.DataFrame(columns=cols, index=dfs.keys())
    for key in dfs.keys():
        # add the number of patients in each bin
        table.loc[key]["N"] = len(dfs[key])
        # For table 1, just report the mean and standard deviation of each column
        for col in cols[1:]:
            mean = dfs[key][col].mean()
            # std = dfs[key][col].std()
            # 95% confidence interval
            std = stats.t.interval(0.95, df=len(dfs[key][col])-1,
                                   loc=dfs[key][col].mean(),
                                   scale=dfs[key][col].sem())
            if col == "los_icu_hours":
                # round the mean and standard deviation
                table.loc[key][col] = f"{round(mean/24, 1)} ({round(std[0]/24, 1)}-{round(std[1]/24, 1)})"
            else:
                # round the mean and standard deviation to 2 decimal places
                table.loc[key][col] = f"{round(mean, 2)} ({round(std[0], 2)}-{round(std[1], 2)})"
        # UNCOMMENT THIS SECTION TO USE THE MEDIAN AND INTERQUARTILE RANGE INSTEAD OF THE MEAN AND STANDARD DEVIATION
        # # for each column, either report the mean and standard deviation, or the median and interquartile range, based on the distribution of the data
        # # if the data is normally distributed, use the mean and standard deviation
        # # check if the data is normally distributed by using the Shapiro-Wilk test
        # # if the p-value is less than 0.05, the data is not normally distributed
        # for col in cols:
        #     if stats.shapiro(dfs[key][col])[1] < 0.05:
        #         # if the data is not normally distributed, use the median and interquartile range
        #         table.loc[key][col] = f"{dfs[key][col].median()} ({dfs[key][col].quantile(0.25)}-{dfs[key][col].quantile(0.75)})"
        #     else:
        #         # if the data is normally distributed, use the mean and standard deviation
        #         table.loc[key][col] = f"{dfs[key][col].mean()} ({dfs[key][col].std()})"
    return table


def main(args, axis):
    # read in the data
    df = pd.read_csv(args.input)
    # get the binned data (binned by lactate and race)
    #setting="table2_MIMIC_"+str(axis)
    dfs = get_binned_data(df, axis)
    # create the table
    table = get_table2(dfs)
    # save transposed the table
    table.T.to_csv(args.output)


if __name__ == "__main__":
    # parse the arguments
    for axis in axes:
        parser = ArgumentParser()
        parser.add_argument(
        "-i", "--input", default=Path('data\cohorts\cohort_MIMIC_lactate_1.csv').absolute(), help="input csv file")
    
        setting=str(axis)
        parser.add_argument(
        "-o", "--output", default=Path(f"results/table2/table2_MIMIC_{setting}.csv").absolute(), help="output csv file")
    
        args = parser.parse_args()
        main(args, axis)
