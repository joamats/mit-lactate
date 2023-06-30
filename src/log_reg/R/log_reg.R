library("openxlsx")

read_confounders <- function(j, treatments, confounders) {

    t <- treatments$treatment[j]
    vars <- paste0(t, " ~ ")

    other_t <- treatments$treatment[-j]

    for (k in 1:length(other_t)) {

        vars <- paste0(vars, other_t[k], " + ")
    }

    for (i in 1:nrow(confounders)) {

        vars <- paste0(vars, confounders$confounder[i], " + ")
    }

    fla <- substr(vars, 1, nchar(vars)-3)
    return(as.formula(fla))
}

run_glm <- function(df, fla) {

    m <- glm(fla, data = df, family = "binomial"(link=logit))
    m_OR <- exp(cbind(OR = coef(m), confint(m), N = log(nobs(m)) ))

    return (m_OR)
}

# Main
#databases <- c("MIMIC", "eICU")
cohorts <- c("all", "cancer")
sofa_ranges <- read.csv("config/SOFA_ranges.csv")
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/confounders_sofa.txt")


#for (d in databases) {
    for (c in cohorts) {

        # Read Data for this database and cohort
        df <- read.csv(paste0("data/cohort_merged_", c, ".csv"))
        # df <- read.csv(paste0("data/cohort_", d, "_", c, ".csv")) # with separate databases

        print(paste0("Study: ", " - ", c))
        # print(paste0("Study: ", d, " - ", c)) # with separate databases

        for (i in 1:nrow(sofa_ranges)) {

            sofa_max <- sofa_ranges$max[i]
            sofa_min <- sofa_ranges$min[i]

            print(paste0("Stratification by SOFA: ", sofa_min, " - ", sofa_max))

            for (j in 1:nrow(treatments)) {
                # Treatment
                t <- treatments$treatment[j]

                # Stratify by SOFA
                subset_df <- subset(df, SOFA <= sofa_max & SOFA >= sofa_min)

                # Get formula with confounders and treatment
                formula <- read_confounders(j, treatments, confounders) 
                print(paste0("Treatment: ", as.character(formula)[2]))
                print(paste0("Adjusted for: ", as.character(formula)[3]))

                # Run GLM
                m_OR <- run_glm(subset_df, formula)
                m_OR_frame <- as.data.frame(m_OR)
                m_OR_frame$varnames <- rownames(m_OR)
                print("GLM Results")
                print(m_OR_frame)

                # Save Results
                write.xlsx(m_OR_frame, 
                file=paste0("results/glm/merged_", c, "_S_max", sofa_max, "_", t, ".xlsx"),
                asTable = TRUE)
                #write.csv(m_OR, paste0("results/glm/", d, "_", c, ".csv")) # with separate databases
            }           
        }
    }
#}