# Wundt-Berlyne Paper: Structural Equation Model
# 
# Purpose: Fit and report all 4 SEM models with comparison tests from the paper
# 
# Output: SEM fit indices, standardized path coefficients, model comparisons for 4 SEM models
#
# Dependencies:
# - data/figshare/m9.figshare.27057958/guardian3.csv (public Guardian experiment data)
# - guardian_all_prepared.rds and guardian_stimulus_prepared.rds (from 01_prepare_data.R)
# - Reported ridge model predictions (prob) in data/models/target_results.rds

# Load required libraries
library(lavaan)
library(semTools)

# Load public Guardian experiment data (anonymized participant IDs in `session`)
guardian_raw <- read.csv(
  "data/figshare/m9.figshare.27057958/guardian3.csv",
  sep = ",",
  header = TRUE,
  na.strings = c("", "NA")
)

# Apply scale inversions (as in 01_prepare_data.R)
guardian_raw$novelty_comprehension_scale_59 = -1 * guardian_raw$novelty_comprehension_scale_59 + 8
guardian_raw$novelty_comprehension_scale_60 = -1 * guardian_raw$novelty_comprehension_scale_60 + 8
guardian_raw$novelty_comprehension_scale_61 = -1 * guardian_raw$novelty_comprehension_scale_61 + 8
guardian_raw$novelty_comprehension_scale_62 = -1 * guardian_raw$novelty_comprehension_scale_62 + 8
guardian_raw$novelty_comprehension_scale_63 = -1 * guardian_raw$novelty_comprehension_scale_63 + 8

guardian_all <- readRDS("data/guardian_all_prepared.rds")
guardian_stimulus <- readRDS("data/guardian_stimulus_prepared.rds")

# Load the reported ridge model predictions used in the paper
target_results <- readRDS("data/models/target_results.rds")
merged_stimulus <- merge(guardian_stimulus, target_results, by = "stimulus")

# Prepare SEM data from the public Guardian data
data_sem <- guardian_raw[c(
  "session", "novelty_comprehension_scale_57", "novelty_comprehension_scale_58",
  "novelty_comprehension_scale_59", "novelty_comprehension_scale_60",
  "novelty_comprehension_scale_61", "novelty_comprehension_scale_62",
  "novelty_comprehension_scale_63", "novelty_comprehension_scale_64",
  "interest_scale_67", "topical_familiarity", "stimulus"
)]
# guardian3.csv names the familiarity measure `topical_familiarity`; the model
# syntax below uses the name `familiarity`
colnames(data_sem)[colnames(data_sem) == "topical_familiarity"] <- "familiarity"

# Add objective complexity (prob) from the model predictions
data_sem <- merge(merged_stimulus[c("stimulus", "prob")], data_sem, by = "stimulus")
data_sem <- na.omit(data_sem)

# Add interaction term for moderation
data_sem$prob_x_famt <- data_sem$prob * data_sem$familiarity

# ============================================================================
# MODEL 1: Partial modulation (prob direct effect only)
# ============================================================================

with_a_model <- '
# Latent variables
# inte and comp are multi-indicator latent constructs; famt is a single-indicator
# construct (the observed familiarity score) with loading fixed to 1
inte =~ novelty_comprehension_scale_63 + novelty_comprehension_scale_64 + interest_scale_67
comp =~ novelty_comprehension_scale_60 + novelty_comprehension_scale_61 + novelty_comprehension_scale_62
famt =~ familiarity

# Mediator relationships
comp ~ a*famt + b*prob
inte ~ c*comp

# Interaction term
prob_x_famt ~ g*famt + h*prob
inte ~ i*prob_x_famt

# Direct effects (prob direct effect only)
inte ~ e*prob

# Indirect effects
ac := a*c
bc := b*c

# Total effects
total_famt := a*c
total_prob := b*c + e
'

with_a_fit <- sem(
  with_a_model,
  data = data_sem,
  std.ov = TRUE,
  estimator = "MLR",
  std.lv = TRUE,
  orthogonal = TRUE
)

with_a_sum <- summary(
  with_a_fit,
  standardize = TRUE,
  rsquare = TRUE,
  fit.measures = TRUE
)

# ============================================================================
# MODEL 2: Partial modulation (famt direct effect only)
# ============================================================================

with_b_model <- '
# Latent variables
inte =~ novelty_comprehension_scale_63 + novelty_comprehension_scale_64 + interest_scale_67
comp =~ novelty_comprehension_scale_60 + novelty_comprehension_scale_61 + novelty_comprehension_scale_62
famt =~ familiarity

# Mediator relationships
comp ~ a*famt + b*prob
inte ~ c*comp

# Interaction term
prob_x_famt ~ g*famt + h*prob
inte ~ i*prob_x_famt

# Direct effects (famt direct effect only)
inte ~ d*famt

# Indirect effects
ac := a*c
bc := b*c

# Total effects
total_famt := a*c + d
total_prob := b*c
'

with_b_fit <- sem(
  with_b_model,
  data = data_sem,
  std.ov = TRUE,
  estimator = "MLR",
  std.lv = TRUE,
  orthogonal = TRUE
)

with_b_sum <- summary(
  with_b_fit,
  standardize = TRUE,
  rsquare = TRUE,
  fit.measures = TRUE
)

# ============================================================================
# MODEL 3: Partial modulation (paths a and b)
# ============================================================================

with_a_and_b_model <- '
# Latent variables
inte =~ novelty_comprehension_scale_63 + novelty_comprehension_scale_64 + interest_scale_67
comp =~ novelty_comprehension_scale_60 + novelty_comprehension_scale_61 + novelty_comprehension_scale_62
famt =~ familiarity

# Mediator relationships
comp ~ a*famt + b*prob
inte ~ c*comp

# Interaction term
prob_x_famt ~ g*famt + h*prob
inte ~ i*prob_x_famt

# Direct effects (paths a and b)
inte ~ d*famt
inte ~ e*prob

# Indirect effects
ac := a*c
bc := b*c

# Total effects
total_famt := a*c + d
total_prob := b*c + e
'

with_a_and_b_fit <- sem(
  with_a_and_b_model,
  data = data_sem,
  std.ov = TRUE,
  estimator = "MLR",
  std.lv = TRUE,
  orthogonal = TRUE
)

with_a_and_b_sum <- summary(
  with_a_and_b_fit,
  standardize = TRUE,
  rsquare = TRUE,
  fit.measures = TRUE
)

# ============================================================================
# MODEL 4: Full modulation (FINAL REPORTED MODEL)
# ============================================================================

full_moderation_model_2 <- '
# Latent variables
# inte and comp are multi-indicator latent constructs; famt is a single-indicator
# construct: the observed topical-familiarity score with its loading fixed to 1
inte =~ novelty_comprehension_scale_63 + novelty_comprehension_scale_64 + interest_scale_67
comp =~ novelty_comprehension_scale_60 + novelty_comprehension_scale_61 + novelty_comprehension_scale_62
famt =~ 1*familiarity

# Mediator relationships
comp ~ a*famt + b*prob
inte ~ c*comp

# Interaction term
prob_x_famt ~ d*famt + e*prob
inte ~ f*prob_x_famt

# Indirect effects
prob_via_comp := b*c
prob_via_mode := e*f
famt_via_comp := a*c
famt_via_mode := d*f

# Total effects
prob_tot := b*c*-1 + e*f
famt_tot := a*c + d*f
'

full_moderation_fit_2 <- sem(
  full_moderation_model_2,
  data = data_sem,
  std.ov = TRUE,
  estimator = "MLR",
  std.lv = TRUE,
  orthogonal = TRUE
)

full_moderation_sum <- summary(
  full_moderation_fit_2,
  standardize = TRUE,
  rsquare = TRUE,
  fit.measures = TRUE
)

# ============================================================================
# MODEL COMPARISON TESTS (4 models: 3 comparison + 1 final)
# ============================================================================

# Compare full modulation model (model 5) with each comparison model
prob_a_test <- anova(full_moderation_fit_2, with_a_fit)
prob_b_test <- anova(full_moderation_fit_2, with_b_fit)
prob_ab_test <- anova(full_moderation_fit_2, with_a_and_b_fit)

# ============================================================================
# REPORT RESULTS
# ============================================================================

# Report fit indices for final model
fit_measures <- fitMeasures(
  full_moderation_fit_2,
  c("cfi.scaled", "srmr", "chisq.scaled", "df", "rmsea.scaled")
)

chisq <- fit_measures["chisq.scaled"]
df <- fit_measures["df"]
cfi <- fit_measures["cfi.scaled"]
srmr <- fit_measures["srmr"]
rmsea <- fit_measures["rmsea.scaled"]

cat("\n=== Final SEM Model ===\n")
cat("Model: Full modulation (Model 2)\n")
cat("\nFit Indices:\n")
cat(sprintf("Chi-square/df: %.3f\n", chisq/df))
cat(sprintf("CFI: %.3f\n", cfi))
cat(sprintf("SRMR: %.3f\n", srmr))
cat(sprintf("RMSEA: %s\n", ifelse(is.na(rmsea), "N/A", sprintf("%.3f", rmsea))))
cat("\nStandardized Path Coefficients:\n")
print(full_moderation_sum$pe[full_moderation_sum$pe$op == "~", ])

cat("\n=== Model Comparison Tests ===\n")
cat("Testing full modulation model against comparison models:\n\n")

cat("1. Full vs Path a only (famt direct effect):\n")
print(prob_a_test)

cat("\n2. Full vs Path b only (prob direct effect):\n")
print(prob_b_test)

cat("\n3. Full vs Both paths (a and b):\n")
print(prob_ab_test)

list(
  # All models
  
  with_a = list(fit = with_a_fit, summary = with_a_sum),
  with_b = list(fit = with_b_fit, summary = with_b_sum),
  with_a_and_b = list(fit = with_a_and_b_fit, summary = with_a_and_b_sum),
  full_moderation = list(fit = full_moderation_fit_2, summary = full_moderation_sum),
  
  # Comparison tests
  prob_a_test = prob_a_test,
  prob_b_test = prob_b_test,
  prob_ab_test = prob_ab_test,
  
  # Fit indices
  chisq = chisq,
  df = df,
  cfi = cfi,
  srmr = srmr,
  rmsea = rmsea,
  fit_measures = fit_measures
)
