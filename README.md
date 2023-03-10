# Is Lactate Racist?

Presentation: https://docs.google.com/presentation/d/1-TKk9ce1XwDHM6TvKuICP6sDfurDmkwcSuGOBdo1BLE/edit#slide=id.g2141956ef13_0_5

## Experimental Design

### Research Question

Is the relationship between lactate and mortality different across races in septic patients? 

### Data

We're using **MIMIC-IV and eICU-CRD.** Please see the [Google Spreadsheet](https://docs.google.com/spreadsheets/d/1NYRQ-eGS3CQEKjPwsEqoLHe82ctdbPU_LBAuY_EdbfI/edit#gid=0) for more details on the features we are extracting.

### Manuscript

The manuscript is also being update in this [Google Docs](https://docs.google.com/document/d/1svoJH6kvBGYszjV7cqea03cmn5A76vKgUOjln66AChE/edit?usp=sharing).

(access restricted to team members)

### Inclusion Criteria

#### Question 1: Is Serum Lactate Racist?

To answer this first question, from the initial selection of sepsis patients patients (Sepsis-3) are filtered using the following inclusion criteria:

- Lactate Day 1 present
- Adult (≥ 18 years of age)
- LoS > 24 h
- First Stay that meets the criteria from above

#### Question 2: If so, is that because of the treatment that the patients receive over the first ICU days?

And an additional criterion is applied:

- Lactate Day 2 present

At every step, we monitor the following demographics to see who is being excluded:

- Race
- Sex
- English proficiency (MIMIC only)


## How to run this project?

### 1. Get Access to MIMIC and eICU

Both MIMIC and eICU data can be found in [PhysioNet](https://physionet.org/), a repository of freely-available medical research data, managed by the MIT Laboratory for Computational Physiology. Due to its sensitive nature, credentialing is required to access both datasets.

Documentation for MIMIC-IV's can be found [here](https://mimic.mit.edu/) and for eICU [here](https://eicu-crd.mit.edu/).

### 2. Get the raw Data!

After running in BigQuery all the auxiliary queries present in `src/sql`, we can run the main ones: `MIMIC_lactate.SQL` and `eICU_lactate.SQL`. These queries will provide the CSV with all the variables, before inclusion criteria.

Make sure to place them in `data/MIMIC_data.csv` and `data/eICU_data.csv`

### 3. Apply Inclusion Criteria to get the final cohorts

To get the working cohorts, run `python3 src/cohorts/2_MIMIC.py` and `python3 src/cohorts/2_eICU.py`.
Your files will show up in the folder `data/cohorts` (make sure to create in advance).
The excluded patients at each step will also be displayed, for the sake of reporting and sampling bias check.


## Integration with Google Cloud Platform (GCP)

In this section, we explain how to set up GCP and your environment in order to run SQL queries through GCP right from your local Python setting. This is not a mandator step, but trust me, it's so cool to have it set up! Follow these steps:

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

## How to contribute?

We are actively working on this project.
Feel free to raise questions opening an issue, send an email to jcmatos@mit.edu or to fork this project and submit a pull request!
