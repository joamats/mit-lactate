from tableone import TableOne
import pandas as pd

data = pd.read_csv('data/cohorts/MIMIC_lac1.csv')

# Groupby Variable
groupby = ['race_group']

# Continuous Variables
data['los_hosp_dead'] = data[data.mortality_in == 1].los_hospital
data['los_hosp_surv'] = data[data.mortality_in == 0].los_hospital

data['los_icu_dead'] = data[data.mortality_in == 1].los_icu
data['los_icu_surv'] = data[data.mortality_in == 0].los_icu

# Encode language as English proficiency or Limited English proficiency
data['eng_prof'] = data['language'].apply(lambda x: "Limited" if x == '?' else "Proficient")

# Create variable for receiving fluids, if fluid volume is not na
data['fluids_overall'] = data['fluids_volume'].apply(lambda x: 1. if x > 0 else 0.)

# Encode absolute durations and offsets into hours
data['MV_time_abs'] = data['MV_time_abs'] * 24
data['VP_time_abs'] = data['VP_time_abs'] * 24
data['MV_init_offset_abs'] = data['MV_init_offset_abs'] * 24
data['RRT_init_offset_abs'] = data['RRT_init_offset_abs'] * 24
data['VP_init_offset_abs'] = data['VP_init_offset_abs'] * 24

# Encode NA as 0, if missing means 0
cols_na = ['major_surgery', 'insulin_yes', 'transfusion_yes', 'hypertension_present',
           'heart_failure_present', 'copd_present', 'asthma_present', 'cad_present',
           'ckd_stages', 'diabetes_types', 'connective_disease', 'pneumonia',
           'uti', 'biliary', 'skin']

for c in cols_na:
    data[c] = data[c].fillna(0)

# Encode diabetes and CKD 0 as "Absent"
data['diabetes_types'] = data['diabetes_types'].apply(lambda x: "Absent" if x == 0 else x)
data['ckd_stages'] = data['ckd_stages'].apply(lambda x: "Absent" if x == 0 else x)

order = {
    "race_group": ["White", "Black", "Hispanic", "Asian", "Other"],
    "gender": ["F", "M"],
    "eng_prof": ["Limited", "Proficient"],
    "insurance": ["Medicare", "Medicaid", "Other"],
    "adm_elective": [1, 0],
    "major_surgery": [1., 0.],
    "mortality_in": [1, 0],
    "mortality_90": [1, 0],
    "mech_vent_overall": [1, 0],
    "rrt_overall": [1, 0],
    "vasopressor_overall": [1, 0],
    "insulin_yes": [1., 0.],
    "transfusion_yes": [1., 0.],
    "fluids_overall": [1., 0.],
    "hypertension_present": [1., 0.],
    "heart_failure_present": [1., 0.],
    "copd_present": [1., 0.],
    "asthma_present": [1., 0.],
    "cad_present": [1., 0.],
    "connective_disease": [1., 0.],
    "pneumonia": [1., 0.],
    "uti": [1., 0.],
    "biliary": [1., 0.],
    "skin": [1., 0.],
    "is_full_code_admission": [1, 0],
    "is_full_code_discharge": [1, 0]
}

limit = {"gender": 1,
         "adm_elective": 1,
         "major_surgery": 1,
         "mortality_in": 1,
         "mortality_90": 1,
         "eng_prof": 1,
         "mech_vent_overall": 1,
         "rrt_overall": 1,
         "vasopressor_overall": 1,
         "insulin_yes": 1,
         "transfusion_yes": 1,
         "fluids_overall": 1,
         "hypertension_present": 1,
         "heart_failure_present": 1,
         "copd_present": 1,
         "asthma_present": 1,
         "cad_present": 1,
         "connective_disease": 1,
         "pneumonia": 1,
         "uti": 1,
         "biliary": 1,
         "skin": 1,
         "is_full_code_admission": 1,
         "is_full_code_discharge": 1
        }


categ = ['anchor_year_group', 'gender',
         'insurance', 'eng_prof',
         'adm_elective', 'major_surgery',
         'mortality_in', 'mortality_90',
         'mech_vent_overall', 'rrt_overall', 'vasopressor_overall',
         'insulin_yes', 'transfusion_yes', 'fluids_overall',
         'hypertension_present', 'heart_failure_present',
         'copd_present', 'asthma_present', 'cad_present',
         'ckd_stages', 'diabetes_types', 'connective_disease',
         'pneumonia', 'uti', 'biliary', 'skin',
         'is_full_code_admission', 'is_full_code_discharge',

        ]

nonnorm = ['admission_age', 
           'los_icu_dead', 'los_icu_surv',
           'los_hosp_dead', 'los_hosp_surv',
           'charlson_comorbidity_index', 'SOFA',
           'respiration', 'coagulation', 'liver', 'cardiovascular', 'cns', 'renal',
           'lactate_day1', 'lactate_freq_day1',
           'lactate_day2', 'lactate_freq_day2',
           'fluids_volume', 'fluids_volume_norm_by_los_icu',
           'FiO2_mean_24h',
           'MV_time_abs', 'MV_time_perc_of_stay',
           'MV_init_offset_abs', #'MV_init_offset_perc',
           'RRT_init_offset_abs', #'RRT_init_offset_perc',
           'VP_init_offset_abs', #'VP_init_offset_perc',
           'VP_time_abs', 'VP_time_perc_of_stay',
           'resp_rate_mean', 'mbp_mean', 'temperature_mean',
           'spo2_mean', 'heart_rate_mean',
           'po2_min', 'pco2_max', 'ph_min', 'glucose_max',
           'sodium_min', 'potassium_max', 'cortisol_min', 'hemoglobin_min',
           'fibrinogen_min', 'inr_max'
           ]  

labls = {
    'anchor_age': 'Age',
    'anchor_year_group': 'Year of Admission',
    'admission_age': 'Age',
    'gender': 'Sex ',
    'mortality_in': "In-Hospital Mortality",
    'mortality_90': "90-Day Mortality",
    'eng_prof': "English Proficiency",
    'adm_elective': "Elective Admission",
    'major_surgery': "Major Surgery",
    'insurance': "Health Insurance",
    'race_group': "Race-Ethnicity Group",
    'mech_vent_overall': 'Mechanical Ventilation (whole stay)',
    'rrt_overall': "RRT (whole stay)",
    'vasopressor_overall': 'Vasopressors (whole stay)',
    'insulin_yes': 'Insulin Transfusion (whole stay)',
    'transfusion_yes': "Blood Transufusion (whole stay)",
    'fluids_overall': "Fluids Received (whole stay)",
    'hypertension_present': "Hypertension",
    'heart_failure_present': "Congestive Heart Failure",
    'copd_present': "COPD",
    'asthma_present': "Asthma",
    'cad_present': "Coronary Artery Disease",
    'ckd_stages': "CKD Stage",
    'diabetes_types': "Diabetes Type",
    'connective_disease': "Connective Tissue Disease",
    'pneumonia': "Pneumonia",
    'uti': "Urinary Tract Infection",
    'biliary': "Biliary Tract Infection",
    'skin': "Skin Infection",
    'is_full_code_admission': "Full Code (Admission)",
    'is_full_code_discharge': "Full Code (Discharge)",
    'los_icu_dead': "ICU LOS (days, if deceased)",
    'los_icu_surv': "ICU LOS (days, if survived)",
    'los_hosp_dead': "Hospital LOS (days, if deceased)",
    'los_hosp_surv': "Hospital LOS (days, if survived)",
    'charlson_comorbidity_index': "Charlson Comorbidity Index",
    'SOFA': "SOFA Score (Admission, first 24h)",
    'respiration': "SOFA: Respiration (first 24h)",
    'coagulation': "SOFA: Coagulation (first 24h)",
    'liver': "SOFA: Liver (first 24h)",
    'cardiovascular': "SOFA: Cardiovascular (first 24h)",
    'cns': "SOFA: CNS (first 24h)",
    'renal': "SOFA: Renal (first 24h)",
    'lactate_day1': "Lactate Day 1 (maximum value)",
    'lactate_freq_day1': "Lactate Day 1 (number of measurements)",
    'lactate_day2': "Lactate Day 2 (maximum value)",
    'lactate_freq_day2': "Lactate Day 2 (number of measurements)",
    'fluids_volume': "Fluids Volume (whole stay)",
    'fluids_volume_norm_by_los_icu': "Fluids Volume (whole stay, normalized by ICU LOS)",
    'FiO2_mean_24h': "FiO2 (mean %, first 24h)",
    'MV_time_abs': "MV Time (duration in the stay, hours)",
    'MV_time_perc_of_stay': "MV Time (duration in the stay, % of ICU LOS)",
    # 'MV_init_offset_perc': "MV Initiation (offset, % of ICU LOS)",
    'MV_init_offset_abs': "MV Initiation (offset, hours)",
    # 'RRT_init_offset_perc': "RRT Initiation (offset, % of ICU LOS)",
    'RRT_init_offset_abs': "RRT Initiation (offset, hours)",
    # 'VP_init_offset_perc': "Vasopressor Initiation (offset, % of ICU LOS)",
    'VP_init_offset_abs': "Vasopressor Initiation (offset, hours)",
    'VP_time_abs': "Vasopressor Time (duration in the stay, hours)",
    'VP_time_perc_of_stay': "Vasopressor Time (duration in the stay, % of ICU LOS)",
    'resp_rate_mean': "Respiratory Rate (mean, first 24h)",
    'mbp_mean': "Mean Blood Pressure (mean, first 24h)",
    'temperature_mean': "Temperature (mean, first 24h)",
    'spo2_mean': "SpO2 (mean, first 24h)",
    'heart_rate_mean': "Heart Rate (mean, first 24h)",
    'po2_min': "PaO2 (min, first 24h)",
    'pco2_max': "PaCO2 (max, first 24h)",
    'ph_min': "pH (min, first 24h)",
    'glucose_max': "Glucose (max, first 24h)",
    'sodium_min': "Sodium (min, first 24h)",
    'potassium_max': "Potassium (max, first 24h)",
    'cortisol_min': "Cortisol (min, first 24h)",
    'hemoglobin_min': "Hemoglobin (min, first 24h)",
    'fibrinogen_min': "Fibrinogen (min, first 24h)",
    'inr_max': "INR (max, first 24h)"
    }

decimals = {
    'admission_age': 0,
    'fluids_volume': 0,
    'lacate_day1': 2,
    'lactate_day2': 2,
    'SOFA': 0,
    'respiration': 0,
    'coagulation': 0,
    'liver': 0,
    'cardiovascular': 0,
    'cns': 0,
    'renal': 0,
    'charlson_comorbidity_index': 0,
    'FiO2_mean_24h': 0,
    'los_icu_dead': 2,
    'los_icu_surv': 2,
    'los_hosp_dead': 2,
    'los_hosp_surv': 2,
    'MV_time_perc_of_stay': 2,
    'VP_time_perc_of_stay': 2    
    }


# Create a TableOne 
table1_s = TableOne(data, columns=categ+nonnorm,
                    rename=labls, limit=limit, order=order, decimals=decimals,
                    groupby=groupby, categorical=categ, nonnormal=nonnorm,
                    missing=True, overall=False,
                    dip_test=True, normal_test=True, tukey_test=True, htest_name=True)

table1_s.to_excel('results/table1_MIMIC.xlsx')

# save data for further analysis
data.to_csv('data/cohorts/MIMIC_lac1_clean.csv', index=False)
