# Is Lactate Racist?

## Experimental Design

### Research Question

Is the relationship between lactate and mortality different across races in septic patients? 

### Data extraction

The following features are extracted from **MIMIC-IV and eICU-CRD.**

Please see the Google Spreadsheet:

https://docs.google.com/spreadsheets/d/1NYRQ-eGS3CQEKjPwsEqoLHe82ctdbPU_LBAuY_EdbfI/edit#gid=0

(access restricted to team members)

### Inclusion Criteria

From the initial selection of sepsis patients patients (Sepsis-3) are filtered using the following inclusion criteria:

- Adult (≥ 18 years of age)
- Lactate values ≥ 3
- LoS > 24 h

At every step monitor the following demographics to see who is being excluded:

- Race
- English prof.
- Sex

(to be organized)

## How to run this project?

### 1. Get the Data!

Both MIMIC and eICU data can be found in [PhysioNet](https://physionet.org/), a repository of freely-available medical research data, managed by the MIT Laboratory for Computational Physiology. Due to its sensitive nature, credentialing is required to access both datasets.

Documentation for MIMIC-IV's can be found [here](https://mimic.mit.edu/) and for eICU [here](https://eicu-crd.mit.edu/).

#### Integration with Google Cloud Platform (GCP)

In this section, we explain how to set up GCP and your environment in order to run SQL queries through GCP right from your local Python setting. Follow these steps:

1) Create a Google account if you don't have one and go to [Google Cloud Platform](https://console.cloud.google.com/bigquery)
2) Enable the [BigQuery API](https://console.cloud.google.com/apis/api/bigquery.googleapis.com)
3) Create a [Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts), where you can download your JSON keys
4) Place your JSON keys in the parent folder (for example) of your project
5) Create a .env file with the command `cp env.example env `
6) Update your .env file with your ***JSON keys*** path and the ***id*** of your project in BigQuery

#### MIMIC-IV

After getting credentialing at PhysioNet, you must sign the data use agreement and connect the database with GCP, either asking for permission or uploading the data to your project. Please note that only MIMIC v2.0 is available at GCP.

Having all the necessary tables for the cohort generation query in your project, run the following command to fetch the data as a dataframe that will be saved as CSV in your local project. Make sure you have all required files and folders.

```shell
python3 src/cohorts/1_get_data.py --sql "src/sql/MIMIC/MIMIC_lactate.sql" --destination "data/MIMIC_data.csv"
```

This will create the file `data/MIMIC_data.csv`

#### eICU-CRD

The rationale for eICU-CRD is similar. Run the following commands:

```sh
python3 src/cohorts/1_get_data.py --sql "src/sql/eICU/eICU_lactate.sql" --destination "data/eICU_data.csv"
```

This creates the file `data/eICU_data.csv`

### 2. Get the Cohorts

With the following command, you can get the same cohorts we used for the study:

```sh
python3 src/cohorts/2A_eICU.py
```

This will create the files `data/cohort_MIMIC.csv` and `data/cohort_eICU.csv`.

### 3. Run the XXXX analysis

We made it really easy for you in this part. All you have to do is:

```sh
source("src/r/XXXX.R")
```

And you'll get the resulting odds ratios both for MIMIC and eICU, for both timepoints and all sensitivity analysis here: `results/tmle`

## How to contribute?

We are actively working on this project.
Feel free to raise questions opening an issue, send an email to jcmatos@mit.edu or to fork this project and submit a pull request!
