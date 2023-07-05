

# R < train_model.R --vanilla

library('DBI')
library("RMySQL")
drv = dbDriver("MySQL")
library(foreach)
library(glmnet)
library(glmnetUtils)
library("dplyr")
library(purrr)
library(tidyr) # unnesting

con = dbConnect(
  drv,
  user = "wundt",
  dbname = "com1_ensiwiki-2020_agerank",
  host = "localhost",
  password = "PaSSWoRD"
)

# Get all fields
tables = c(
  "features_esacoh_50k",
  "features_word_50k",
  "features_swe_50k",
  "features_locality2_50k",
  "features_lm_50k",
  "features_kenlm_50k",
  "features_altlex_50k",
  "features_coref_50k",
  "features_wordnet_50k"
)
fields = tables %>%
  map(function(table)
    paste0("SHOW COLUMNS FROM ", table)) %>%
  map(function(query)
    dbGetQuery(con, query)[, 1]) %>%
  unlist %>%
  unique

dbDisconnect(con)

#### FEATURES ####
word_swe_win = c(45, 50, 55, 60, 65)
esa_swe_win = c(10, 15, 20, 25, 30)
variables = c(
  "causal_word_span_ratio",
  "noncausal_word_span_ratio",
  paste0("coref_", seq(1, 4)),
  "deploc_log_mean",
  paste0("esacoh_", seq(1, 4)),
  "cc_prob",
  paste0("esa_swe_w", esa_swe_win),
  paste(rep(
    paste0("snowball_swe_w", word_swe_win), each = 5
  ), seq(1, 5), sep = "_n"),
  "lucene_characters_per_word",
  "lucene_syllables_per_word",
  paste0("wordnet_", seq(1, 5))
)

seed_value = 131
classifier = "ridge"
drop_na_level = 1 # no need to drop features with too many nas, as there are none

dir = "out"
rdata_filename = paste0(dir, "/", "result-wundt.RData")
model_filename = paste0(dir, "/", "model-wundt.RDS")

start.time <- Sys.time()

library("mlr3")
library("magrittr")
library(mlr3verse)
library(mlr3pipelines)
library(mlr3filters)
#remotes::install_github("mlr-org/mlr3pipelines@pipeop_filterrows")
source("PipeOpFilterRows.R") # copied from github branch ... integrated here.
source("wundt_tuning_functions.R")

library(future)
library(data.table)

################## STAGE 1 ########################
# Stage 1: Load data and prepare task
lgr::get_logger("mlr3")$set_threshold("warn")
cat("Loading data\n")
source("source_load_features.R")
com_query <-
  com1_query_art(
    "com1_ensiwiki-2020_agerank",
    "50k",
    "stanford_sentences_sum >= 5 AND lucene_words_sum >= 30",
    col_names = variables
  )
guardian_query <-
  com1_query("com1_theguardian", "TRUE", col_names = variables)

data_all <- load_features_with_query(com_query)
guardian_data <- load_features_with_query(guardian_query)
cat("Done loading data\n")

wiki_data = data_all
wiki_data$lang = relevel(as.factor(wiki_data$lang), "simple")

wiki_task = as_task_classif(wiki_data, target = "lang", id = paste0("sample", i))
# https://mlr3gallery.mlr-org.com/posts/2020-03-30-stratification-blocking/
# this makes sure that pairs are together in either train or test groups
wiki_task$set_col_roles("pair_id", roles = "group")

# train/test split
set.seed(seed_value)

################## STAGE 2 ########################
# Stage 2: Prepare pipelines
# https://mlr3book.mlr-org.com/pipelines.html#pipe-modeling
#
feature_selection_graph =
  po("select", id = "word_swe_w")  %>>%
  po("select", id = "esa_swe_w")
filter_na_graph = # filters out rows with nas and columns with too many nas
  po("select",
     id = "drop_na",
     param_vals = list(selector = selector_drop_na(drop_na_level)))  %>>%
  po("filterrows", param_vals = list(filter_formula = ~ !apply(is.na(.SD), 1, any)))
po_under = po(
  "classbalancing",
  id = "undersample",
  adjust = "major",
  reference = "minor",
  shuffle = FALSE,
  ratio = 1 / 1
)
preprocessing_graph =
  feature_selection_graph %>>%
  filter_na_graph %>>%
  po_under %>>%
  po("scale")

cat(paste0("\n\n################## STAGE 3 ########################\n"))
cat(paste0("Stage 3: Inner loop\n"))

cat('Preparing ridge classifier\n')
classifier_graph =
  preprocessing_graph %>>%
  po(
    "learner",
    learner = lrn("classif.cv_glmnet"),
    param_vals = list(alpha = 0, parallel = FALSE)
  )

#classifier_graph$param_set # shows params that can be set
search_space = ps(
  word_swe_w.selector = p_fct(
    word_swe_w,
    trafo = function(x)
      selector_word_features(x)
  ),
  esa_swe_w.selector = p_fct(
    esa_swe_w,
    trafo = function(x)
      selector_esa_features(x)
  )
)


################## STAGE 4 ########################
# Stage 4: Run tuning
inner_grid = generate_design_grid(search_space)
cat('Inner grid size', nrow(inner_grid$data), '\n')

cv5 = rsmp("cv", folds = 5)
set.seed(seed_value)

# prepare tuner
# https://mlr3book.mlr-org.com/optimization.html
at = AutoTuner$new(
  learner = as_learner(classifier_graph),
  resampling = cv5,
  measure = msr("classif.acc"),
  search_space = search_space,
  terminator = trm("none"),
  tnr("grid_search")
)

# See https://stats.stackexchange.com/questions/11602/training-on-the-full-dataset-after-cross-validation
# 1. nested resampling to estimate unbiased performance
cat(paste0("Stage 1: Nested resampling\n"))
outer_resampling = rsmp("cv", folds = 3)
rr = resample(
  wiki_task,
  at$clone(),
  outer_resampling,
  store_models = TRUE,
  store_backends = TRUE
)
cat(paste0("extract_inner_tuning_results\n"))
print(extract_inner_tuning_results(rr))
cat(paste0("rr$score\n"))
measures = list(
  msr("classif.acc"),
  msr("classif.recall"),
  msr("classif.precision"),
  msr("classif.fbeta")
)
print(rr$score(measures))
cat(paste0("rr$aggregate\n"))
print(rr$aggregate(measures))
rr_result = data.frame(as.list(rr$aggregate(measures)))
# 2. tune + fit on whole dataset for final model (with optimal parameters)
cat(paste0("Stage 2: Final model training\n"))
at$train(wiki_task)

# get coefficients
# at$learner$model contains the final model
# see https://mlr3tuning.mlr-org.com/reference/AutoTuner.html
coef(at$learner$model$classif.cv_glmnet$model)

pred_data = foreach(i = 1:3, .combine = 'rbind') %do% {
  test_ids = rr$resampling$test_set(i)
  learner = rr$learners[[i]]
  learner$predict_type = "prob"
  pred = learner$predict(wiki_task, test_ids)
  print(pred$score(measures))
  pred_data = as.data.table(pred)
  pred_data %>% group_by(truth) %>% count()
  pred_data[, 'fold'] = i
  pred_data
}
print(pred_data %>% group_by(fold, truth) %>% count())

################## STAGE 6 ########################
# Stage 6: Evaluate model on Guardian
at$predict_type = "prob"
guardian_pred <-
  at$predict_newdata(guardian_data) # seems to retain order!
gprob = guardian_pred$prob[, 'english']
glogit = log(gprob / (1 - gprob)) # https://en.wikipedia.org/wiki/Logit
gpred <-
  data.frame(logit = glogit,
             prob = gprob,
             stimulus = guardian_data$page_id)
target_results = merge(guardian_stimulus, gpred, by = "stimulus")

# Guardian ALL data
cat("Loading Guardian ALL data\n")
cv_fit_coef = coef(at$learner$model$classif.cv_glmnet$model)
cv_fit_variables = rownames(cv_fit_coef)[-1] # first var is (Intercept)
guardian_query <-
  com1_query("com1_theguardian_all", "TRUE", col_names = cv_fit_variables)
guardian_all_data <- load_features_with_query(guardian_query)
unused_columns = variables[!variables %in% cv_fit_variables]
guardian_all_data[, unused_columns] = NA

# # predict
at$predict_type = "prob"
guardian_all_pred <- at$predict_newdata(guardian_all_data)
guardian_all_prob = guardian_all_pred$prob[, 'english']

# saving like this allows for reuse
saveRDS(at, file = model_filename)

# DESCRIBE DATA
cat("Describing data\n")
library(Hmisc)
descriptives <- list()
descriptives$data_all <- describe(wiki_data)

save(
  rr,
  at,
  pred_data,
  guardian_pred,
  guardian_all_prob,
  target_results,
  rr_result,
  descriptives,
  file = rdata_filename
)

time.taken <- difftime(Sys.time(), start.time, units = "secs")
