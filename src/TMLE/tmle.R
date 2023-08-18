library(tmle)
library(tidyverse)

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries,
                    results_df) {

    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]
    
    result <- tmle(
                Y = Y,
                A = A,
                W = W,
                family = "binomial", 
                gbound = c(0.05, 0.95),
                g.SL.library = SL_libraries$SL_library,
                Q.SL.library = SL_libraries$SL_library
                )

    log <- summary(result)   

    results_df[nrow(results_df) + 1,] <- c( outcome,
                                            treatment, # treatment = axis of race/sex/EP
                                            log$estimates$OR$psi,
                                            log$estimates$OR$CI[1],
                                            log$estimates$OR$CI[2],
                                            log$estimates$OR$pvalue,
                                            nrow(data),
                                            paste(SL_libraries$SL_library, collapse = " "),
                                            paste(result$Qinit$coef, collapse = " "),
                                            paste(result$g$coef, collapse = " ")
                                            ) 
    return (results_df)
}

# Main
outcomes <- c("lactate_day1_yes_no") # other outcomes
treatments <- read.delim("config/treatments.txt")
# SL_libraries <- read.delim("config/SL_libraries_SL.txt") # or use only base libraries, see below
SL_libraries <- read.delim("config/SL_libraries_base.txt") # or read.delim("config/SL_libraries_SL.txt")
axis <- read.delim("config/axis.txt")
print(axis)
data <- read.csv("data/cohorts/cohort_MIMIC_lac1.csv")
axis_values <- unique(data$gender)
print(axis_values)

for (a in axis) {
   
    print(paste0("Demographic: ", a))

    # Read Data for this database and cohort
    data <- read.csv("data/cohorts/cohort_MIMIC_lac1.csv")

    # Factorize variables
    confounders <- read.delim(paste0("config/confounders.txt"))
 
    # Creating a list to store the unique values for each axis
    print(a)
    axis_values <- unique(data$a)
    print(axis_values)

    # Setting the reference value for each axis and removing that axis from the confounders list
    if (a == 'race_group') {
        reference <- 'White'
        axis_values <- axis_values[axis_values != reference]
        conf_copy <- confounders[confounders != 'race_group']

    } else if (a == 'gender') {
        reference <- 'M'
        axis_values <- axis_values[axis_values != reference]
        conf_copy <- confounders[confounders != 'sex_female']

    } else {
        reference <- 'ENGLISH'
        axis_values <- axis_values[axis_values != reference]
        conf_copy <- confounders[confounders != 'eng_prof']
    }

    # Encoding columns
    for (col in axis_values) {
        data[[col]] <- ifelse(data[[a]] == col, 1,
                              ifelse(data[[a]] == reference, 0, NA))
    }

    # Dataframe to hold results
    results_df <- data.frame(matrix(ncol=10, nrow=0))
    colnames(results_df) <- c(
                            "outcome",
                            "tx_demographic",
                            "OR",
                            "i_ci",
                            "s_ci",
                            "pvalue",
                            "n",
                            "SL_libraries",
                            "Q_weights",
                            "g_weights")

    # Run TMLE
    results_df <- run_tmle(data, treatment, model_confounders, outcome, 
                            SL_libraries, results_df)

    # Save Results
    write.csv(results_df, paste0("results/tmle/tmle_", a, ".csv"))
}
