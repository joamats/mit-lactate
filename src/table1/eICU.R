# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

source("src/load_data.R")

df <- read_csv('data/cohort_merged.csv', show_col_types = FALSE)

df$sex_female <- factor(df$sex_female, levels=c(1,0), labels=c("Female", "Male"))
df$mortality_in <- factor(df$mortality_in, levels=c(1,0), labels=c("Died", "Survived"))
df$mortality_90 <- factor(df$mortality_90, levels=c(1,0), labels=c("Died", "Survived"))

df$mech_vent <- factor(df$mech_vent, levels=c(1,0), labels=c("Received", "Not received"))
df$rrt <- factor(df$rrt, levels=c(1,0), labels=c("Received", "Did not receive"))
df$vasopressor <- factor(df$vasopressor, levels=c(1,0), labels=c("Received", "Not received"))

df$is_full_code_admission <- factor(df$is_full_code_admission, levels=c(0,1), labels=c("Not Full Code", "Full Code"))
df$is_full_code_discharge <- factor(df$is_full_code_discharge, levels=c(0,1), labels=c("Not Full Code", "Full Code"))

df$age_ranges <- df$anchor_age
df$age_ranges[df$anchor_age >= 18 & df$anchor_age <= 44] <- "18 - 44"
df$age_ranges[df$anchor_age >= 45 & df$anchor_age <= 64] <- "45 - 64"
df$age_ranges[df$anchor_age >= 65 & df$anchor_age <= 74] <- "65 - 74"
df$age_ranges[df$anchor_age >= 75 & df$anchor_age <= 84] <- "75 - 84"
df$age_ranges[df$anchor_age >= 85] <- "85 and higher"

# Cohort of Source
df <- df %>% mutate(source = ifelse(source == "mimic", "MIMIC", "eICU"))

# Cancer Categories
df <- df %>% mutate(cat_solid = ifelse(cat_solid == 1, "Present", "Not Present"))
df <- df %>% mutate(cat_hematological = ifelse(cat_hematological == 1, "Present", "Not Present"))
df <- df %>% mutate(cat_metastasized = ifelse(cat_metastasized == 1, "Present", "Not Present"))

# Cancer Types
df <- df %>% mutate(loc_colon_rectal = ifelse(loc_colon_rectal == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_liver_bd = ifelse(loc_liver_bd == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_pancreatic = ifelse(loc_pancreatic == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_lung_bronchus = ifelse(loc_lung_bronchus == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_melanoma = ifelse(loc_melanoma == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_breast = ifelse(loc_breast == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_endometrial = ifelse(loc_endometrial == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_prostate = ifelse(loc_prostate == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_kidney = ifelse(loc_kidney == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_bladder = ifelse(loc_bladder == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_thyroid = ifelse(loc_thyroid == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_nhl = ifelse(loc_nhl == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_leukemia = ifelse(loc_leukemia == 1, "Present", "Not Present"))

# Get data into factor format
df$SOFA_ranges <- factor(df$SOFA_ranges, levels = c('0-3', '4-6', '7-10', '>10'),
                                         labels = c('0 - 3', '4 - 6','7 - 10', '11 and above'))

df$CCI_ranges <- factor(df$CCI_ranges, levels = c('0-3', '4-6', '7-10', '>10'),
                                       labels = c('0 - 3', '4 - 6', '7 - 10', '11 and above'))
df$source <- factor(df$source)

df$com_hypertension_present <- factor(df$com_hypertension_present, levels = c(0, 1), 
                        labels = c('Hypertension absent', 'Hypertension present'))

df$com_heart_failure_present <- factor(df$com_heart_failure_present, levels = c(0, 1), 
                        labels = c('CHF absent', 'CHF present'))

df$com_copd_present <- factor(df$com_copd_present, levels = c(0, 1), 
                        labels = c('COPD absent', 'COPD present'))

df$com_asthma_present <- factor(df$com_asthma_present, levels = c(0, 1), 
                        labels = c('Asthma absent', 'Asthma present'))

df <- within(df, com_ckd_stages <- factor(com_ckd_stages, levels = c(0, 1, 2, 3, 4, 5)))
df <- within(df, com_ckd_stages <- fct_collapse(com_ckd_stages, Absent=c("0", "1", "2"), Present=c("3", "4", "5")))

df$cancer_type <- 0
df$cancer_type[df$cat_solid == "Present"] <- 1
df$cancer_type[df$cat_metastasized == "Present"] <- 2
df$cancer_type[df$cat_hematological == "Present"] <- 3

df$cancer_type <- factor(df$cancer_type, levels = c(1, 2, 3), 
                        labels = c('Solid cancer', 'Metastasized cancer', 'Hematological cancer'))

# Factorize and label variables
label(df$age_ranges) <- "Age by group"
units(df$age_ranges) <- "years"

label(df$anchor_age) <- "Age overall"
units(df$anchor_age) <- "years"

label(df$sex_female) <- "Sex"
label(df$SOFA) <- "SOFA continuous"
label(df$SOFA_ranges) <- "SOFA Ranges"

label(df$los_icu) <- "Length of stay"
units(df$los_icu) <- "days"

label(df$CCI) <- "Charlson Comorbidity Index continuous (CCI)"
label(df$CCI_ranges) <- "CCI Ranges"

label(df$mech_vent) <- "Mechanic Ventilation"
label(df$rrt) <- "Renal Replacement Therapy"
label(df$vasopressor) <- "Vasopressor(s)"

label(df$mortality_in) <- "In-hospital Mortality"
label(df$mortality_90) <- "90-days Mortality"

label(df$has_cancer) <- "Active Cancer"

label(df$cat_solid) <- "Solid Cancer"
label(df$cat_hematological) <- "Hematological Cancer"
label(df$cat_metastasized) <- "Metastasized Cancer"

label(df$loc_breast) <- "Breast"
label(df$loc_prostate) <- "Prostate"
label(df$loc_lung_bronchus) <- "Lung (including bronchus)"
label(df$loc_colon_rectal) <- "Colon and Rectal (combined)"
label(df$loc_melanoma) <- "Melanoma"
label(df$loc_bladder) <- "Bladder"
label(df$loc_kidney) <- "Kidney"
label(df$loc_nhl) <- "NHL"
label(df$loc_endometrial) <- "Endometrial"
label(df$loc_leukemia) <- "Leukemia"
label(df$loc_pancreatic) <- "Pancreatic"
label(df$loc_thyroid) <- "Thyroid"
label(df$loc_liver_bd) <- "Liver and intrahepatic BD"

label(df$com_hypertension_present) <- "Hypertension"
label(df$com_heart_failure_present) <- "Heart Failure"
label(df$com_copd_present) <- "COPD"
label(df$com_asthma_present) <- "Asthma"
label(df$com_ckd_stages) <- "CKD"

label(df$is_full_code_admission) <- "Full Code upon Admission"
label(df$is_full_code_discharge) <- "Full Code upon Discharge"

label(df$race_group) <- "Race"


render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ mortality_in + mortality_90 +
               mech_vent + rrt + vasopressor +
               age_ranges + anchor_age + sex_female + race_group + 
               SOFA_ranges + SOFA + CCI_ranges + CCI +
               is_full_code_admission + is_full_code_discharge +
               cat_solid + cat_hematological + cat_metastasized +
               loc_colon_rectal + loc_liver_bd + loc_pancreatic +
               loc_lung_bronchus + loc_melanoma + loc_breast +
               loc_endometrial + loc_prostate + loc_kidney +
               loc_bladder + loc_thyroid + loc_nhl + loc_leukemia +
               com_hypertension_present + com_heart_failure_present +
               com_asthma_present + com_copd_present + com_ckd_stages
               | source,
               data=df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )


# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/MIMIC_and_eICU.docx")


###############################
# Table to check positivity assumption
###############################

# Create table1 object for SOFA
tbl_pos <- table1(~ rrt + mech_vent + vasopressor + race_group 
                  | mortality_in*cancer_type, 
                  data=df, 
                  render.missing=NULL, 
                  topclass="Rtable1-grid Rtable1-shade Rtable1-times",
                  render.categorical=render.categorical, 
                  render.strat=render.strat)

# Convert to flextable
t1flex(tbl_pos) %>% save_as_docx(path="results/table1/Table_posA.docx")

