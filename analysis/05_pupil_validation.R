# Wundt–Berlyne Paper: Pupil Dilation Validation
#
# Purpose: Reproduce the pupil validation result reported in the manuscript:
#   Association between baseline-corrected pupil dilation and subjective ratings
#
# Data: guardian3.csv (public Figshare m9.figshare.27057958) already contains the
#   per-trial baseline-corrected pupil diameter (`pupil_corrected`) merged by
#   participant (anonymized `session`) and article (`stimulus`), so no raw
#   eye-tracking export or private session mapping is required.
#
# Dependencies:
# - data/figshare/m9.figshare.27057958/guardian3.csv
# - data/guardian_all_prepared.rds (from 01_prepare_data.R)
# - data/models/target_results.rds (reported model predictions used in the paper)

# Load public Guardian experiment data with pupil measures
guardian_raw <- read.csv(
  "data/figshare/m9.figshare.27057958/guardian3.csv",
  sep = ",",
  header = TRUE,
  na.strings = c("", "NA")
)

# Load prepared Guardian data (derived subjective variables) and merge by
# anonymized participant ID + stimulus
guardian_all <- readRDS("data/guardian_all_prepared.rds")
merged_pupil <- merge(
  guardian_all,
  guardian_raw[, c("session", "stimulus", "pupil_diameter", "pupil_corrected")],
  by = c("session", "stimulus"),
  all.x = TRUE
)

# Load the reported ridge model predictions (objective complexity, prob)
target_results <- readRDS("data/models/target_results.rds")
merged_pupil <- merge(merged_pupil, target_results, by = "stimulus", all.x = TRUE)

# ============================================================================
# MAIN PUPIL VALIDATION RESULT
# ============================================================================
# The manuscript reports pupil dilation correlations with:
# - interest (inte)
# - comprehensibility (comp)
# - subjective complexity (noco2)
# (objective complexity prob is computed for completeness)

pupil_inte_cor <- cor.test(
  merged_pupil$pupil_corrected,
  merged_pupil$inte.x,
  method = "pearson"
)

pupil_comp_cor <- cor.test(
  merged_pupil$pupil_corrected,
  merged_pupil$comp.x,
  method = "pearson"
)

pupil_noco2_cor <- cor.test(
  merged_pupil$pupil_corrected,
  merged_pupil$noco2.x,
  method = "pearson"
)

pupil_prob_cor <- cor.test(
  merged_pupil$pupil_corrected,
  merged_pupil$prob,
  method = "pearson"
)

# Report results
cat("\n=== Pupil Dilation Validation ===\n")
cat("Baseline-corrected pupil dilation (pupil_corrected) correlations:\n\n")

cat("Pupil dilation vs Interest (inte):\n")
cat(sprintf("r = %.3f, t(%d) = %.2f, p = %s\n",
            pupil_inte_cor$estimate,
            pupil_inte_cor$parameter,
            abs(pupil_inte_cor$statistic),
            format(pupil_inte_cor$p.value, digits = 4)))

cat("\nPupil dilation vs Comprehensibility (comp):\n")
cat(sprintf("r = %.3f, t(%d) = %.2f, p = %s\n",
            pupil_comp_cor$estimate,
            pupil_comp_cor$parameter,
            abs(pupil_comp_cor$statistic),
            format(pupil_comp_cor$p.value, digits = 4)))

cat("\nPupil dilation vs Subjective Complexity (noco2):\n")
cat(sprintf("r = %.3f, t(%d) = %.2f, p = %s\n",
            pupil_noco2_cor$estimate,
            pupil_noco2_cor$parameter,
            abs(pupil_noco2_cor$statistic),
            format(pupil_noco2_cor$p.value, digits = 4)))

cat("\nPupil dilation vs Objective Complexity (prob):\n")
cat(sprintf("r = %.3f, t(%d) = %.2f, p = %s\n",
            pupil_prob_cor$estimate,
            pupil_prob_cor$parameter,
            abs(pupil_prob_cor$statistic),
            format(pupil_prob_cor$p.value, digits = 4)))

# ============================================================================
# Return results
# ============================================================================

list(
  pupil_inte_correlation = pupil_inte_cor,
  pupil_comp_correlation = pupil_comp_cor,
  pupil_noco2_correlation = pupil_noco2_cor,
  pupil_prob_correlation = pupil_prob_cor,
  merged_pupil = merged_pupil
)
