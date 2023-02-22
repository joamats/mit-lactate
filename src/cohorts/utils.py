import pandas as pd
import numpy as np


def get_demography(df):
    """Get the demography of the cohort.

    Args:
        df (pd.DataFrame): The cohort.
    """
    demo = {}
    demo["race"] = {race: df[df["race_group"] == race].shape[0] /
                         df.shape[0] for race in df["race_group"].unique() if race != "Other"}
    demo["sex"] = {
        "Male": df[df["sex_female"] == 0].shape[0] / df.shape[0],
        "Female": df[df["sex_female"] == 1].shape[0] / df.shape[0]}
    return demo


def print_demo(demo):
    demo_str = ""
    for key, value in demo.items():
        if isinstance(value, dict):
            demo_str += f"{key}: ["
            for key2, value2 in value.items():
                demo_str += f"{key2}: {round(value2*100,1)}%, "
            demo_str = demo_str[:-2] + "], "
        else:
            demo_str += f"{key}: {round(value*100,1)}%, "
    demo_str = demo_str[:-2]
    return demo_str
