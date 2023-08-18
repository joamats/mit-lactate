library(tmle)
library(tidyverse)

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries,
                    results_df) {
    # Subset data
    print(unique(data[[treatment]]))
    data <- data[!is.null(data[[treatment]]), ]
    print(unique(data[[treatment]]))
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
outcome <- c("lactate_day1_yes_no") # other outcomes
# SL_libraries <- read.delim("config/SL_libraries_SL.txt") # or use only base libraries, see below
SL_libraries <- read.delim("config/SL_libraries_base.txt") # or read.delim("config/SL_libraries_SL.txt")
axis <- readLines("config/axis.txt")
axis <- axis[axis != 'axis'] # remove header
data <- read.csv("data/cohorts/cohort_MIMIC_entire_los.csv")
axis_values <- unique(data$gender)

for (a in axis) {
   
    print(paste0("Demographic: ", a))

    # Read Data for this database and cohort
    data <- read.csv("data/cohorts/cohort_MIMIC_lac1.csv")

    # Factorize variables
    confounders <- read.delim(paste0("config/confounders.txt"))
 
    # Creating a list to store the unique values for each axis
    axis_values <- unique(data[[a]])
   
    # Setting the reference value for each axis and removing that axis from the confounders list
    if (a == 'race_group') {
        reference <- 'White'
        axis_values <- axis_values[axis_values != reference]
        conf_copy <- confounders[confounders != 'race_group']

    } else if (a == 'gender') {
        print("test g")
        reference <- 'M'
        print(reference)
        axis_values <- axis_values[axis_values != reference]
         print(axis_values)
        conf_copy <- confounders[confounders != 'sex_female']
        print(conf_copy)

    } else {
        print("test L")
        reference <- 'ENGLISH'
        print(reference)
        axis_values <- axis_values[axis_values != reference]
        print(axis_values)
        conf_copy <- confounders[confounders != 'eng_prof']
        print(conf_copy)
    }

    # Encoding columns
    for (col in axis_values) {
    print("encoding loop")  
        print(col)
        
       # data <- data %>% mutate(col = ifelse(race_group=="White", 1, 0))

        data[[col]] <- ifelse(data[[a]] == col, 1,
                           ifelse(data[[a]] == reference, 0, NA))
     print(unique(data[[col]]))         
    }
    print(colnames(data))

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
    results_df <- run_tmle(data, col, conf_copy, outcome, 
                            SL_libraries, results_df)

    # Save Results
    write.csv(results_df, paste0("results/tmle/tmle_", a, ".csv"))
}
