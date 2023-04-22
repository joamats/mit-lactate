import pandas as pd
import numpy as np
import os
from argparse import ArgumentParser
from scipy import stats


def get_binned_data(df):
    """
    split the data into bins by lactate, 
    bins: All, 0-2, 2-4, 4-6, >6
    bins are subdivided by race
    """
    # switch this to lactate_day2 if you want to use that instead
    lacs = df.lactate_day1
    races = ["White", "Black"]
    bins = [0, 2, 4, 6]
    dfs = {}
    for race in races:
        dfs[f"All {race}"] = df[df["race_group"] == race]
        for i in range(len(bins)-1):
            dfs[f"{bins[i]}-{bins[i+1]} {race}"] = df[df["race_group"]
                                                      == race][(lacs >= bins[i]) & (lacs < bins[i+1])]
        dfs[f">6 {race}"] = df[df["race_group"] == race][lacs >= bins[-1]]
    # sort the dictionary by key
    dfs = {k: dfs[k] for k in sorted(dfs.keys())}
    return dfs


def get_table2(dfs):
    # Create a table with the following columns:
    # mortality_in, los_icu_hours, mech_vent_overall_yes, rrt_overall_yes, vasopressor_overall_yes, transfusion_overall_yes, fluids_overall_yes
    # the rows will be the bins of lactate_day1
    cols = ["mortality_in", "los_icu", "mech_vent_overall", "rrt_overall",
            "vasopressor_overall", "transfusion_overall", "fluids_volume_norm_by_los_icu"]
    table = pd.DataFrame(columns=cols, index=dfs.keys())
    for key in dfs.keys():
        # For table 1, just report the mean and standard deviation of each column
        for col in cols:
            mean = dfs[key][col].mean()
            std = dfs[key][col].std()
            if col == "los_icu_hours":
                # round the mean and standard deviation
                table.loc[key][col] = f"{round(mean/24, 1)} ({round(std/24, 1)})"
            else:
                # round the mean and standard deviation to 2 decimal places
                table.loc[key][col] = f"{round(mean, 2)} ({round(std, 2)})"

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


def main(args):
    # read in the data
    df = pd.read_csv(args.input)
    # get the binned data (binned by lactate and race)
    dfs = get_binned_data(df)
    # create the table
    table = get_table2(dfs)
    # save the table
    table.T.to_csv(args.output)


if __name__ == "__main__":
    # parse the arguments
    parser = ArgumentParser()
    parser.add_argument(
        "-i", "--input", default='../../data/cohorts/MIMIC_lac1.csv', help="input csv file")
    parser.add_argument(
        "-o", "--output", default='../../results/table2/table2_MIMIC_lac1.csv', help="output csv file")
    args = parser.parse_args()
    main(args)
