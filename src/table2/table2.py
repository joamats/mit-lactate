import pandas as pd
import numpy as np
import os
from argparse import ArgumentParser


def get_binned_data(df):
    # split the data into bins by lactate
    # bins: All, 0-2, 2-4, 4-6, >6
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
    table = pd.DataFrame(columns=["mortality_in", "los_icu_hours", "mech_vent_overall_yes", "rrt_overall_yes",
                         "vasopressor_overall_yes", "transfusion_overall_yes", "fluids_overall_yes"], index=dfs.keys())
    for key in dfs.keys():
        table.loc[key] = [dfs[key].mortality_in.mean(), dfs[key].los_icu_hours.mean(), dfs[key].mech_vent_overall_yes.mean(), dfs[key].rrt_overall_yes.mean(
        ), dfs[key].vasopressor_overall_yes.mean(), dfs[key].transfusion_overall_yes.mean(), dfs[key].fluids_overall_yes.mean()]
    return table


def main(args):
    df = pd.read_csv(args.input)
    df.keys()
    dfs = get_binned_data(df)
    table = get_table2(dfs)
    # save the table
    table.to_csv(args.output)


if __name__ == "__main__":
    # parse the arguments
    parser = ArgumentParser()
    parser.add_argument(
        "-i", "--input", default='../../data/cohort_eICU_lac1.csv', help="input csv file")
    parser.add_argument(
        "-o", "--output", default='../../results/table2/table2_cohort_eICU.csv', help="output csv file")
    args = parser.parse_args()
    main(args)
