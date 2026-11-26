# Wundt–Berlyne Paper: Data Preparation
# 
# Purpose: Prepare Guardian experiment data for all subsequent analyses.
#
# This script loads the public Guardian experiment data and derives the
# variables required for the paper's analyses. It does NOT include:
# - Model training
# - Feature extraction
# - Plotting

# Load Guardian experiment data from the public guardian3.csv file
# (public Figshare deposit m9.figshare.27057958;
#  includes the anonymized participant IDs in `session`)
guardian_raw <- read.csv(
  "data/figshare/m9.figshare.27057958/guardian3.csv",
  sep = ",",
  header = TRUE,
  na.strings = c("", "NA")
)

# The `session` column in guardian3.csv is the anonymized participant identifier
# used for participant-level clustering in the clustered LMs

# Remove non-article rows (welcome screens, instructions, etc.)
guardian_raw <- guardian_raw[guardian_raw$familiarity_group != "", ]

# Invert scales so that higher values indicate greater difficulty/interest
# These transformations ensure: left = 'easy to read', right = 'difficult to read'
# guardian3.csv stores the raw (non-inverted) scale values, so the inversion
# below is required to obtain the analysis orientation
guardian_raw$novelty_comprehension_scale_59 <- -1 * guardian_raw$novelty_comprehension_scale_59 + 8
guardian_raw$novelty_comprehension_scale_60 <- -1 * guardian_raw$novelty_comprehension_scale_60 + 8
guardian_raw$novelty_comprehension_scale_61 <- -1 * guardian_raw$novelty_comprehension_scale_61 + 8
guardian_raw$novelty_comprehension_scale_62 <- -1 * guardian_raw$novelty_comprehension_scale_62 + 8
guardian_raw$novelty_comprehension_scale_63 <- -1 * guardian_raw$novelty_comprehension_scale_63 + 8

# Remove missing values in key variables
guardian_all <- data.frame(
  session = guardian_raw$session,  # Anonymized participant ID
  stimulus = guardian_raw$stimulus,
  condition = guardian_raw$familiarity_group,  # Renamed from condition to familiarity_group
  gender = NA,  # Not available in public guardian3.csv
  # Interest: average of three interest ratings
  inte = (guardian_raw$novelty_comprehension_scale_63 + 
          guardian_raw$novelty_comprehension_scale_64 + 
          guardian_raw$interest_scale_67) / 3,
  # Reading ease: average of two readability ratings
  read = (guardian_raw$novelty_comprehension_scale_57 + 
          guardian_raw$novelty_comprehension_scale_59) / 2,
  # Negative complexity (inverted readability)
  noco2 = (guardian_raw$novelty_comprehension_scale_57 + 
           guardian_raw$novelty_comprehension_scale_59) / -2 + 8,
  # Topical familiarity (single item)
  fama = guardian_raw$novelty_comprehension_scale_58,
  # Topical familiarity (alternative measure)
  famt = guardian_raw$topical_familiarity,
  # Combined familiarity measure - handle NAs in fam_answer columns
  fam = apply(guardian_raw[, c("fam_answer_1", "fam_answer_2", "fam_answer_3", 
                               "novelty_comprehension_scale_58")], 1, function(x) mean(x, na.rm = TRUE)),
  position = NA,  # Not available in public guardian3.csv
  # Comprehensibility: average of three comprehension ratings
  comp = (guardian_raw$novelty_comprehension_scale_60 + 
          guardian_raw$novelty_comprehension_scale_61 + 
          guardian_raw$novelty_comprehension_scale_62) / 3,
  # Processing fluency: average of five readability-related ratings
  pf = (guardian_raw$novelty_comprehension_scale_57 + 
        guardian_raw$novelty_comprehension_scale_59 + 
        guardian_raw$novelty_comprehension_scale_60 + 
        guardian_raw$novelty_comprehension_scale_61 + 
        guardian_raw$novelty_comprehension_scale_62) / 5,
  stringsAsFactors = FALSE
)

# Remove rows with NA values in critical variables (not position or gender)
critical_cols <- c("session", "stimulus", "condition", "inte", "read", 
                   "noco2", "fama", "famt", "fam", "comp", "pf")
guardian_all <- guardian_all[, critical_cols]
guardian_all <- na.omit(guardian_all)

# Add condition_position column (1-6 within each condition per session)
# Note: guardian3.csv uses "median" instead of "misc"
guardian_all$condition_position <- NA  # Initialize
for (i in unique(guardian_all$session)) {
  for (j in c("low", "high", "median")) {  # Using "median" for guardian3.csv
    idx <- which(guardian_all$session == i & guardian_all$condition == j)
    if (length(idx) > 0) {
      guardian_all$condition_position[idx] <- 1:length(idx)
    }
  }
}

# Note: EC variables are NOT required for the final reported SEM
# and are not available in the public guardian3.csv dataset
# Session-level aggregation for participant clustering is handled by the anonymized session ID

# Aggregate stimulus-level data
guardian_stimulus <- aggregate(
  guardian_all[, c("inte", "read", "noco2", "fama", "famt", "fam", "comp", "pf")],
  by = list(stimulus = guardian_all$stimulus),
  FUN = mean,
  na.rm = TRUE
)

# Note: Objective complexity (prob) is added from the model predictions
# (data/models/target_results.rds) in the subsequent analysis scripts.

# Save prepared data for use by other scripts
# For reproducibility, we save them here.
saveRDS(guardian_all, "data/guardian_all_prepared.rds")
saveRDS(guardian_stimulus, "data/guardian_stimulus_prepared.rds")

# Return prepared data objects for use in downstream analyses
# (In interactive use, these would be loaded from the .rds files above)
list(
  guardian_all = guardian_all,
  guardian_stimulus = guardian_stimulus
)