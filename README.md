# Wundt–Berlyne's Inverted-U shows that Information Complexity explains Interest in Text

This repository contains the analysis code accompanying the paper *Wundt–Berlyne's Inverted-U shows that Information Complexity explains Interest in Text*. The paper tests whether readers' interest in newspaper articles follows an inverted-U relation with the articles' objective information complexity, and whether comprehensibility and familiarity moderate that relation. The code implements the analyses reported in the paper: the main inverted-U model, the moderation models, the structural equation model, the pupil-dilation validation, and the supplementary comparison of alternative complexity models.

## Relation to previous work

The feature extraction and complexity-modeling infrastructure used to produce the textual complexity predictions derives from our previous *Patterns* paper, *Model interpretability enhances domain generalization in the case of textual complexity modeling* (DOI [10.1016/j.patter.2025.101177](https://doi.org/10.1016/j.patter.2025.101177)), whose code is published at [github.com/fsluis/textual-complexity](https://github.com/fsluis/textual-complexity). That repository is linked here as a pinned submodule (`external/textual-complexity`) for provenance; the analysis scripts in this repository do not import it at runtime.

## Repository structure

```
├── README.md                             # this file
├── LICENSE                               # MIT license for the source code in this repository
├── sessionInfo.txt                       # tested software environment (R and package versions)
├── .gitmodules                           # submodule configuration
├── external/textual-complexity/          # pinned submodule (Patterns paper infrastructure)
└── analysis/
    ├── 01_prepare_data.R                 # prepare the Guardian experiment data
    ├── 02_main_wundt_model.R             # main inverted-U model
    ├── 03_moderation.R                   # comprehensibility and familiarity moderation models
    ├── 04_sem.R                          # structural equation model
    ├── 05_pupil_validation.R             # pupil dilation validation
    ├── 06_train_alternative_models.R     # train alternative complexity models
    ├── 07_alternative_models.R           # evaluate alternative complexity models
    ├── 08_reconstruct_target_results.R   # reconstruct the textual complexity model
    └── feature_spec.R                    # feature specifications
```

Scripts 01–07 implement the analyses accompanying the paper. Script 08 is an independent reconstruction of the textual complexity model from the public feature data; it is not required for the paper's reported analyses.

## Software requirements

R (tested with R 4.4.3; full version list in `sessionInfo.txt`) with the following CRAN packages:

- `dplyr`, `readr` — data loading
- `sandwich`, `lmtest` — cluster-robust inference
- `lavaan`, `semTools` — structural equation modeling
- `lm.beta` — standardized regression coefficients
- `glmnet` — regularized logistic regression
- `mlr3`, `mlr3pipelines`, `mlr3learners`, `mlr3tuning`, `future` — model training and evaluation
- `randomForest`, `xgboost` — alternative classifiers

## Data availability

The datasets used by the analysis are published on Figshare under CC BY 4.0:

- Guardian experiment data (behavioral and pupil measures): [m9.figshare.27057958](https://doi.org/10.6084/m9.figshare.27057958)
- EnSiWiki + Guardian feature matrix: [m9.figshare.25676394](https://doi.org/10.6084/m9.figshare.25676394)
- Parsed Wikipedia corpus used for feature extraction: [m9.figshare.25676209](https://doi.org/10.6084/m9.figshare.25676209)

## License

The source code in this repository is licensed under the MIT License (see `LICENSE`). The datasets remain under their existing Figshare licenses (CC BY 4.0). The `external/textual-complexity` submodule is maintained separately by its own authors and is not covered by this repository's license.
