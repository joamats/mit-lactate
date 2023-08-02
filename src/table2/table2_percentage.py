def get_table2(dfs):
    cols = ["N", "mortality_in", "mortality_90", "los_icu", "los_hospital", "mech_vent_overall", "rrt_overall",
            "vasopressor_overall", "transfusion_overall", "MV_init_offset_abs"]
    table = pd.DataFrame(columns=cols, index=dfs.keys())
    for key in dfs.keys():
        table.loc[key]["N"] = len(dfs[key])
        for col in cols[1:]:
            mean = dfs[key][col].mean()
            std = stats.t.interval(0.95, df=len(dfs[key][col])-1,
                                   loc=dfs[key][col].mean(),
                                   scale=dfs[key][col].sem())
            # Convert mean and std to percentages
            mean_percent = mean * 100
            std_lower_percent = std[0] * 100
            std_upper_percent = std[1] * 100
            if col == "los_icu_hours":
                table.loc[key][col] = f"{round(mean_percent/24, 1)}% ({round(std_lower_percent/24, 1)}% - {round(std_upper_percent/24, 1)}%)"
            else:
                table.loc[key][col] = f"{round(mean_percent, 2)}% ({round(std_lower_percent, 2)}% - {round(std_upper_percent, 2)}%)"
    return table
