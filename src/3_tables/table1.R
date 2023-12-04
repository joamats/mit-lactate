# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df <- read_csv('data/cohorts/cohort_MIMIC_lac1.csv', show_col_types = FALSE)

# Sex
df$sex_female <- factor(df$sex_female, levels=c(1,0), labels=c("Female", "Male"))
label(df$sex_female) <- "Sex"

# Age
label(df$admission_age) <- "Age overall"
units(df$admission_age) <- "years"

df$eng_prof <- factor(df$eng_prof, levels=c(1,0), labels=c("Yes", "No"))
label(df$eng_prof) <- "English proficiency"

df$insurance <- factor(df$insurance, levels=c("Medicare", "Medicaid", "Other"), labels=c("Medicare", "Medicaid", "Other"))
label(df$insurance) <- "Insurance"

# new race column
df$binary_race <- ifelse(df$race_group == "White", "White", "Non-white")

# Race/Ethnicity
df$binary_race <- factor(df$binary_race, levels = c("White", "Non-white"),
                        labels = c("White", "Non-white"))
label(df$binary_race) <- "Race Group"

label(df$SOFA) <- "SOFA"

label(df$charlson_comorbidity_index) <- "Charlson Comorbidity Index (CCI)"

df$adm_elective <- factor(df$adm_elective, levels = c(0, 1), 
              labels = c('Emergency admission', 'Elective admission'))

# label(df$ckd_stages) <- "CKD"

# Weight
label(df$weight_admit) <- "Weight"
units(df$weight_admit) <- "kg"

# Lactate
label(df$lactate_day1) <- "Lactate day 1"
units(df$lactate_day1) <- "mmol/L"
label(df$lactate_freq_day1) <- "Number of lactate measurements day 1"

label(df$lactate_day2) <- "Lactate day 2"
units(df$lactate_day2) <- "mmol/L"
label(df$lactate_freq_day2) <- "Number of lactate measurements day 2"

# Hemoglobin
label(df$hemoglobin_min) <- "Min. Hemoglobin (entire stay)"
units(df$hemoglobin_min) <- "g/dL"

# Outcomes
df$mortality_in <- factor(df$mortality_in, levels=c(1,0), labels=c("Died", "Survived"))
label(df$mortality_in) <- "In-hospital Mortality"

df$los_icu_ <- df$los_icu
label(df$los_icu) <- "Length of stay"
units(df$los_icu) <- "days"

# Mechanical Ventilation
df$mech_vent_overall <- factor(df$mech_vent_overall, levels=c(1,0), labels=c("Received", "Not received"))
label(df$mech_vent_overall) <- "Mechanical Ventilation"

# RRT
df$rrt_overall <- factor(df$rrt_overall, levels=c(1,0), labels=c("Received", "Did not receive"))
label(df$rrt_overall) <- "Renal Replacement Therapy"

# df$rrt_start_delta <- df$rrt_start_delta / 60 
# label(df$rrt_start_delta) <- "Time elapsed before RRT"
# units(df$rrt_start_delta) <- "hours"

# VPs
df$vasopressor_overall <- factor(df$vasopressor_overall, levels=c(1,0), labels=c("Received", "Not received"))
label(df$vasopressor_overall) <- "Vasopressor(s)"

# Blood Transfusion
df$transfusion_overall <- factor(df$transfusion_overall, levels=c(1,0), labels=c("Received", "Not received"))
label(df$transfusion_overall) <- "Blood Transfusion (first 2 days)"

# Fluids
#df$fluids_overall_yes <- factor(df$fluids_overall_yes, levels=c(1,0), labels=c("Received", "Not received"))
#label(df$fluids_overall_yes) <- "Fluids (entire stay)"

#df$fluids_yes <- factor(df$fluids_yes, levels=c(1,0), labels=c("Received", "Not received"))
#label(df$fluids_yes) <- "Fluids (during the 2 first days)"

label(df$fluids_volume) <- "Volume of Fluids received (day 1)"
units(df$fluids_volume) <- "mL"

# label(df$fluids_sum_day2) <- "Volume of Fluids received (day 2)"
# units(df$fluids_sum_day2) <- "mL"


render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
  label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ sex_female + admission_age + eng_prof + insurance + SOFA + charlson_comorbidity_index +
                 lactate_day1 + lactate_day2 + lactate_freq_day1 + lactate_freq_day2 +
                 los_icu + insurance + adm_elective + major_surgery +
                 mech_vent_overall +
                 rrt_overall +
                 vasopressor_overall +
                 fluids_volume 
               | binary_race,
               data=df,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat, 
               render.continuous=c(.="Mean (SD)", .="Median (Q1, Q3)")
)


# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/MIMIC_lactate.docx")
