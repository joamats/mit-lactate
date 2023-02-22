# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df <- read_csv('Desktop/mimic4-lac.csv', show_col_types = FALSE)

# Sex
df$sex_female <- factor(df$sex_female, levels=c(1,0), labels=c("Female", "Male"))
label(df$sex_female) <- "Sex"

# Age
label(df$age) <- "Age overall"
units(df$age) <- "years"

df$age_ranges <- df$age
df$age_ranges[df$age >= 18 & df$age <= 44] <- "18 - 44"
df$age_ranges[df$age >= 45 & df$age <= 64] <- "45 - 64"
df$age_ranges[df$age >= 65 & df$age <= 74] <- "65 - 74"
df$age_ranges[df$age >= 75 & df$age <= 84] <- "75 - 84"
df$age_ranges[df$age >= 85] <- "85 and higher"

label(df$age_ranges) <- "Age by group"
units(df$age_ranges) <- "years"

# Race/Ethnicity
df$race_group <- factor(df$race_group, levels = c("White", "Black", "Hispanic", "Asian", "Other"),
                        labels = c("White", "Black", "Hispanic", "Asian", "Other"))
label(df$race_group) <- "Race Group"

# # Year
# df$year <- factor(df$year, levels = c('2014', '2015'),
#                   labels = c('2014', '2015'))
# label(df$year) <- "Year of Admission"

# Admission SOFA
df$SOFA_ranges <- factor(df$SOFA_ranges, levels = c('0-3', '4-6', '7-10', '>10'),
                         labels = c('0 - 3', '4 - 6','7 - 10', '11 and above'))

label(df$sofa_day1) <- "SOFA"
# label(df$SOFA_ranges) <- "SOFA Ranges"

# Comorbidites
# df$CCI_ranges <- factor(df$CCI_ranges, levels = c('0-3', '4-6', '7-10', '>10'),
#                         labels = c('0 - 3', '4 - 6', '7 - 10', '11 and above'))

label(df$charlson_ci) <- "Charlson Comorbidity Index (CCI)"
# label(df$CCI_ranges) <- "CCI Ranges"

df$cirrhosis_present <- factor(df$cirrhosis_present, levels = c(0, 1), 
                               labels = c('Cirrhosis absent', 'Cirrhosis present'))

# label(df$cirrhosis_present) <- "Cirrhosis"

# df$heart_failure_present <- factor(df$heart_failure_present, levels = c(0, 1), 
#                                    labels = c('CHF absent', 'CHF present'))

# label(df$heart_failure_present) <- "Congestive Heart Failure (CHF)"

# df <- within(df, ckd_stages <- factor(ckd_stages, levels = c(0, 1, 2, 3, 4, 5)))
# df <- within(df, ckd_stages <- fct_collapse(ckd_stages, Absent=c("0", "1", "2"), Present=c("3", "4", "5")))

# label(df$ckd_stages) <- "CKD"

# Weight
label(df$weight) <- "Weight"
units(df$weight) <- "kg"

# Lactate
label(df$lactate_day1) <- "Lactate Day 1"
units(df$lactate_day1) <- "mmol/L"
label(df$lactate_freq_day1) <- "No. Measurements of Lactate in Day 1"

label(df$lactate_day2) <- "Lactate Day 2"
units(df$lactate_day2) <- "mmol/L"
label(df$lactate_freq_day2) <- "No. Measurements of Lactate in Day 2"

# Hemoglobin
label(df$hemoglobin_stay_min) <- "Min. Hemoglobin (entire stay)"
units(df$hemoglobin_stay_min) <- "g/dL"

# Outcomes
df$mortality_in <- factor(df$mortality_in, levels=c(1,0), labels=c("Died", "Survived"))
label(df$mortality_in) <- "In-hospital Mortality"

df$los_icu_days <- df$los_icu_hours / 24
label(df$los_icu_days) <- "Length of stay"
units(df$los_icu_days) <- "days"

# Mechanical Ventilation
df$mech_vent_overall_yes <- factor(df$mech_vent_overall_yes, levels=c(1,0), labels=c("Received", "Not received"))
label(df$mech_vent_overall_yes) <- "Mechanical Ventilation"

# RRT
df$rrt_overall_yes <- factor(df$rrt_overall_yes, levels=c(1,0), labels=c("Received", "Did not receive"))
label(df$rrt_overall_yes) <- "Renal Replacement Therapy"

# df$rrt_start_delta <- df$rrt_start_delta / 60 
# label(df$rrt_start_delta) <- "Time elapsed before RRT"
# units(df$rrt_start_delta) <- "hours"

# VPs
df$vasopressor_overall_yes <- factor(df$vasopressor_overall_yes, levels=c(1,0), labels=c("Received", "Not received"))
label(df$vasopressor_overall_yes) <- "Vasopressor(s)"

# Blood Transfusion
# df$transfusion_overall_yes <- factor(df$transfusion_overall_yes, levels=c(1,0), labels=c("Received", "Not received"))
# label(df$transfusion_overall_yes) <- "Blood Transfusion (entire stay)"

df$transfusion_yes <- factor(df$transfusion_yes, levels=c(1,0), labels=c("Received", "Not received"))
label(df$transfusion_yes) <- "Blood Transfusion (first 2 days)"

# label(df$transfusion_units_day1) <- "Volume of Blood received (day 1)"
# units(df$transfusion_units_day1) <- "mL"

# # label(df$transfusion_units_day2) <- "Volume of Blood received (day 2)"
# units(df$transfusion_units_day2) <- "mL"

# Fluids
#df$fluids_overall_yes <- factor(df$fluids_overall_yes, levels=c(1,0), labels=c("Received", "Not received"))
#label(df$fluids_overall_yes) <- "Fluids (entire stay)"

df$fluids_yes <- factor(df$fluids_yes, levels=c(1,0), labels=c("Received", "Not received"))
label(df$fluids_yes) <- "Fluids (during the 2 first days)"

# label(df$fluids_sum_day1) <- "Volume of Fluids received (day 1)"
# units(df$fluids_sum_day1) <- "mL"

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
tbl1 <- table1(~ age + age_ranges + sex_female + race_group + year +
                 sofa_day1 + charlson_ci +
                 lactate_day1 + lactate_day2 + lactate_freq_day1 + lactate_freq_day2 +
                 hemoglobin_stay_min + 
                 los_icu_days +
                 mech_vent_overall_yes +
                 rrt_overall_yes +
                 vasopressor_overall_yes +
                transfusion_yes +
                fluids_yes 
               | mortality_in,
               data=df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
)


# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="mimic4.docx")


###############################
# Table to check positivity assumption
###############################

# Create table1 object for SOFA
#tbl_pos <- table1(~ rrt_overall_yes + mech_vent_overall_yes + vasopressor_overall_yes + race_group 
#                  | mortality_in*cancer_type, 
#                  data=df, 
#                  render.missing=NULL, 
#                  topclass="Rtable1-grid Rtable1-shade Rtable1-times",
#                  render.categorical=render.categorical, 
#                  render.strat=render.strat)

# Convert to flextable
#t1flex(tbl_pos) %>% save_as_docx(path="results/table1/Table_posA.docx")==
