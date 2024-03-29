import os
from math import sqrt

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.api as sm
from patsy import dmatrices
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from statsmodels.formula.api import glm
from statsmodels.stats.outliers_influence import variance_inflation_factor

# get parent directory of this file
script_dir = os.path.dirname(__file__)

# get root directory of this project (two levels up from this file)
root_dir = os.path.abspath(os.path.join(script_dir, os.pardir, os.pardir))

# Read confounders from list in txt
with open("config/dag_confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Load the data into a DataFrame
df = pd.read_csv("data/cohorts/cohort_MIMIC_entire_los.csv")
df.head()

df.fillna(0, inplace=True)

df["lactate_freq_normalized"] = (
    df["lactate_freq_whole"] / df["los_icu"]
)  # move to cohort selection
df_sub = df[df["lactate_freq_normalized"] < 10]


split_index = int(len(df_sub) * 0.8)  # 80% for training, 20% for testing

df_train = df_sub[:split_index]
df_test = df_sub[split_index:]
print("Training data set length=" + str(len(df_train)))
print("Testing data set length=" + str(len(df_test)))

# One-hot encoding all categorical columns
categorical_col = ["race_group"]
for col in categorical_col:
    df_train = pd.concat(
        [df_train.drop(col, axis=1), pd.get_dummies(df_train[col], dtype=int)], axis=1
    )
    df_test = pd.concat(
        [df_test.drop(col, axis=1), pd.get_dummies(df_test[col], dtype=int)], axis=1
    )

print(df_train.columns)

expr = "lactate_freq_normalized ~ admission_age + Black + Asian + Hispanic + sex_female + eng_prof + private_insurance + adm_elective + charlson_comorbidity_index + SOFA + fluids_volume_norm_by_los_icu + pneumonia + uti + biliary + skin"

y_train, X_train = dmatrices(expr, df_train, return_type="dataframe")
y_test, X_test = dmatrices(expr, df_test, return_type="dataframe")

# Removing the reference columns
# X_train.drop('race_group[T.White]', axis=1, inplace=True)
# X_test.drop('race_group[T.White]', axis=1, inplace=True)
# X.drop('2008 - 2010', axis=1, inplace=True)


# Creating the Negative Binomial model
nb_training_results = sm.GLM(
    y_train, X_train, family=sm.families.NegativeBinomial(alpha=1)
).fit()

print(nb_training_results.summary())
print(nb_training_results.params)


# Extract coefficient names and values
coef_names = nb_training_results.params.index
coef_values = nb_training_results.params.values

# Calculate exponentiated coefficients
coef_exp = np.exp(coef_values)
print(coef_exp)

negbin_predictions = nb_training_results.predict(X_test)
predicted_counts = negbin_predictions
actual_counts = y_test

# Calculate RMSE for the negative binomial model
rmse = np.sqrt(np.mean(np.power(predicted_counts - actual_counts, 2)))
print("Negative Binomial RMSE=", rmse)

# Calculate R-squared for count data models
total_var = np.sum(np.power(actual_counts - np.mean(actual_counts), 2))
deviance = np.sum(np.power(actual_counts - predicted_counts, 2))
r2_count = 1 - (deviance / total_var)
print("R-squared (Count Data Models):", r2_count)


# Accuracy of the test set
print(
    "R-square of train set: ", round(r2_score(y_test, predicted_counts) * 100, 2), "%"
)

# Creating and plotting the graph
fig1 = plt.figure()
fig1.suptitle("Predicted versus actual counts using the Negative Binomial model")
plt.scatter(actual_counts, predicted_counts)
plt.xlabel("Actual Counts")
plt.ylabel("Predicted Counts")
# plt.ylim(0,10)
# plt.xlim(0,10)
plt.show()

fig1.savefig(os.path.join(root_dir, "results/neg_bin_reg", "neg_bin_plot1_subset.png"))

# Assuming you have the results from nb_training_results.summary2()
# Replace the following line with the actual summary results from your model
summary_table = nb_training_results.summary2().tables[1]

# Extract the CI columns from the summary table and create a copy
coef_table = summary_table[["[0.025", "0.975]"]].copy()

# Exponentiate the CI values using np.exp()
LCI_exp = np.exp(coef_table["[0.025"])
UCI_exp = np.exp(coef_table["0.975]"])

# Add the exponentiated CI values to the DataFrame as new columns
coef_table["Lower_CI_exp"] = LCI_exp
coef_table["Upper_CI_exp"] = UCI_exp

# Inserting exponentiating coefficients
coef_table.insert(0, "IRR", coef_exp)

# Drop the original non-exponentiated CI columns
coef_table.drop(columns=["[0.025", "0.975]"], inplace=True)

# Round the values in the DataFrame to a specified number of decimal places (e.g., 5)
coef_table = coef_table.round(2)

coef_table.reset_index(inplace=True)

# Display the table
print(coef_table)

# Download as a CSV file
coef_table.to_csv(
    "results/neg_bin_reg/negbin_exponentiated_CI_results_subset.csv", index=False
)

# Assuming you have the DataFrame 'coef_table' with columns: 'IRR', 'Lower_CI_exp', 'Upper_CI_exp'
coef_table = coef_table.sort_values(by="Upper_CI_exp", ascending=True)

fig2, ax2 = plt.subplots(
    figsize=(10, len(coef_table) * 0.4)
)  # Adjust the figure size according to your preference
fig2.subplots_adjust(left=0.2)

# Calculate the errors for error bars without taking the absolute value
lower_errors = coef_table["IRR"] - coef_table["Lower_CI_exp"]
upper_errors = coef_table["Upper_CI_exp"] - coef_table["IRR"]

# Create the forest plot with error bars
plt.errorbar(
    coef_table["IRR"],
    coef_names,
    xerr=[lower_errors, upper_errors],
    linestyle="",
    marker="o",
    markersize=5,
    capsize=5,
    color="black",
)

# Set the y-ticks and labels
plt.yticks(range(len(coef_table)), coef_names)
plt.axvline(x=1, color="red", linestyle="--", label="IRR = 1")

# Set the labels for x and y axes
plt.xlabel("IRR")
plt.ylabel("Studies")
plt.xlim(0, 2)

# Show the plot
plt.show()

fig2.savefig(os.path.join(root_dir, "results/neg_bin_reg", "neg_bin_plot2_subset.png"))


def calculate_vif(race_df):
    # Create a DataFrame to store the VIF values
    vif_data = pd.DataFrame()
    vif_data["Feature"] = race_df.columns
    vif_data["VIF"] = [
        variance_inflation_factor(race_df.values, i) for i in range(race_df.shape[1])
    ]
    return vif_data


# Assuming 'X_train' is a DataFrame containing the predictor variables
vif_result = calculate_vif(X_train)

# Rounding all values to two decimal places
vif_result = vif_result.round(2)

vif_result.to_csv("results/neg_bin_reg/negbin_vif_result_subset.csv", index=False)
