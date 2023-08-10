import pandas as pd
import numpy as np
from tqdm import tqdm
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold
from pathlib import Path
from sklearn import preprocessing
import os
import sys

setting = "measurements_logreg_MIMIC"

# Read treatments from txt
with open("/Users/fredrikwhaug/fredrik/research/summer-23/lactate/mit-lactate/config/treatments.txt", "r") as f:
    treatments = f.read().splitlines()
treatments.remove("treatment")

# Read confounders from list in txt
with open("/Users/fredrikwhaug/fredrik/research/summer-23/lactate/mit-lactate/config/confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Read the cohorts
with open("/Users/fredrikwhaug/fredrik/research/summer-23/lactate/mit-lactate/config/cohorts.txt", "r") as f:
    cohorts = f.read().splitlines()
cohorts.remove("cohorts")

# Get race_groups:
with open("/Users/fredrikwhaug/fredrik/research/summer-23/lactate/mit-lactate/config/race_groups.txt", "r") as f:
    races = f.read().splitlines()
races.remove("race_groups")

# create dataframes to store results
results_df = pd.DataFrame(columns=["Cohort", "Race","Treatment", "lactate","OR","2.5%","97.5%", "N"])

# loading the actual data
data = pd.read_csv("/Users/fredrikwhaug/fredrik/research/summer-23/lactate/mit-lactate/data/cohorts/cohort_MIMIC_lac1_entire_los.csv")

#One-hot encoding all categorical columns
categorical_col= ['race_group', 'anchor_year_group']
for col in categorical_col:
    data = pd.concat([data.drop(col, axis=1), pd.get_dummies(data[col], dtype=int)], axis=1)

cohort='MIMIC'

for race in races:
    print(f"Race: {race}")

    # load data
    subset_data=data[(data[race]==1)]

    conf = confounders + treatments
    # include the number of measurements as a confounder by Leo
    # include sex and EP (or do seperately? probably not) by Tristan

    # compute OR based on all data
    X = subset_data[conf]
    y = subset_data["lactate_overall_yes_no"]

    n_rep = 20
   
   # Creating a list of empty lists to append the mean OR value of the k-fold cross-validation for each iteration across all races
    new_lists = []
    for p in range(len(races)):
        new_lists.append([])

    # This dictionary will hold the mean OR value as a result of k-fold cross validation for every iteration per race group
    lactate_ORs = {k:v for k,v in zip(races, new_lists)}

    # outer loop
    for i in tqdm(range(n_rep)):

        # Creating a list of empty lists to append OR values for k-fold cross-validation across all race groups
        lists = []
        for p in range(len(races)):
            lists.append([])
        
        # This dictionary will hold all the OR values as a result of k-fold cross validation per race group
        list_dict = {k:v for k,v in zip(races, lists)}


        # normal k-fold cross validation
        kf = StratifiedKFold(n_splits=5, shuffle=True, random_state=i)
            

        # inner loop, in each fold
        for train_index, test_index in tqdm(kf.split(X, y)):
            X_train, X_test = X.iloc[train_index,:], X.iloc[test_index,:]
            y_train, y_test = y.iloc[train_index], y.iloc[test_index]
                
            # Fit logistic regression model
            model = LogisticRegression(max_iter=10000)
            model.fit(X_test, y_test)

            # Iterating through the lactate bin names and the empty lists to add OR values for k-fold cross validation
            for (lactate, OR) in zip(races, list(list_dict.values())):
                idx = X_test.columns.get_loc(lactate)
                param = model.coef_[0][idx]
                OR_inner = np.exp(param)
                # # append OR to list
                OR.append(OR_inner)

        # calculate odds ratio based on all 5 folds, append
        for OR, odds_ratios in zip(list(list_dict.values()), lactate_ORs.values()):
            odds_ratios.append(np.mean(OR))
    

    # calculate confidence intervals for odds ratios over all the iterations

    for odds_ratios in lactate_ORs.values():
        CI_lower = round(np.percentile(odds_ratios, 2.5), 2)
        OR = round(np.percentile(odds_ratios, 50), 2)
        CI_upper = round(np.percentile(odds_ratios, 97.5), 2)

        print(f"OR (95% CI): {OR:.3f} ({CI_lower:.3f} - {CI_upper:.3f})") 

        # Appending the confidence intervals and OR values to the dataframe
        position=list(lactate_ORs.values()).index(odds_ratios)  
        lactate_bin=list(lactate_ORs.keys())[position]    
        N=len(subset_data[subset_data[lactate_bin]==1])
        results_df.loc[len(results_df.index)] = [cohort, race, "IMV", lactate_bin, OR, CI_lower, CI_upper, N] 

    # Create a folder if doesn not exist already
    if os.path.exists('results/models')==False:
        os.makedirs('results/models') 

    # save results as we go
    results_df.to_csv(f"/Users/fredrikwhaug/fredrik/research/summer-23/lactate/mit-lactate/src/log-reg/log-reg-measurement/results/models/{setting}.csv", index=False)
