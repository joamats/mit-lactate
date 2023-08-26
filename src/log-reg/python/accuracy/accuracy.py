import pandas as pd
import numpy as np
from tqdm import tqdm
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score 

# Read confounder from txt
with open("/Users/fredrikwhaug/research/mit/projects/lactate/mit-lactate/config/confounders_fred.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Read the different axes from txt
with open("/Users/fredrikwhaug/research/mit/projects/lactate/mit-lactate/config/axis.txt", "r") as f:
    axes = f.read().splitlines()
axes.remove("axis")

# Input data and data preprocessing
data = pd.read_csv("/Users/fredrikwhaug/research/mit/projects/lactate/mit-lactate/src/data/cohorts/MIMIC_cohort_lab_values.csv")

# Create dataframe to store results
results_df = pd.DataFrame(columns=["Axis", "Demographic", "AUC"])

setting = "logreg_lactate_performance"

# Iterating through the three axes values
for a in axes:
    # Creating a list to store the unique values for each axis
    axis_values = data[a].unique().tolist()

    # Setting the reference value for each axis and removing that axis from the confounders list
    if a == 'race_group':
        reference = 'White'
        axis_values.remove(reference)
        conf_copy = confounders.copy()
        conf_copy.remove('race_group')
    elif a == 'gender':
        reference = 'M'
        axis_values.remove(reference)
        conf_copy = confounders.copy()
        conf_copy.remove('sex_female')
    else:
        reference = 'ENGLISH'
        axis_values.remove(reference)
        conf_copy = confounders.copy()
        conf_copy.remove('eng_prof')

    # Encoding columns
    for col in axis_values:
        data[col] = np.where(data[a] == col, 1, np.where(data[a] == reference, 0, np.nan))

    # Append results to dataframe
    results_df = pd.concat([results_df, pd.DataFrame({"Axis": [a],
                                                      "Demographic": [reference],
                                                      "AUC": [1]})],
                                                      ignore_index=True)

    for val in axis_values:
        print(f"Axis: {a}")
        print(f"Demographic: {val}")
        conf = conf_copy + [val]

        # Subset the data to get not nan values
        subset_data = data.dropna(subset=[val])  # why are we doing this?
        print(f"Patients dropped: {len(data) - len(subset_data)}")

        # Compute OR based on all data
        X = subset_data[conf]

        # Dropping the race_group column for the sex and english proficiency axis modeling
        col = 'race_group'
        if col in X.columns:
            X.drop(col, axis=1, inplace=True)  

        y = subset_data['lactate_day1_yes_no']  

        r = subset_data[val]  # can you please explain this?

        auc_inner = []

        # Fit logistic regression model
        model = LogisticRegression(max_iter=10000)
        model.fit(X, y)

        # AUC
        y_pred_proba = model.predict_proba(X)[:, 1]
        auc = roc_auc_score(y, y_pred_proba)
        print(auc)

        auc_inner.append(auc)

        auc_mean = np.mean(auc_inner)

        # Append results to dataframe
        results_df = pd.concat([results_df, pd.DataFrame({"Axis": [a],
                                                          "Demographic": [val],
                                                          "AUC": [auc_mean]})],
                                                          ignore_index=True)
# Save results
results_df.to_csv(f"/Users/fredrikwhaug/research/mit/projects/lactate/mit-lactate/results/log-reg-results/accuracy/{setting}.csv", index=False)
