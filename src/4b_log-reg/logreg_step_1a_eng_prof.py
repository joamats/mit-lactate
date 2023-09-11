import pandas as pd
import numpy as np
from tqdm import tqdm
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold

# Read confounder from txt
with open("config/confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")


# Input data and data preprocessing
data = pd.read_csv("data/cohorts/cohort_MIMIC_entire_los.csv")


# Create dataframe to store results
results_df = pd.DataFrame(columns=["Demographic","OR","2.5%","97.5%", "N"])

setting = "logreg_eng"
    
# Append results to dataframe
results_df = pd.concat([results_df, pd.DataFrame({"Demographic": "English",
                                                      "OR": 1,
                                                      "2.5%": 1,
                                                      "97.5%": 1,
                                                      "N": len(data[data['eng_prof']==1])}, index=[0])], 
                                                      ignore_index=True)

#print(f"Demographic: {val}")
conf = confounders  #why are we doing this?

    # Compute OR based on all data
X = data[conf]

# One-hot encoding categorical confounders 
col=['race_group', 'anchor_year_group']
for c in col:
    X = pd.concat([X.drop(c, axis=1), pd.get_dummies(X[c], dtype=int)], axis=1)
           
y = data['lactate_overall_yes_no']

        # To ensure that the train and test sets are split based on the number of samples for each value in 
        # the current axis
r = data['eng_prof']

n_rep = 2
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
        model = LogisticRegression(max_iter=10000)
        model.fit(X_test, y_test)

        idx = X_test.columns.get_loc('eng_prof')
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
results_df = pd.concat([results_df, pd.DataFrame({"Demographic": "No English",
                                                          "OR": [OR],
                                                          "2.5%": [CI_lower],
                                                          "97.5%": [CI_upper],
                                                          "N": [len(data[data['eng_prof']==0])]})], 
                                                          ignore_index=True)
# Save results 
results_df.to_csv(f"results/models/{setting}.csv", index=False)