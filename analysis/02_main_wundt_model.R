# Wundt–Berlyne Paper: Main Inverted-U Model
# 
# Purpose: Fit and report the main inverted-U model:
#   interest ~ complexity + complexity^2
# 
# Output: Statistical results for the main Wundt curve relationship
#
# Dependencies:
# - guardian_all_prepared.rds (from 01_prepare_data.R)
# - guardian_stimulus_prepared.rds (from 01_prepare_data.R)
# - data/models/target_results.rds (reported model predictions used in the paper)

# Load required libraries
library(sandwich)
library(lmtest)

# Load prepared data
guardian_all <- readRDS("data/guardian_all_prepared.rds")
guardian_stimulus <- readRDS("data/guardian_stimulus_prepared.rds")

# Load the reported ridge model predictions:
# the 18 Guardian objective-complexity values in data/models/target_results.rds
# (the independent re-fit in 08_reconstruct_target_results.R is a separate, optional validation)
target_results <- readRDS("data/models/target_results.rds")

# Merge predictions with prepared data
# The model object contains target_results with 'prob' (complexity predictions)
merged_all <- merge(guardian_all, target_results, by = "stimulus", all.x = TRUE)
merged_stimulus <- merge(guardian_stimulus, target_results, by = "stimulus", all.x = TRUE)

# Add squared complexity term
merged_all$prob2 <- merged_all$prob^2

# Fit the main inverted-U model
# interest ~ complexity + complexity^2
m1 <- lm(inte.x ~ prob + prob2, data = merged_all)
m1_sum <- summary(m1)

# Two-way cluster-robust inference
# Clusters: participant (anonymized `session` ID from guardian3.csv) and article (stimulus)
m1.vcov <- sandwich::vcovCL(
  m1,
  cluster = ~ session + stimulus,
  type = "HC1"
)

m1.df <- min(
  length(unique(merged_all$session)),
  length(unique(merged_all$stimulus))
) - 1

m1.robust <- lmtest::coeftest(
  m1,
  vcov. = m1.vcov,
  df = m1.df
)

# Joint Wald test of the full fitted model (all non-intercept coefficients)
m1.terms <- names(coef(m1))[-1]
m1.b <- coef(m1)[m1.terms]
m1.V <- m1.vcov[m1.terms, m1.terms]

f_stat <- c(
  drop(t(m1.b) %*% solve(m1.V, m1.b)) / length(m1.terms),
  length(m1.terms),
  m1.df
)

p_value <- pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)

# Report results
cat("\n=== Main Inverted-U Model Results ===\n")
cat("Model: interest ~ complexity + complexity^2\n")
cat("\n")

# Coefficients
cat("Coefficients:\n")
print(coef(m1))

cat("\nCluster-robust coefficients:\n")
print(m1.robust)

# Model fit
cat("\nModel Fit:\n")
cat(sprintf("R-squared: %s\n", m1_sum$r.squared))
cat(sprintf("F(%d, %d) = %.2f, p = %s\n",
            f_stat[2], f_stat[3], f_stat[1], format(p_value, digits = 4)))

# Linear coefficient
linear_coef <- coef(m1)["prob"]
linear_t <- m1.robust["prob", "t value"]
linear_p <- m1.robust["prob", "Pr(>|t|)"]

# Quadratic coefficient  
quadratic_coef <- coef(m1)["prob2"]
quadratic_t <- m1.robust["prob2", "t value"]
quadratic_p <- m1.robust["prob2", "Pr(>|t|)"]

cat("\nKey Parameters:\n")
cat(sprintf("Linear coefficient (complexity): b = %.3f, t(%d) = %.2f, p = %s\n",
            linear_coef, m1.df, linear_t, format(linear_p, digits = 4)))
cat(sprintf("Quadratic coefficient (complexity^2): b = %.3f, t(%d) = %.2f, p = %s\n",
            quadratic_coef, m1.df, quadratic_t, format(quadratic_p, digits = 4)))

# Return results as a list for use by other scripts
list(
  model = m1,
  model_summary = m1_sum,
  robust_coefficients = m1.robust,
  vcov = m1.vcov,
  df = m1.df,
  f_statistic = f_stat[1],
  f_df = c(f_stat[2], f_stat[3]),
  p_value = p_value,
  r_squared = m1_sum$r.squared,
  merged_all = merged_all,
  merged_stimulus = merged_stimulus
)
