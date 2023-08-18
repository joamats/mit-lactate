source("src/r_scripts/load_data.R")
source("src/r_scripts/utils.R")

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries,
                     cohort, race, sev_min, sev_max, results_df) {

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
                                            treatment,
                                            cohort,
                                            race,
                                            sev_min,
                                            sev_max,
                                            log$estimates$ATE$psi,
                                            log$estimates$ATE$CI[1],
                                            log$estimates$ATE$CI[2],
                                            log$estimates$ATE$pvalue,
                                            nrow(data),
                                            paste(SL_libraries$SL_library, collapse = " "),
                                            paste(result$Qinit$coef, collapse = " "),
                                            paste(result$g$coef, collapse = " ")
                                            ) 
    return (results_df)
}

# Main
cohorts <- c("MIMIC") # choose "MIMIC" only
outcomes <- c("odd_hour") # "odd_hour","insulin_yes", "blood_yes", "comb_noso", "mortality_in"
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")
treatments <- read.delim("config/treatments.txt")
SL_libraries <- read.delim("config/SL_libraries_SL.txt") # or use only base libraries, see below
#SL_libraries <- read.delim("config/SL_libraries_base.txt") # or read.delim("config/SL_libraries_SL.txt")


for (c in cohorts) {
    print(paste0("Cohort: ", c))

    # Read Data for this database and cohort
    data <- read.csv(paste0("data/", c, ".csv"))

    # Factorize variables

    confounders <- read.delim(paste0("config/confounders_", c,".txt"))

    for (outcome in outcomes) {
        print(paste0("Outcome: ", outcome))

        # Dataframe to hold results
        results_df <- data.frame(matrix(ncol=14, nrow=0))
        colnames(results_df) <- c(
                                "outcome",
                                "treatment",
                                "cohort",
                                "race",
                                "prob_mort_start",
                                "prob_mort_end",
                                "psi",
                                "i_ci",
                                "s_ci",
                                "pvalue",
                                "n",
                                "SL_libraries",
                                "Q_weights",
                                "g_weights")

        if (outcome == "mortality_in") {
            races <- c("white", "non-white") 
        } else {
            races <- c("all") 
        }

        for (j in 1:nrow(treatments)) {
            # Treatment
            treatment <- treatments$treatment[j]
            print(paste0("Treatment: ", treatment))

            # Get formula with confounders and treatment
            model_confounders <- read_confounders(j, treatments, confounders) 

            for (r in races) {

                print(paste0("Race: ", r))

                if (r == "non-white") {
                    subset_data <- subset(data, ethnicity_white == 0)

                } else if (r == "white") {        
                    subset_data <- subset(data, ethnicity_white == 1)
                    
                } else {
                    subset_data <- data
                }

                for (i in 1:nrow(prob_mort_ranges)) {
                    
                    sev_min <- prob_mort_ranges$min[i]
                    sev_max <- prob_mort_ranges$max[i]

                    print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                    # Stratify by prob_mort
                    subsubset_data <- subset(subset_data, prob_mort >= sev_min & prob_mort < sev_max)
                    
                    # Run TMLE
                    results_df <- run_tmle(subsubset_data, treatment, model_confounders, outcome, 
                                           SL_libraries, c, r, sev_min, sev_max, results_df)

                    # Save Results
                    write.csv(results_df, paste0("results/prob_mort/", c, "/", outcome, ".csv"))

                }
            }           
        }
    }
}
