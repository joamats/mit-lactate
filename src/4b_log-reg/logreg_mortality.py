import pandas as pd
import numpy as np
from tqdm import tqdm
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold
from pathlib import Path
from sklearn import preprocessing
import os

setting = "logreg_MIMIC_lactatebins"

# Read treatments from txt
with open("config_new/treatments.txt", "r") as f:
    treatments = f.read().splitlines()
treatments.remove("treatment")

# Read confounders from list in txt
with open("config_new/confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Read the cohorts
with open("config_new/cohorts.txt", "r") as f:
    cohorts = f.read().splitlines()
cohorts.remove("cohorts")

# Get race_groups:
with open("config_new/race_groups.txt", "r") as f:
    races = f.read().splitlines()
races.remove("race_groups")

# create dataframes to store results
results_df = pd.DataFrame(columns=["cohort", "race","lactate","OR","2.5%","97.5%", "N"])
data = pd.read_csv(Path("data/cohorts/cohort_MIMIC_lac1.csv").absolute())

#Converting lactate values into bins
lacs = data.lactate_day1
bins = [0, 2, 4, 6, np.inf]
bin_names = ['0-2', '2-4', '4-6', '>6']
data['lactate_range'] = pd.cut(lacs, bins, right=False, labels=bin_names, include_lowest=True)

#One-hot encoding all categorical columns
categorical_col= ['lactate_range', 'race_group', 'anchor_year_group']
for col in categorical_col:
    data= pd.concat([data.drop(col, axis=1), 
                   pd.get_dummies(data[col], dtype=int)], axis=1)  

cohort='MIMIC'

for race in races:
    print(f"Race: {race}")

    # load data
    subset_data=data[(data[race]==1)]

    conf = confounders + treatments 

    # compute OR based on all data
    X = pd.concat([subset_data[conf], subset_data[bin_names]], axis=1)
    y = subset_data["mortality_in"]

    n_rep = 20
   
   # Creating a list of empty lists to append the mean OR value of the k-fold cross-validation for each iteration across all lactate bins
    new_lists = []
    for p in range(len(bin_names)):
        new_lists.append([])

    #This dictionary will hold the mean OR value as a result of k-fold cross validation for every iteration per lactate bin
    lactate_ORs = {k:v for k,v in zip(bin_names, new_lists)}

    # outer loop
    for i in tqdm(range(n_rep)):

        # Creating a list of empty lists to append OR values for k-fold cross-validation across all lactate bins
        lists = []
        for p in range(len(bin_names)):
            lists.append([])
        
        ##This dictionary will hold all the OR values as a result of k-fold cross validation per lactate bin
        list_dict = {k:v for k,v in zip(bin_names, lists)}


        # normal k-fold cross validation
        kf = StratifiedKFold(n_splits=5, shuffle=True, random_state=i)
            

        # inner loop, in each fold
        for train_index, test_index in tqdm(kf.split(X, y)):
            X_train, X_test = X.iloc[train_index,:], X.iloc[test_index,:]
            y_train, y_test = y.iloc[train_index], y.iloc[test_index]
                
            # # Fit logistic regression model
            model = LogisticRegression(max_iter=10000)
            model.fit(X_test, y_test)

            # Iterating through the lactate bin names and the empty lists to add OR values for k-fold cross validation
            for (lactate, OR) in zip(bin_names, list(list_dict.values())):
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
        results_df.loc[len(results_df.index)] = [cohort, race, lactate_bin, OR, CI_lower, CI_upper, N] 

    # Create a folder if doesn not exist already
    if os.path.exists('results/models')==False:
        os.makedirs('results/models') 

    # save results as we go
    results_df.to_csv(f"results/models/{setting}.csv", index=False)