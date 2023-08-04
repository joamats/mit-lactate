* Read in data
 cd "/Users/Tristan/Documents/Projekte/Boston Celi/1 Lactate Project/mit-lactate/data/cohorts/"
 import delimited "data/cohorts/cohort_MIMIC_lac1_entire_los.csv", clear

encode race_group, gen(race_group2)

* error: lactate_day1_yes_no contains only 1s, no 0s

* simple model with no interactions
logistic lactate_overall_yes_no admission_age sex_female ib4.race_group2 eng_prof private_insurance adm_elective ///
major_surgery charlson_comorbidity_index sofa pneumonia uti biliary skin
estimates store simple


logistic lactate_overall_yes_no admission_age sex_female ib4.race_group2 eng_prof private_insurance adm_elective ///
major_surgery charlson_comorbidity_index sofa pneumonia uti biliary skin ///
i.race_group2#eng_prof
estimates store interactions

cd "/Users/Tristan/Documents/Projekte/Boston Celi/1 Lactate Project/mit-lactate/src/cohorts/log_reg/Stata/"
etable, estimates(simple interactions) mstat(N) mstat(r2_a) export(interactions.pdf, replace) cstat(_r_b) cstat(_r_ci)

/* keep confounders in case needed
admission_age sex_female i.race_group2 eng_prof private_insurance anchor_year_group ///
adm_elective major_surgery charlson_comorbidity_index SOFA respiration coagulation cardiovascular //
cns renal liver hypertension_present heart_failure_present copd_present asthma_present cad_present ///
connective_disease ckd_stages fluids_volume_norm_by_los_icu resp_rate_mean mbp_mean ///
temperature_mean spo2_mean heart_rate_mean po2_min pco2_max ph_min lactate_max glucose_max ///
sodium_min potassium_max cortisol_min hemoglobin_min fibrinogen_min inr_max ///
pneumonia uti biliary skin
*/
