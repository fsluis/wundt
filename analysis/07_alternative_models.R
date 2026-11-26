#!/usr/bin/env Rscript
# Assemble the supplementary comparison table of alternative complexity models
# (the table reported in the paper's supplement).
#
# Consumes the candidates trained by 06_train_alternative_models.R
# (data/candidates.rds; per candidate: classif.acc and Guardian-side metrics) and
# applies the selection rules:
#   - per feature family: the ONE specified model (candidate sf_<family> from 06;
#     no per-family learner competition)
#   - full-feature rows: ridge, lasso, log_reg, random forest
#   - XGBoost: best of the outer (alpha x lambda) candidates by classif.acc
#   - plus subjective, inter-subjective, and Vec2Read rows
# All Guardian-side columns (Com, R^2, beta_x, beta_x^2) are filled; no NAs.
#
# Vec2Read: EnSiWiki classification accuracy is computed from
#   data/vec2read/best_epoch_99_pred.tsv (accuracy: table(y, round(siwiki)));
#   Guardian-side metrics from data/vec2read/target_pred_99.tsv (epoch 99 = best epoch).
#
# Output: data/table_c1_selected.rds

suppressPackageStartupMessages({
  library(dplyr)
  library(lm.beta)
})

data_dir <- "data"
candidates <- readRDS(file.path(data_dir, "candidates.rds"))
cat(sprintf("Loaded %d candidates\n", nrow(candidates)))
guardian_all <- readRDS(file.path(data_dir, "guardian_all_prepared.rds"))
guardian_stimulus <- readRDS(file.path(data_dir, "guardian_stimulus_prepared.rds"))

## ---------- learned-model rows from 06 candidates ----------
families <- c(word_length = "Word length (I)", snowball = "Word entropy (IIIa)",
              esa = "Semantic entropy (IIIb)", loc = "Dependency length (IV)",
              altlex = "Connectives (VII)", coref = "Referential cohesion (VIa)",
              esacoh = "Semantic cohesion (VIb)", cc = "Word probability (V)",
              wordnet = "Semantic neighborhood density (II)")
mkrow <- function(cand, label) {
  data.frame(label = label, classifier = cand$classifier, family = cand$family,
             classif.acc = cand$classif.acc, r_prob = cand$r_prob,
             r_squared_inte_poly_model = cand$r_squared_inte_poly_model,
             beta_x = cand$beta_x, beta_x2 = cand$beta_x2,
             xgb_alpha = NA_real_, xgb_lambda = NA_real_,
             stringsAsFactors = FALSE)
}
rows <- list()
# feature-family rows: one specified model per family (candidate tag sf_<family> from 06)
for (fam in names(families)) {
  w <- candidates[candidates$candidate == paste0("sf_", fam), ][1, ]
  rows[[fam]] <- mkrow(w, families[[fam]])
  cat(sprintf("  %-12s model=%-8s acc=%.4f\n", fam, w$classifier, w$classif.acc))
}
# full-feature rows
for (tag in c("full_ridge", "full_lasso", "full_logreg", "full_rf")) {
  w <- candidates[candidates$candidate == tag, ][1, ]
  lbl <- c(full_ridge = "Ridge regression", full_lasso = "Lasso regression",
           full_logreg = "Regression", full_rf = "Random Forest")[[tag]]
  rows[[tag]] <- mkrow(w, lbl)
}
# XGBoost winner among the outer candidates
xg <- candidates[candidates$classifier == "xgboost", ]
w <- xg[which.max(xg$classif.acc), ]
wx <- mkrow(w, "XGBoost")
wx$xgb_alpha <- w$xgb_alpha; wx$xgb_lambda <- w$xgb_lambda
rows[["xgb"]] <- wx
cat(sprintf("  XGBoost winner: alpha=%g lambda=%g acc=%.4f\n", w$xgb_alpha, w$xgb_lambda, w$classif.acc))

## ---------- subjective / inter-subjective rows (same quadratic LM on prob as the learned models) ----------
merged <- merge(guardian_all, guardian_stimulus, by = "stimulus", all.x = TRUE)
merged$prob <- merged$noco2.y  # inter-subjective (stimulus-level)
m <- summary(lm.beta(lm(inte.x ~ poly(prob, 2), data = merged)))
rows[["inter"]] <- data.frame(label = "Inter-subjective complexity", classifier = "average subjective",
  family = "subjective", classif.acc = NA, r_prob = 1, r_squared_inte_poly_model = m$r.squared,
  beta_x = m$coefficients[2, "Standardized"], beta_x2 = m$coefficients[3, "Standardized"],
  xgb_alpha = NA_real_, xgb_lambda = NA_real_, stringsAsFactors = FALSE)
merged$prob <- merged$noco2.x  # subjective (session-level)
m <- summary(lm.beta(lm(inte.x ~ poly(prob, 2), data = merged)))
rows[["subj"]] <- data.frame(label = "Subjective complexity", classifier = "subjective",
  family = "subjective", classif.acc = NA, r_prob = cor(merged$prob, merged$noco2.y),
  r_squared_inte_poly_model = m$r.squared,
  beta_x = m$coefficients[2, "Standardized"], beta_x2 = m$coefficients[3, "Standardized"],
  xgb_alpha = NA_real_, xgb_lambda = NA_real_, stringsAsFactors = FALSE)

## ---------- Vec2Read row ----------
# EnSiWiki classification accuracy from the epoch-99 test-set predictions
best <- read.table(file.path(data_dir, "vec2read", "best_epoch_99_pred.tsv"), sep = "\t", header = TRUE)
t <- table(best$y, round(best$siwiki))
vec2read_acc <- (t[1, 1] + t[2, 2]) / sum(t)   # classification accuracy
cat(sprintf("  Vec2Read EnSiWiki acc = %.6f (%.2f%%)\n", vec2read_acc, vec2read_acc * 100))
# Guardian-side metrics from the epoch-99 target predictions
vt <- read.table(file.path(data_dir, "vec2read", "target_pred_99.tsv"), sep = "\t", header = TRUE)
vt <- vt[, setdiff(colnames(vt), "siwiki")]
vt <- merge(guardian_stimulus, vt, by.x = "stimulus", by.y = "label")
vt$prob <- vt$enwiki * -1 + 1  # vec2read predicts readability; prob = 1 - p
vec2read_com <- cor(vt$prob, vt$noco2)
va <- merge(guardian_all, vt, by.x = "stimulus", by.y = "stimulus")
va$prob <- va$enwiki * -1 + 1
mb <- summary(lm.beta(lm(inte.x ~ poly(prob, 2), data = va)))
rows[["vec2read"]] <- data.frame(label = "Vec2Read", classifier = "vec2read", family = "vec2read",
  classif.acc = vec2read_acc, r_prob = vec2read_com, r_squared_inte_poly_model = mb$r.squared,
  beta_x = mb$coefficients[2, "Standardized"], beta_x2 = mb$coefficients[3, "Standardized"],
  xgb_alpha = NA_real_, xgb_lambda = NA_real_, stringsAsFactors = FALSE)

## ---------- assemble ----------
table_c1 <- do.call(rbind, rows)
table_c1 <- table_c1[, c("label", "classifier", "family", "classif.acc", "r_prob",
                         "r_squared_inte_poly_model", "beta_x", "beta_x2",
                         setdiff(colnames(table_c1), c("label", "classifier", "family", "classif.acc",
                                                       "r_prob", "r_squared_inte_poly_model", "beta_x", "beta_x2")))]
cat(sprintf("\nTable C.1: %d rows\n", nrow(table_c1)))
print(as.data.frame(table_c1), digits = 4)
cat(sprintf("NA Guardian cells: %d\n", sum(is.na(table_c1[, c("r_prob", "r_squared_inte_poly_model", "beta_x", "beta_x2")]))))
saveRDS(table_c1, file.path(data_dir, "table_c1_selected.rds"))
cat("Saved to: data/table_c1_selected.rds\n")
