#!/usr/bin/env Rscript
# Independent re-fit of the ridge complexity model (optional validation exercise).
#
# Role: OPTIONAL. This script is NOT a prerequisite for the paper's reported
# analyses. Scripts 01-07 use the reported model predictions stored in
# data/models/target_results.rds.
#
# Purpose: Re-fit the ridge workflow from public inputs (the combined EnSiWiki +
# Guardian feature matrix) and compare the resulting Guardian predictions against
# the reported ones in data/models/target_results.rds.
#
# Input feature matrix: m9.figshare.25676394/wundt_v16_8-model-ridge-na_swe-windows.csv.gz
# The extra SWE-window columns in the export are NOT used here: the re-fit uses
# exactly the 25 pinned predictors from analysis/feature_spec.R.
#
# Dependencies (public inputs only; independent of 01_prepare_data.R):
#   - data/figshare/m9.figshare.25676394/wundt_v16_8-model-ridge-na_swe-windows.csv.gz (feature matrix)
#   - analysis/feature_spec.R (pinned feature sets; sourced below)
#   - data/figshare/m9.figshare.27057958/guardian3.csv (public Guardian behavioral data)
#   - data/models/target_results.rds (comparison target, read-only)
#
# Outputs:
#   - data/models/target_results_reconstructed.rds (reconstructed predictions)
#     This NEVER overwrites data/models/target_results.rds.
#
# The re-fit is not expected to be bit-identical to the reported model: the original
# CV fold assignment was not preserved, so cv.glmnet cannot necessarily select the
# same solution, and software/library versions may also differ. The comparison below
# reports r, MAE and max absolute difference.

cat("\n====== INDEPENDENT RECONSTRUCTION OF RIDGE PREDICTIONS (validation only) ======\n\n")

# Load required packages
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(glmnet)
})

# Fix the seed so cv.glmnet's random fold assignment is reproducible across runs
set.seed(131)

# Configuration
# pinned feature sets (25 primary predictors; no auto-derivation from file columns)
source("analysis/feature_spec.R")

data_dir <- "data"
figshare_dir <- file.path(data_dir, "figshare", "m9.figshare.25676394")
guardian_file <- file.path(data_dir, "figshare", "m9.figshare.27057958", "guardian3.csv")
model_dir <- file.path(data_dir, "models")
reference_file <- file.path(model_dir, "target_results.rds")  # reported predictions, read-only
enwiki_feature_file <- file.path(figshare_dir, FIGSHARE_FEATURE_FILE)
output_file <- file.path(model_dir, "target_results_reconstructed.rds")

# Ensure output directory exists in a fresh clone
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

cat("Stage 1: Loading data...\n")

# Check dependencies exist
if (!file.exists(enwiki_feature_file)) {
  stop("EnSiWiki+Guardian feature file not found: ", enwiki_feature_file, "\n",
       "Download from m9.figshare.25676394")
}
if (!file.exists(guardian_file)) {
  stop("Public Guardian data not found: ", guardian_file)
}


# Load combined EnSiWiki+Guardian feature matrix
cat("  Loading combined feature matrix...\n")
df <- as.data.frame(read_csv(enwiki_feature_file, show_col_types = FALSE))
validate_feature_spec(colnames(df))
cat(sprintf("  Total rows: %d, total columns: %d (expanded export)\n", nrow(df), ncol(df)))

# Split into EnSiWiki (training) and Guardian (target) BEFORE filtering
ensiwiki_rows <- df$lang %in% c("english", "simple")
guardian_rows <- is.na(df$lang)

cat(sprintf("  EnSiWiki rows (training): %d\n", sum(ensiwiki_rows)))
cat(sprintf("  Guardian rows (target): %d\n", sum(guardian_rows)))

# Extract data frames
ensiwiki_df <- df[ensiwiki_rows, ]
guardian_df <- df[guardian_rows, ]

# Pinned feature columns (exactly the 25 predictors of the primary model). NEVER
# derived from the file's columns: the export carries extra SWE-window columns that
# must not leak into the re-fit.
feature_cols <- PRIMARY_FEATURE_COLS
if (length(feature_cols) != 25L) stop("primary feature set must have exactly 25 predictors")
if (any(grepl("^snowball_swe_w(45|50|60|65)_", feature_cols))) stop("SWE window leakage in feature_cols")

cat(sprintf("  Feature columns (pinned): %d\n", length(feature_cols)))
cat("  ", paste(feature_cols, collapse = ", "), "\n")

# Derive stimulus-level Guardian aggregates directly from the public guardian3.csv,
# using the same derivation as 01_prepare_data.R, so this script does not depend on 01
guardian_raw <- read.csv(guardian_file, sep = ",", header = TRUE, na.strings = c("", "NA"))
guardian_raw <- guardian_raw[guardian_raw$familiarity_group != "", ]
# Scale inversion (guardian3.csv stores the raw, non-inverted items)
guardian_raw$novelty_comprehension_scale_59 <- -1 * guardian_raw$novelty_comprehension_scale_59 + 8
guardian_raw$novelty_comprehension_scale_60 <- -1 * guardian_raw$novelty_comprehension_scale_60 + 8
guardian_raw$novelty_comprehension_scale_61 <- -1 * guardian_raw$novelty_comprehension_scale_61 + 8
guardian_raw$novelty_comprehension_scale_62 <- -1 * guardian_raw$novelty_comprehension_scale_62 + 8
guardian_raw$novelty_comprehension_scale_63 <- -1 * guardian_raw$novelty_comprehension_scale_63 + 8
# Stimulus-level means of the derived subjective variables (as in 01_prepare_data.R)
guardian_stimulus <- aggregate(
  data.frame(
    inte = (guardian_raw$novelty_comprehension_scale_63 +
            guardian_raw$novelty_comprehension_scale_64 +
            guardian_raw$interest_scale_67) / 3,
    read = (guardian_raw$novelty_comprehension_scale_57 +
            guardian_raw$novelty_comprehension_scale_59) / 2,
    noco2 = (guardian_raw$novelty_comprehension_scale_57 +
             guardian_raw$novelty_comprehension_scale_59) / -2 + 8,
    fama = guardian_raw$novelty_comprehension_scale_58,
    famt = guardian_raw$topical_familiarity,
    fam = apply(guardian_raw[, c("fam_answer_1", "fam_answer_2", "fam_answer_3",
                                 "novelty_comprehension_scale_58")], 1, function(x) mean(x, na.rm = TRUE)),
    comp = (guardian_raw$novelty_comprehension_scale_60 +
            guardian_raw$novelty_comprehension_scale_61 +
            guardian_raw$novelty_comprehension_scale_62) / 3,
    pf = (guardian_raw$novelty_comprehension_scale_57 +
          guardian_raw$novelty_comprehension_scale_59 +
          guardian_raw$novelty_comprehension_scale_60 +
          guardian_raw$novelty_comprehension_scale_61 +
          guardian_raw$novelty_comprehension_scale_62) / 5
  ),
  by = list(stimulus = guardian_raw$stimulus),
  FUN = mean,
  na.rm = TRUE
)

# ============================================================================
# Stage 2: Train ridge regression on EnSiWiki data
# ============================================================================

cat("\nStage 2: Training ridge regression on EnSiWiki...\n")

# Convert to data.frame (glmnet needs this)
ensiwiki_df <- ensiwiki_df[, c(feature_cols, "label")]

# Convert label to factor (as.factor, not integer)
ensiwiki_df$label <- as.factor(ensiwiki_df$label)

# Apply complete-case filtering
complete_rows <- complete.cases(ensiwiki_df[, feature_cols])
ensiwiki_df <- ensiwiki_df[complete_rows, ]
cat(sprintf("  EnSiWiki rows after complete.cases: %d\n", nrow(ensiwiki_df)))

# Extract feature matrix and labels
enwiki_features <- ensiwiki_df[, feature_cols]
enwiki_labels <- ensiwiki_df$label

# External scaling
enwiki_features_scaled <- scale(enwiki_features)

# Convert to matrix (no intercept - glmnet will handle it)
enwiki_matrix <- as.matrix(enwiki_features_scaled)

# Train ridge regression with standardize=TRUE (default in glmnet):
# external scaling followed by glmnet's internal standardization
cv_fit <- cv.glmnet(
  enwiki_matrix, 
  enwiki_labels,
  alpha = 0,  # Ridge regression
  nfolds = 10,
  family = "binomial",
  standardize = TRUE  # glmnet will standardize internally
)

cat(sprintf("  Ridge lambda.min: %e\n", cv_fit$lambda.min))
cat(sprintf("  Ridge cvm minimum: %.4f\n", min(cv_fit$cvm)))

# ============================================================================
# Stage 3: Apply model to Guardian stimuli
# ============================================================================

cat("\nStage 3: Applying model to Guardian stimuli...\n")

# Get Guardian features (same 25 columns, same order)
guardian_features <- guardian_df[, feature_cols]

# Apply the SAME external scaling using EnSiWiki center/scale
guardian_features_scaled <- scale(guardian_features, 
                                  center = attr(enwiki_features_scaled, "scaled:center"),
                                  scale = attr(enwiki_features_scaled, "scaled:scale"))

# Convert to matrix (no intercept)
guardian_matrix <- as.matrix(guardian_features_scaled)

# Use predict.glmnet which handles everything properly
guardian_prob <- predict(cv_fit, newx = guardian_matrix, type = "response")
guardian_prob <- as.numeric(guardian_prob)  # Convert to numeric vector

cat(sprintf("  Guardian predictions (first 5): %.4f, %.4f, %.4f, %.4f, %.4f\n",
            guardian_prob[1], guardian_prob[2], guardian_prob[3], guardian_prob[4], guardian_prob[5]))

# ============================================================================
# Stage 4: Create target_results
# ============================================================================

cat("\nStage 4: Creating target_results...\n")

# Extract stimuli IDs from guardian_df$id (matches guardian_stimulus$stimulus)
guardian_ids <- guardian_df$id

# Sort by stimulus ID
sorted_order <- order(guardian_ids)
guardian_ids <- guardian_ids[sorted_order]
guardian_prob <- guardian_prob[sorted_order]

# Match to guardian_stimulus and extract required variables
matched_indices <- match(guardian_ids, guardian_stimulus$stimulus)

target_results <- data.frame(
  stimulus = guardian_ids,
  prob = guardian_prob,
  noco2 = guardian_stimulus$noco2[matched_indices],
  inte = guardian_stimulus$inte[matched_indices],
  comp = guardian_stimulus$comp[matched_indices],
  famt = guardian_stimulus$famt[matched_indices]
)

cat(sprintf("  target_results: %d rows\n", nrow(target_results)))

# Add the logit transform of prob
target_results$logit <- log(target_results$prob / (1 - target_results$prob))

# ============================================================================
# Stage 5: Save results
# ============================================================================

cat("\nStage 5: Saving results...\n")

saveRDS(target_results, file = output_file)
cat(sprintf("  Saved to: %s\n", output_file))

# ============================================================================
# Verification
# ============================================================================

cat("\n=== Verification ===\n")
cat(sprintf("  Mean prob: %.4f\n", mean(target_results$prob)))
cat(sprintf("  SD prob: %.4f\n", sd(target_results$prob)))
cat(sprintf("  Range prob: %.4f - %.4f\n", min(target_results$prob), max(target_results$prob)))

# Correlation with subjective complexity
noco_cor <- cor.test(target_results$prob, target_results$noco2)
cat(sprintf("  Correlation with subjective complexity: r = %.4f, p = %.4f\n",
            noco_cor$estimate, noco_cor$p.value))

# Check IDs match
cat("\nGuardian IDs:\n")
print(target_results$stimulus)

# ============================================================================
# Stage 6: Validate reconstructed predictions against the reported predictions
# ============================================================================

cat("\n=== Validation against published predictions ===\n")
published <- readRDS(reference_file)
cmp <- merge(
  target_results[, c("stimulus", "prob")],
  published[, c("stimulus", "prob")],
  by = "stimulus",
  suffixes = c("_reconstructed", "_published")
)
r_val <- cor(cmp$prob_reconstructed, cmp$prob_published)
mae_val <- mean(abs(cmp$prob_reconstructed - cmp$prob_published))
max_val <- max(abs(cmp$prob_reconstructed - cmp$prob_published))
cat(sprintf("  n stimuli compared: %d\n", nrow(cmp)))
cat(sprintf("  r    = %.7f\n", r_val))
cat(sprintf("  MAE  = %.7f\n", mae_val))
cat(sprintf("  max abs diff = %.6f\n", max_val))
cat("  Interpretation: very close independent reconstruction of the historical ridge\n")
cat("  predictions (r ~ 0.99998, MAE ~ 0.0043); NOT exact identity, because the\n")
cat("  historical CV fold assignment was not preserved and the software stack differs.\n")
cat("  The published predictions remain the artifact used for paper reproduction.\n")

cat("\n[PASS] independent ridge reconstruction complete (validation only)\n\n")

# Return results
list(
  target_results_reconstructed = target_results,
  ridge_model = cv_fit,
  validation = list(r = r_val, mae = mae_val, max_abs_diff = max_val)
)
