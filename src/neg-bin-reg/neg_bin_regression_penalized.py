import pandas as pd
import numpy as np
import statsmodels.api as sm
import matplotlib.pyplot as plt
from patsy import dmatrices
from statsmodels.formula.api import glm
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from math import sqrt
from statsmodels.stats.outliers_influence import variance_inflation_factor
from sklearn.model_selection import train_test_split
import os

# get parent directory of this file
script_dir = os.path.dirname(__file__)

# get root directory of this project (two levels up from this file)
root_dir = os.path.abspath(os.path.join(script_dir, os.pardir, os.pardir))

# Read confounders from list in txt
with open("config/confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Load the data into a DataFrame
df = pd.read_csv('data/cohorts/cohort_MIMIC_entire_los.csv')
df.head()

print(df.describe())

X = df[confounders]
y = df['lactate_freq_LOS']

#One-hot encoding all categorical columns
categorical_col= ['race_group', 'anchor_year_group']
for col in categorical_col:
    X = pd.concat([X.drop(col, axis=1), pd.get_dummies(X[col], dtype=int)], axis=1)

# Removing the reference columns    
X.drop('White', axis=1, inplace=True)
X.drop('2008 - 2010', axis=1, inplace=True)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

print('Training data set length=' + str(len(X_train)))
print('Testing data set length=' + str(len(X_test)))

# Creating the Negative Binomial model
nb_training_results = sm.GLM(y_train, X_train, family = sm.families.NegativeBinomial(alpha = 1)).fit_regularized()
print(nb_training_results.params)
print(nb_training_results)
#print(nb_training_results.summary())


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
print('Negative Binomial RMSE=', rmse)

# Calculate R-squared for count data models
total_var = np.sum(np.power(actual_counts - np.mean(actual_counts), 2))
deviance = np.sum(np.power(actual_counts - predicted_counts, 2))
r2_count = 1 - (deviance / total_var)
print("R-squared (Count Data Models):", r2_count)


#Accuracy of the test set
print("R-square of train set: ", round(r2_score(y_test, predicted_counts)*100, 2), "%")

# Creating and plotting the graph
fig1 = plt.figure()
fig1.suptitle('Predicted versus actual counts using the Negative Binomial model')
plt.scatter(actual_counts, predicted_counts)
plt.xlabel('Actual Counts')
plt.ylabel('Predicted Counts')
plt.ylim(0,10)
plt.xlim(0,10)
plt.show()

fig1.savefig(os.path.join(root_dir, 'results/neg_bin_reg', 'neg_bin_plot1_penalized.png'))

# Assuming you have the results from nb_training_results.summary2()
# Replace the following line with the actual summary results from your model
summary_table = coef_names.to_frame()

# Extract the CI columns from the summary table and create a copy
#coef_table = summary_table[['[0.025', '0.975]']].copy()

# Exponentiate the CI values using np.exp()
#LCI_exp = np.exp(coef_table['[0.025'])
#UCI_exp = np.exp(coef_table['0.975]'])

# Add the exponentiated CI values to the DataFrame as new columns
#coef_table['Lower_CI_exp'] = LCI_exp
#coef_table['Upper_CI_exp'] = UCI_exp

#Inserting exponentiating coefficients
summary_table.insert(1, 'IRR', coef_exp)

# Drop the original non-exponentiated CI columns
#coef_table.drop(columns=['[0.025', '0.975]'], inplace=True)

# Round the values in the DataFrame to a specified number of decimal places (e.g., 5)
summary_table = summary_table.round(2)

#summary_table.reset_index(inplace=True)

# Display the table
print(summary_table)

# Download as a CSV file
summary_table.to_csv('results/neg_bin_reg/negbin_exponentiated_IRR_results_penalized.csv', index=False)

# Assuming you have the DataFrame 'coef_table' with columns: 'IRR', 'Lower_CI_exp', 'Upper_CI_exp'
#coef_table = coef_table.sort_values(by='Upper_CI_exp', ascending=True)

#fig2 = plt.figure(figsize=(10, len(coef_table) * 0.4))  # Adjust the figure size according to your preference

# Calculate the errors for error bars without taking the absolute value
#lower_errors = coef_table['IRR'] - coef_table['Lower_CI_exp']
#upper_errors = coef_table['Upper_CI_exp'] - coef_table['IRR']

# Create the forest plot with error bars
#plt.errorbar(coef_table['IRR'], range(len(coef_table)), xerr=[lower_errors, upper_errors],
             #linestyle='', marker='o', markersize=5, capsize=5, color='black')

# Set the y-ticks and labels
#plt.yticks(range(len(coef_table)), coef_table.index)
#plt.axvline(x=1, color='red', linestyle='--', label='IRR = 1')

# Set the labels for x and y axes
#plt.xlabel('IRR')
#plt.ylabel('Studies')
#plt.xlim(0, 2)

# Show the plot
#plt.show()

#fig2.savefig(os.path.join(root_dir, 'results/models', 'neg_bin_plot2.png'))

def calculate_vif(race_df):
    # Create a DataFrame to store the VIF values
    vif_data = pd.DataFrame()
    vif_data["Feature"] = race_df.columns
    vif_data["VIF"] = [variance_inflation_factor(race_df.values, i) for i in range(race_df.shape[1])]
    return vif_data

# Assuming 'X_train' is a DataFrame containing the predictor variables
vif_result = calculate_vif(X_train)

# Rounding all values to two decimal places
vif_result = vif_result.round(2)

vif_result.to_csv('results/neg_bin_reg/negbin_vif_result_penalized.csv', index=False)