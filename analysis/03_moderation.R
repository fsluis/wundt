# Wundt–Berlyne Paper: Moderation Analyses
# 
# Purpose: Fit moderation models for comprehensibility and familiarity,
# compute cluster-robust inference, and generate conditional predictions/contrasts/CIs
# 
# Output: Statistical results for moderation effects reported in the paper
#
# Dependencies:
# - guardian_all_prepared.rds (from 01_prepare_data.R)
# - merged_all with prob from 02_main_wundt_model.R or directly loaded predictions

# Load required libraries
library(sandwich)
library(lmtest)

# Load prepared data with predictions
# In practice, this would be loaded from 02_main_wundt_model.R output
# or directly from the reported predictions
merged_all <- readRDS("data/guardian_all_prepared.rds")

# Load the reported ridge model predictions used in the paper
target_results <- readRDS("data/models/target_results.rds")
merged_all <- merge(merged_all, target_results, by = "stimulus", all.x = TRUE)
merged_all$prob2 <- merged_all$prob^2

# Ensure factors are properly encoded
merged_all$stimulus <- as.factor(merged_all$stimulus)
merged_all$session <- as.factor(merged_all$session)

# ============================================================================
# COMPREHENSIBILITY MODERATION
# ============================================================================

# Fit moderation model with both linear and quadratic interactions
m_comp <- lm(inte.x ~ prob * comp.x + I(prob^2) * comp.x, data = merged_all)
m_comp_sum <- summary(m_comp)

# Two-way cluster-robust inference
m_comp.vcov <- sandwich::vcovCL(
  m_comp,
  cluster = ~ session + stimulus,
  type = "HC1"
)

m_comp.df <- min(
  length(unique(merged_all$session)),
  length(unique(merged_all$stimulus))
) - 1

m_comp.robust <- lmtest::coeftest(
  m_comp,
  vcov. = m_comp.vcov,
  df = m_comp.df
)

# Joint Wald test
m_comp.terms <- names(coef(m_comp))[-1]
m_comp.b <- coef(m_comp)[m_comp.terms]
m_comp.V <- m_comp.vcov[m_comp.terms, m_comp.terms]

f_comp <- c(
  drop(t(m_comp.b) %*% solve(m_comp.V, m_comp.b)) / length(m_comp.terms),
  length(m_comp.terms),
  m_comp.df
)
p_comp <- pf(f_comp[1], f_comp[2], f_comp[3], lower.tail = FALSE)

# Report comprehensibility moderation results
cat("\n=== Comprehensibility Moderation ===\n")
cat(sprintf("R-squared: %s\n", m_comp_sum$r.squared))
cat(sprintf("F(%d, %d) = %.2f, p = %s\n",
            f_comp[2], f_comp[3], f_comp[1], format(p_comp, digits = 4)))
cat("\nCoefficients:\n")
print(m_comp.robust)

# Conditional predictions for comprehensibility
comp_mean <- mean(merged_all$comp.x, na.rm = TRUE)
comp_sd <- sd(merged_all$comp.x, na.rm = TRUE)
comp_vals <- c(
  low = comp_mean - comp_sd,
  mean = comp_mean,
  high = comp_mean + comp_sd
)

xgrid <- seq(
  min(merged_all$prob, na.rm = TRUE),
  max(merged_all$prob, na.rm = TRUE),
  length.out = 200
)

# Generate predictions for each comprehensibility level
comp_predictions <- lapply(names(comp_vals), function(lbl) {
  comp_value <- comp_vals[[lbl]]
  newdat <- data.frame(prob = xgrid, comp.x = comp_value)
  X <- model.matrix(delete.response(terms(m_comp)), newdat, contrasts.arg = m_comp$contrasts)
  pred <- drop(X %*% coef(m_comp))
  
  # For mean level, no contrast CI
  if (lbl == "mean") {
    data.frame(
      prob = xgrid,
      inte.x = pred,
      conf.low = NA_real_,
      conf.high = NA_real_,
      comp_level = lbl
    )
  } else {
    # For low/high levels: contrast against mean
    new_ref <- data.frame(prob = xgrid, comp.x = comp_mean)
    X_ref <- model.matrix(delete.response(terms(m_comp)), new_ref, contrasts.arg = m_comp$contrasts)
    ref_pred <- drop(X_ref %*% coef(m_comp))
    D <- X - X_ref
    diff <- drop(D %*% coef(m_comp))
    diff_se <- sqrt(pmax(0, diag(D %*% m_comp.vcov %*% t(D))))
    crit <- qt(.975, df = m_comp.df)
    
    data.frame(
      prob = xgrid,
      inte.x = pred,
      conf.low = ref_pred + diff - crit * diff_se,
      conf.high = ref_pred + diff + crit * diff_se,
      comp_level = lbl
    )
  }
})
comp_predictions <- do.call(rbind, comp_predictions)

# ============================================================================
# FAMILIARITY MODERATION
# ============================================================================

# Fit moderation model with both linear and quadratic interactions
m_famt <- lm(inte.x ~ prob * famt.x + I(prob^2) * famt.x, data = merged_all)
m_famt_sum <- summary(m_famt)

# Two-way cluster-robust inference
m_famt.vcov <- sandwich::vcovCL(
  m_famt,
  cluster = ~ session + stimulus,
  type = "HC1"
)

m_famt.df <- min(
  length(unique(merged_all$session)),
  length(unique(merged_all$stimulus))
) - 1

m_famt.robust <- lmtest::coeftest(
  m_famt,
  vcov. = m_famt.vcov,
  df = m_famt.df
)

# Joint Wald test
m_famt.terms <- names(coef(m_famt))[-1]
m_famt.b <- coef(m_famt)[m_famt.terms]
m_famt.V <- m_famt.vcov[m_famt.terms, m_famt.terms]

f_famt <- c(
  drop(t(m_famt.b) %*% solve(m_famt.V, m_famt.b)) / length(m_famt.terms),
  length(m_famt.terms),
  m_famt.df
)
p_famt <- pf(f_famt[1], f_famt[2], f_famt[3], lower.tail = FALSE)

# Report familiarity moderation results
cat("\n=== Familiarity Moderation ===\n")
cat(sprintf("R-squared: %s\n", m_famt_sum$r.squared))
cat(sprintf("F(%d, %d) = %.2f, p = %s\n",
            f_famt[2], f_famt[3], f_famt[1], format(p_famt, digits = 4)))
cat("\nCoefficients:\n")
print(m_famt.robust)

# Conditional predictions for familiarity
famt_mean <- mean(merged_all$famt.x, na.rm = TRUE)
famt_sd <- sd(merged_all$famt.x, na.rm = TRUE)
famt_vals <- c(
  low = famt_mean - famt_sd,
  mean = famt_mean,
  high = famt_mean + famt_sd
)

# Generate predictions for each familiarity level
famt_predictions <- lapply(names(famt_vals), function(lbl) {
  famt_value <- famt_vals[[lbl]]
  newdat <- data.frame(prob = xgrid, famt.x = famt_value)
  X <- model.matrix(delete.response(terms(m_famt)), newdat, contrasts.arg = m_famt$contrasts)
  pred <- drop(X %*% coef(m_famt))
  
  # For mean level, no contrast CI
  if (lbl == "mean") {
    data.frame(
      prob = xgrid,
      inte.x = pred,
      conf.low = NA_real_,
      conf.high = NA_real_,
      famt_level = lbl
    )
  } else {
    # For low/high levels: contrast against mean
    new_ref <- data.frame(prob = xgrid, famt.x = famt_mean)
    X_ref <- model.matrix(delete.response(terms(m_famt)), new_ref, contrasts.arg = m_famt$contrasts)
    ref_pred <- drop(X_ref %*% coef(m_famt))
    D <- X - X_ref
    diff <- drop(D %*% coef(m_famt))
    diff_se <- sqrt(pmax(0, diag(D %*% m_famt.vcov %*% t(D))))
    crit <- qt(.975, df = m_famt.df)
    
    data.frame(
      prob = xgrid,
      inte.x = pred,
      conf.low = ref_pred + diff - crit * diff_se,
      conf.high = ref_pred + diff + crit * diff_se,
      famt_level = lbl
    )
  }
})
famt_predictions <- do.call(rbind, famt_predictions)

# ============================================================================
# Return all results
# ============================================================================

list(
  # Comprehensibility moderation
  comp_model = m_comp,
  comp_summary = m_comp_sum,
  comp_robust = m_comp.robust,
  comp_vcov = m_comp.vcov,
  comp_df = m_comp.df,
  comp_f_stat = f_comp[1],
  comp_f_df = c(f_comp[2], f_comp[3]),
  comp_p_value = p_comp,
  comp_r_squared = m_comp_sum$r.squared,
  comp_predictions = comp_predictions,
  
  # Familiarity moderation
  famt_model = m_famt,
  famt_summary = m_famt_sum,
  famt_robust = m_famt.robust,
  famt_vcov = m_famt.vcov,
  famt_df = m_famt.df,
  famt_f_stat = f_famt[1],
  famt_f_df = c(f_famt[2], f_famt[3]),
  famt_p_value = p_famt,
  famt_r_squared = m_famt_sum$r.squared,
  famt_predictions = famt_predictions
)
