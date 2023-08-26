import pandas as pd
import numpy as np
from tqdm import tqdm
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold

# Read confounder from txt
with open("config/some_confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Read the different axes from txt
with open("config/axis.txt", "r") as f:
    axes = f.read().splitlines()
axes.remove("axis")

# Input data and data preprocessing
data = pd.read_csv("data/cohorts/cohort_MIMIC_entire_los.csv")

# Create dataframe to store results
results_df = pd.DataFrame(columns=["Axis", "Demographic","OR","2.5%","97.5%", "N"])

setting = "logreg_lactate_measurement_non_penalized"

# Iterating through the three axes values
for a in axes:
    # Creating a list to store the unique values for each axis
    axis_values=data[a].unique().tolist()

    # Setting the reference value for each axis and removing that axis from the confounders list
    if a=='race_group':
        reference='White'
        axis_values.remove(reference)
        conf_copy=confounders.copy()
        conf_copy.remove('race_group')

    elif a=='gender':
        reference='M'
        axis_values.remove(reference)
        conf_copy=confounders.copy()
        conf_copy.remove('sex_female')

    else:
        reference='ENGLISH'
        axis_values.remove(reference)
        conf_copy=confounders.copy()
        conf_copy.remove('eng_prof')
    

    # Encoding columns
    for col in axis_values:
        data[col]=np.where(data[a] == col, 1, np.where(data[a] == reference, 0, np.nan))    

    # Append results to dataframe
    results_df = pd.concat([results_df, pd.DataFrame({"Axis": a,
                                                      "Demographic": reference,
                                                      "OR": 1,
                                                      "2.5%": 1,
                                                      "97.5%": 1,
                                                      "N": len(data[data[a]==reference])}, index=[0])], 
                                                      ignore_index=True)

    for val in axis_values:
        print(f"Axis: {a}")
        print(f"Demographic: {val}")
        conf = conf_copy + [val] 

        # Subset the data to get not nan values 
        subset_data = data.dropna(subset=val)
        print(f"Patients dropped: {len(data) - len(subset_data)}")

        # Compute OR based on all data
        X = subset_data[conf]

        # One-hot encoding all categorical columns
        col='anchor_year_group'
        X = pd.concat([X.drop(col, axis=1), pd.get_dummies(X[col], dtype=int)], axis=1)

        # Dropping the race_group column for the sex and english proficiency axis modelling
        col='race_group'
        if col in X.columns:
            X.drop(col, axis=1, inplace=True)

        #print(X.columns)
            
        y = subset_data['lactate_day1_yes_no']

        # To ensure that the train and test sets are split based on the number of samples for each value in 
        # the current axis
        r = subset_data[val]

        n_rep = 20
        odds_ratios = []

        # Outer loop
        for i in tqdm(range(n_rep)):
          # List to append inner ORs
          ORs = []

          # Normal k-fold cross validation
          kf = StratifiedKFold(n_splits=5, shuffle=True, random_state=i)
            
          # Inner loop, in each fold
          for train_index, test_index in tqdm(kf.split(X, r)):
            X_train, X_test = X.iloc[train_index,:], X.iloc[test_index,:]
            y_train, y_test = y.iloc[train_index], y.iloc[test_index]

            # Fit logistic regression model
            model = LogisticRegression(max_iter=10000, penalty=None)
            model.fit(X_test, y_test)

            idx = X_test.columns.get_loc(val)
            param = model.coef_[0][idx]
            OR_inner = np.exp(param)

            # Append OR to list
            ORs.append(OR_inner)

            print(f"OR: {OR_inner:.5f}")

          # Calculate odds ratio based on all 5 folds, append
          odds_ratios.append(np.mean(ORs))

        # Calculate confidence intervals
        CI_lower = np.percentile(odds_ratios, 2.5)
        OR = np.percentile(odds_ratios, 50)
        CI_upper = np.percentile(odds_ratios, 97.5)

        print(f"OR (95% CI): {OR:.3f} ({CI_lower:.3f} - {CI_upper:.3f})")

        # Append results to dataframe
        results_df = pd.concat([results_df, pd.DataFrame({"Axis": [a],
                                                          "Demographic": [val],
                                                          "OR": [OR],
                                                          "2.5%": [CI_lower],
                                                          "97.5%": [CI_upper],
                                                          "N": [len(data[data[val]==1])]})], 
                                                          ignore_index=True)
# Save results 
results_df.to_csv(f"results/models/{setting}.csv", index=False)