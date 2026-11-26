# Pinned feature specification — shared by 06 and 08 (single source; do not duplicate).
#
# Model feature sets are pinned explicitly below and are NEVER derived from the
# columns present in the input file, so extra columns in a data export can never
# silently leak into a model.

# Feature-matrix export used by 06/08 (public Figshare deposit m9.figshare.25676394).
# The export contains several snowball SWE window variants
# (w45/w50/w55/w60/w65 x n1-n5) so that the pinned configurations below can be
# selected explicitly.
FIGSHARE_FEATURE_FILE <- "wundt_v16_8-model-ridge-na_swe-windows.csv.gz"

# Non-feature (metadata/label) columns of the export.
FIGSHARE_ID_COLS <- c("pair_id", "lang", "label", "id")

# The 25 predictors of the primary (full) model, used by all full-feature models in
# 06 (ridge / lasso / log_reg / random forest / XGBoost) and by the ridge re-fit in 08.
# Word-entropy part: snowball SWE window m=55, n-grams 1-5.
# Semantic-entropy part: ESA SWE window m=30.
PRIMARY_FEATURE_COLS <- c(
  "causal_word_span_ratio",
  "cc_sent_geo_log_p_mean",
  "coref_fwin_fill_local_1_mean",
  "coref_fwin_fill_local_2_mean",
  "coref_fwin_fill_local_3_mean",
  "coref_fwin_fill_local_4_mean",
  "esa_swe_w30_mean",
  "esacoh_fwin_fill_local_1_mean",
  "esacoh_fwin_fill_local_2_mean",
  "esacoh_fwin_fill_local_3_mean",
  "esacoh_fwin_fill_local_4_mean",
  "loc__cor2_f0_i0_log_mean_mean",
  "lucene_characters_per_word_mean",
  "lucene_syllables_per_word_mean",
  "noncausal_word_span_ratio",
  "snowball_swe_w55_n1_mean",
  "snowball_swe_w55_n2_mean",
  "snowball_swe_w55_n3_mean",
  "snowball_swe_w55_n4_mean",
  "snowball_swe_w55_n5_mean",
  "wordnet_log_cumulative_spread_1_posall_stonge_mean",
  "wordnet_log_cumulative_spread_2_posall_stonge_mean",
  "wordnet_log_cumulative_spread_3_posall_stonge_mean",
  "wordnet_log_cumulative_spread_4_posall_stonge_mean",
  "wordnet_log_cumulative_spread_5_posall_stonge_mean"
)

# Feature columns for the supplementary single-feature Word entropy (IIIa) model:
# snowball SWE window m=65, n-grams 1-5.
SWE_WOR_C1_COLS <- paste0("snowball_swe_w65_n", 1:5, "_mean")

# Feature columns for the supplementary full-feature Lasso model: the primary 25,
# but with the word-entropy window m=50.
LASSO_FEATURE_COLS <- sub("^snowball_swe_w55_", "snowball_swe_w50_", PRIMARY_FEATURE_COLS)

# Invariants, enforced at source time:
stopifnot(length(PRIMARY_FEATURE_COLS) == 25L)
stopifnot(all(paste0("snowball_swe_w55_n", 1:5, "_mean") %in% PRIMARY_FEATURE_COLS))
stopifnot("esa_swe_w30_mean" %in% PRIMARY_FEATURE_COLS)
stopifnot(length(grep("^snowball_swe_w(45|50|60|65)_", PRIMARY_FEATURE_COLS)) == 0L)
stopifnot(length(SWE_WOR_C1_COLS) == 5L)
stopifnot(length(LASSO_FEATURE_COLS) == 25L)
stopifnot(all(paste0("snowball_swe_w50_n", 1:5, "_mean") %in% LASSO_FEATURE_COLS))
stopifnot(length(grep("^snowball_swe_w(45|55|60|65)_", LASSO_FEATURE_COLS)) == 0L)

# Validate the spec against the columns actually present in a loaded export.
validate_feature_spec <- function(available_cols) {
  missing <- setdiff(c(PRIMARY_FEATURE_COLS, SWE_WOR_C1_COLS, LASSO_FEATURE_COLS), available_cols)
  if (length(missing) > 0) {
    stop("Feature matrix is missing required pinned columns (download the expanded ",
         "export '", FIGSHARE_FEATURE_FILE, "' from m9.figshare.25676394). Missing: ",
         paste(missing, collapse = ", "))
  }
  invisible(TRUE)
}
