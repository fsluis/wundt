#!/usr/bin/env Rscript
# Train the alternative complexity-model candidates reported in the supplementary
# comparison table of the paper.
#
# Input:  data/figshare/m9.figshare.25676394/wundt_v16_8-model-ridge-na_swe-windows.csv.gz
#         (public Figshare export of the EnSiWiki+Guardian feature matrix; includes
#         several snowball SWE window variants)
#         EnSiWiki rows: lang %in% c("english","simple"); Guardian target rows: lang = NA (18)
#
# FEATURE PINNING: all model feature sets come from analysis/feature_spec.R (sourced
# below) and are NEVER derived from the columns present in the file. Full models and
# XGBoost use exactly the 25 pinned PRIMARY_FEATURE_COLS; the pinned SWE_WOR_C1_COLS
# and LASSO_FEATURE_COLS sets are used only by their respective supplementary rows.
# Extra SWE-window columns in the export must not leak into full models.
# Output: data/candidates.rds (one row per candidate: classifier, family, hyperparams,
#         classif.acc, and Guardian-side metrics r_prob / R2 / beta_x / beta_x2)
#
# Pipeline design:
#   - mlr3 classification task on EnSiWiki, pair_id as group role (pairs kept together)
#   - complete-case filtering (applied per candidate, after feature selection),
#     class balancing by undersampling to 1:1, scaling
#   - set.seed(131) per candidate
#   - outer 3-fold CV resampling, msr("classif.acc") as the reported accuracy
#   - inner 5-fold tuning (AutoTuner grid search) where applicable (XGBoost)
#   - final model trained on the full EnSiWiki task, then probability prediction
#     for the 18 Guardian stimuli
#   - Guardian metrics: r_prob = cor(noco2, prob) at stimulus level;
#     R2 / standardized betas from lm(inte.x ~ poly(prob, 2)) + lm.beta
#
# Implementation notes:
#   - complete-case filtering is done before graph training (the task is built on
#     rows complete for the candidate's columns)
#   - installed mlr3learners declares a 'loglik' property unknown to the installed mlr3
#     core; registered via mlr_reflections so classif.log_reg constructs
#   - mlr3extralearners is not installed; random forest is run through
#     randomForest::randomForest directly (ntree = 500)
#   - modern glmnet requires >= 2 columns; single-column families get a duplicated column
#   - XGBoost inner tuning runs once on the full task

suppressPackageStartupMessages({
  library(mlr3); library(mlr3pipelines); library(mlr3learners); library(mlr3tuning)
  library(readr); library(dplyr); library(lm.beta); library(future)
})
# compatibility patch for mlr3/mlr3learners version skew (see header)
mlr_reflections$learner_properties$classif <- union(mlr_reflections$learner_properties$classif, "loglik")

# pinned feature sets (25 primary predictors + the supplementary pinned sets)
source("analysis/feature_spec.R")

setwd(getwd())
data_dir <- "data"
figshare_dir <- file.path(data_dir, "figshare", "m9.figshare.25676394")
feature_file <- file.path(figshare_dir, FIGSHARE_FEATURE_FILE)
guardian_file <- file.path(data_dir, "figshare", "m9.figshare.27057958", "guardian3.csv")
output_file <- file.path(data_dir, "candidates.rds")
if (!file.exists(feature_file)) stop("Feature matrix not found: ", feature_file,
                                      " (download the expanded export from m9.figshare.25676394)")

## ---------------- data ----------------
df <- as.data.frame(read_csv(feature_file, show_col_types = FALSE))
validate_feature_spec(colnames(df))  # pinned columns must all be present
en <- df[df$lang %in% c("english", "simple"), ]
gu <- df[is.na(df$lang), ]
feat_cols <- PRIMARY_FEATURE_COLS          # full models: exactly the pinned 25 (asserted in spec)
model_cols <- unique(c(feat_cols, SWE_WOR_C1_COLS, LASSO_FEATURE_COLS))  # extra windows only for their candidates
stopifnot(length(feat_cols) == 25L)
cat(sprintf("Feature matrix: %d rows total, %d EnSiWiki, %d Guardian; %d columns total\n",
            nrow(df), nrow(en), nrow(gu), ncol(df)))
cat(sprintf("Full-model feature set: pinned PRIMARY_FEATURE_COLS (%d predictors)\n", length(feat_cols)))
cat("  ", paste(feat_cols, collapse = ", "), "\n")

wiki <- en[, c("lang", model_cols, "pair_id")]
wiki$lang <- factor(wiki$lang)
# NOTE: complete-case filtering is applied per candidate, after feature selection;
# a global pre-filter here would wrongly drop rows for single-feature families.
cat(sprintf("EnSiWiki rows: %d; lang %s\n",
            nrow(wiki), paste(names(table(wiki$lang)), table(wiki$lang), collapse = "/")))
gu_df <- as.data.frame(gu[, model_cols])

# build a task on rows complete for the given columns (complete-case filter after select)
make_task <- function(cols, id) {
  w <- wiki[complete.cases(wiki[, cols]), c("lang", cols, "pair_id")]
  t <- as_task_classif(w, target = "lang", id = id)
  t$set_col_roles("pair_id", roles = "group")  # pairs kept together in CV folds
  t
}

## Guardian behavioral data (same derivation as 01_prepare_data.R, from guardian3.csv)
g3 <- read.csv(guardian_file, na.strings = c("", "NA"))
g3 <- g3[g3$familiarity_group != "", ]
for (v in 59:63) g3[[paste0("novelty_comprehension_scale_", v)]] <- -1 * g3[[paste0("novelty_comprehension_scale_", v)]] + 8
guardian_all <- data.frame(
  session = g3$session, stimulus = g3$stimulus,
  inte = (g3$novelty_comprehension_scale_63 + g3$novelty_comprehension_scale_64 + g3$interest_scale_67) / 3,
  noco2 = (g3$novelty_comprehension_scale_57 + g3$novelty_comprehension_scale_59) / -2 + 8
)
guardian_stimulus <- aggregate(guardian_all[, c("inte", "noco2")],
                               by = list(stimulus = guardian_all$stimulus), FUN = mean, na.rm = TRUE)

## ------- feature families: conceptual -> physical column mapping + one learner per family -------
# One specified model per feature family; there is NO per-family learner competition.
# Assignment: ridge for word_length, snowball (swe_wor), altlex, coref, esacoh, wordnet;
# log_reg for esa, loc, cc. The snowball (Word entropy IIIa) family uses the pinned
# SWE_WOR_C1_COLS from feature_spec.R.
families <- list(
  word_length = list(cl = "ridge",   cols = c("lucene_characters_per_word_mean", "lucene_syllables_per_word_mean")),
  snowball    = list(cl = "ridge",   cols = SWE_WOR_C1_COLS),
  esa         = list(cl = "log_reg", cols = "esa_swe_w30_mean"),
  loc         = list(cl = "log_reg", cols = "loc__cor2_f0_i0_log_mean_mean"),
  altlex      = list(cl = "ridge",   cols = c("causal_word_span_ratio", "noncausal_word_span_ratio")),
  coref       = list(cl = "ridge",   cols = grep("^coref_fwin_fill_local", feat_cols, value = TRUE)),
  esacoh      = list(cl = "ridge",   cols = grep("^esacoh_fwin_fill_local", feat_cols, value = TRUE)),
  cc          = list(cl = "log_reg", cols = "cc_sent_geo_log_p_mean"),
  wordnet     = list(cl = "ridge",   cols = grep("^wordnet_log_cumulative_spread", feat_cols, value = TRUE))
)
# duplicated column for 1-column families (modern glmnet needs >= 2 columns)
one_col <- names(families)[sapply(families, function(x) length(x$cols)) == 1]
for (f in one_col) {
  col <- families[[f]]$cols
  wiki[[paste0(col, "_dup")]] <- wiki[[col]]
  gu_df[[paste0(col, "_dup")]] <- gu_df[[col]]
}

## ---------------- candidate runner ----------------
guardian_metrics <- function(prob) {
  tgt <- merge(guardian_stimulus, data.frame(stimulus = gu$id, prob = prob), by = "stimulus")
  r_prob <- cor(tgt$noco2, tgt$prob)
  merged <- merge(guardian_all, tgt, by = "stimulus", all.x = TRUE)
  mb <- summary(lm.beta(lm(inte.x ~ poly(prob, 2), data = merged)))
  list(r_prob = r_prob, r2 = mb$r.squared,
       beta_x = mb$coefficients[2, "Standardized"], beta_x2 = mb$coefficients[3, "Standardized"])
}

make_graph <- function(learner) {
  po("classbalancing", id = "under", adjust = "major", reference = "minor",
     shuffle = FALSE, ratio = 1) %>>%   # undersample to 1:1
  po("scale", id = "scale") %>>%
  po("learner", id = "learner", learner = learner)
}

eval_and_predict <- function(feats, learner) {
  if (learner$id == "classif.cv_glmnet" && length(feats) == 1) feats <- c(feats, paste0(feats[1], "_dup"))
  subtask <- make_task(feats, "cand")
  set.seed(131)
  outer <- rsmp("cv", folds = 3)  # outer resampling
  outer$instantiate(subtask)
  gl <- as_learner(make_graph(learner))
  rr <- resample(subtask, gl, outer, store_models = FALSE)
  acc <- rr$aggregate(msr("classif.acc"))
  gl$train(subtask)               # final model on full EnSiWiki task
  gl$predict_type <- "prob"
  pred <- gl$predict_newdata(gu_df[, feats, drop = FALSE])  # 18 Guardian stimuli
  prob <- pred$prob[, "english"]
  c(list(acc = unname(acc)), guardian_metrics(prob))
}

# random forest: randomForest with ntree=500; mlr3extralearners is not installed,
# so folds are run directly (same preprocessing)
eval_rf <- function(feats) {
  subtask <- make_task(feats, "rf")
  set.seed(131)
  outer <- rsmp("cv", folds = 3); outer$instantiate(subtask)
  accs <- numeric(3)
  for (i in 1:3) {
    tr <- as.data.frame(subtask$filter(outer$train_set(i))$data(cols = c("lang", feats)))
    te <- as.data.frame(subtask$filter(outer$test_set(i))$data(cols = c("lang", feats)))
    tb <- table(tr$lang); minor <- names(which.min(tb)); maj <- setdiff(names(tb), minor)
    keep <- which(tr$lang == minor)
    if (length(maj) > 0) keep <- c(keep, which(tr$lang == maj)[seq_len(tb[minor])])
    tr <- tr[sort(keep), ]
    mu <- sapply(tr[, feats, drop = FALSE], mean); sds <- sapply(tr[, feats, drop = FALSE], sd)
    m <- randomForest::randomForest(x = scale(tr[, feats, drop = FALSE], mu, sds), y = factor(tr$lang), ntree = 500)
    p <- predict(m, newdata = scale(te[, feats, drop = FALSE], mu, sds), type = "prob")
    accs[i] <- mean(colnames(p)[max.col(p)] == as.character(te$lang))
  }
  tr <- as.data.frame(subtask$data(cols = c("lang", feats)))
  mu <- sapply(tr[, feats, drop = FALSE], mean); sds <- sapply(tr[, feats, drop = FALSE], sd)
  m <- randomForest::randomForest(x = scale(tr[, feats, drop = FALSE], mu, sds), y = factor(tr$lang), ntree = 500)
  pp <- predict(m, newdata = scale(gu_df[, feats, drop = FALSE], mu, sds), type = "prob")
  c(list(acc = mean(accs)), guardian_metrics(pp[, "english"]))
}

# XGBoost: outer grid over (alpha x lambda); inner 5-fold AutoTuner grid search over
# max_depth x eta x min_child_weight, tuned once on the full task
eval_xgb_outer <- function(a, l) {
  gl_base <- make_graph(lrn("classif.xgboost", alpha = a, lambda = l, nrounds = 1, nthread = 1, verbose = 0))
  subtask <- make_task(feat_cols, "xgb")
  set.seed(131)
  cv5 <- rsmp("cv", folds = 5)  # inner resampling
  ss <- ps(learner.max_depth = p_fct(c(2, 4, 6, 8, 10)),
           learner.eta = p_fct(c(.05, .1, .15, .2, .25)),
           learner.min_child_weight = p_fct(c(1, 3, 5)))
  at <- AutoTuner$new(learner = as_learner(gl_base), resampling = cv5,
                      measure = msr("classif.acc"), search_space = ss,
                      terminator = trm("none"), tuner = tnr("grid_search"))
  at$train(subtask)
  pv <- at$learner$param_set$values
  getp <- function(p) pv[[grep(paste0(p, "$"), names(pv))[1]]]
  tuned <- list(max_depth = getp("max_depth"), eta = getp("eta"), min_child_weight = getp("min_child_weight"))
  set.seed(131)
  outer <- rsmp("cv", folds = 3); outer$instantiate(subtask)
  gl <- as_learner(make_graph(lrn("classif.xgboost", alpha = a, lambda = l, nrounds = 1, nthread = 1, verbose = 0,
                                   max_depth = tuned$max_depth, eta = tuned$eta,
                                   min_child_weight = tuned$min_child_weight)))
  rr <- resample(subtask, gl, outer, store_models = FALSE)
  acc <- rr$aggregate(msr("classif.acc"))
  gl$train(subtask); gl$predict_type <- "prob"
  pred <- gl$predict_newdata(gu_df[, feat_cols, drop = FALSE])  # pinned 25 only
  c(list(acc = unname(acc)), guardian_metrics(pred$prob[, "english"]),
    max_depth = tuned$max_depth, eta = tuned$eta, mcw = tuned$min_child_weight)
}

## ---------------- run all candidates (single-feature families + full-feature models + XGBoost grid) ----------------
plan(multisession, workers = 6)  # parallelize inner tuning grids
results <- list()
cache_dir <- file.path(data_dir, ".cache06")
dir.create(cache_dir, showWarnings = FALSE)
add <- function(tag, family, classifier, res, extra = list()) {
  fp <- file.path(cache_dir, paste0(tag, ".rds"))
  if (file.exists(fp)) { results[[tag]] <<- readRDS(fp); cat("cached", tag, "\n"); return(invisible(NULL)) }
  if (is.null(res)) stop("no result for ", tag)
  row <- data.frame(candidate = tag, family = family, classifier = classifier,
                    classif.acc = res[["acc"]], r_prob = res[["r_prob"]],
                    r_squared_inte_poly_model = res[["r2"]],
                    beta_x = res[["beta_x"]], beta_x2 = res[["beta_x2"]],
                    xgb_alpha = NA_real_, xgb_lambda = NA_real_,
                    max_depth = NA, eta = NA, mcw = NA,
                    stringsAsFactors = FALSE)
  for (nm in names(extra)) row[[nm]] <- extra[[nm]]
  results[[tag]] <<- row
  saveRDS(row, fp)
  cat(sprintf("%-26s %-8s acc=%.4f com=%.4f R2=%.4f bx=%.4f bx2=%.4f\n",
              tag, classifier, row$classif.acc, row$r_prob, row$r_squared_inte_poly_model,
              row$beta_x, row$beta_x2))
}

t0 <- Sys.time()
# single-feature candidates: one specified model per family (no learner competition)
for (fam in names(families)) {
  spec <- families[[fam]]
  learner <- if (spec$cl == "ridge") lrn("classif.cv_glmnet", alpha = 0, parallel = FALSE) else lrn("classif.log_reg")
  add(paste0("sf_", fam), fam, spec$cl, eval_and_predict(spec$cols, learner))
}
add("full_ridge",  "all", "ridge",   eval_and_predict(feat_cols, lrn("classif.cv_glmnet", alpha = 0, parallel = FALSE)))
# full lasso uses the pinned w50 word-entropy window (LASSO_FEATURE_COLS);
# all other full models use the primary w55 pin
add("full_lasso",  "all", "lasso",   eval_and_predict(LASSO_FEATURE_COLS, lrn("classif.cv_glmnet", alpha = 1, parallel = FALSE)))
add("full_logreg", "all", "log_reg", eval_and_predict(feat_cols, lrn("classif.log_reg")))
add("full_rf",     "all", "rf",      eval_rf(feat_cols))
alpha_vals <- c(1e-5, 1e-2, 0.1, 1, 100)
lambda_vals <- c(1e-5, 1e-2, 0.1, 1, 100)
for (a in alpha_vals) for (l in lambda_vals) {
  tag <- sprintf("xgb_a%g_l%g", a, l)
  if (file.exists(file.path(cache_dir, paste0(tag, ".rds")))) { add(tag, "all", "xgboost", NULL); next }
  r <- eval_xgb_outer(a, l)
  add(tag, "all", "xgboost", r,
      extra = list(xgb_alpha = a, xgb_lambda = l,
                   max_depth = r$max_depth, eta = r$eta, mcw = r$mcw))
}
plan(sequential)

candidates <- do.call(rbind, results)
# record the pinned feature sets on the output for downstream verification
attr(candidates, "primary_feature_cols") <- PRIMARY_FEATURE_COLS
attr(candidates, "swe_wor_c1_cols") <- SWE_WOR_C1_COLS
attr(candidates, "lasso_feature_cols") <- LASSO_FEATURE_COLS
attr(candidates, "feature_file") <- FIGSHARE_FEATURE_FILE
cat(sprintf("\nTrained %d candidates in %.1f min\n", nrow(candidates),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
cat(sprintf("Full-model predictors used: %d (pinned); swe_wor C.1 columns: %s\n",
            length(attr(candidates, "primary_feature_cols")),
            paste(attr(candidates, "swe_wor_c1_cols"), collapse = ", ")))
saveRDS(candidates, output_file)
cat("Saved to:", output_file, "\n")
