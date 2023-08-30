library(tmle)
library(tidyverse)

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries, results_df) {
  # Subset data to remove pts with NA in the race group
  data <- data[!is.null(data[[treatment]]), ]

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

  results_df[nrow(results_df) + 1, ] <- c(
    outcome,
    treatment,
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
outcome <- c("lactate_day1_yes_no")
SL_libraries <- read.delim("config/SL_libraries_base.txt")
axis <- readLines("config/axis.txt")
axis <- axis[axis != 'axis'] # remove header

for (a in axis) {
  print(paste0("Demographic: ", a))

  data <- read.csv("data/cohorts/cohort_MIMIC_entire_los.csv")
  confounders <- read.delim(paste0("config/confounders.txt"))
  axis_values <- unique(data[[a]])

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

  master_results_df <- data.frame(matrix(ncol=11, nrow=0))
  colnames(master_results_df) <- c(
    "SOFA",
    "outcome",
    "tx_demographic",
    "OR",
    "i_ci",
    "s_ci",
    "pvalue",
    "n",
    "SL_libraries",
    "Q_weights",
    "g_weights"
  )

  for (col in axis_values) {
    print(paste0("Subgroup: ", col))

    # Define SOFA bins
    sofa_bins <- list(c(0:max(data$SOFA)),
                      c(0:3),
                      c(4:6),
                      c(7:max(data$SOFA)))

    for (sofa_bin in sofa_bins) {
      print(paste0("SOFA Bin: ", min(sofa_bin), "-", max(sofa_bin)))

      data_sofa_subset <- subset(data, SOFA %in% sofa_bin)
      data_subset <- data_sofa_subset
      data_subset[[col]] <- ifelse(data_subset[[a]] == col, 1,
                       ifelse(data_subset[[a]] == reference, 0, NA))

      data_subset <- data_subset %>% drop_na(col)

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
        "g_weights"
      )

      results_df <- run_tmle(data_subset, col, conf_copy, outcome,
                             SL_libraries, results_df)

      results_df$SOFA <- paste(min(sofa_bin), "-", max(sofa_bin))

      master_results_df <- rbind(master_results_df, results_df)
    }
  }
  write.csv(master_results_df, paste0("results/sens/tmle_", a, ".csv"))
}
