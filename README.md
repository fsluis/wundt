# Wundt
This repository contains the code base accompanying the paper 'Textual Complexity Facilitates Epistemically Resilient AI'. 
It consists of two parts: The main Scala code for text analysis and the r-code used for modelling.

## Contents
The Scala code is divided into subprojects according to shared dependencies and functionality.

The following subprojects are relevant:
* `data/`. The main control flow for reading data sets, analysing features, and submitting the results back to a database. Complexity features are derived in the scala package _ix/data/com/features_. This is the recommended starting point for review.
* `complexity-*/`. Specifies different _Services_ and routines that calculate aspects of textual complexity. For example, the `complexity-lm/` subproject handles the interaction with KenLM and AltLex for calculating the respective language model and AltLex features.

The following subprojects can be considered boilerplate:
* `integration/` merges all subprojects into a single dependency.  
* `common-*/` contains shared routines and boilerplate used by the different subprojects.
* `data/` combines all test code into a fat-jar used for testing.
* `shaded` contains external projects with specific dependencies dropped or changed, to solve dependency conflicts. 

## Resources
The Scala code relies on extensive resources to run. It needs:
* Input data. Currently included is a file with 10 pairs of simple and English Wikipedia articles (at resources/data) for testing.
* WordNet. Currently included is version 3.1.
* A large language model (CommonCrawl). Can be obtained from http://statmt.org/ngrams.
* Hyphen dictionaries. Currently included in resources/hyphen 
* ESA model. Can be generated using `data/src/scala/ix/complexity/lucene3/esa/index/`

## R-code
R-code for modelling is included in the directory `r-code`. The main loop that runs the nested resampling is in the file `r-code/train_model.R`. It expects that textual features to be found in a database. Model files are outputted in a subfolder `r-code/out/`.    

## Final model
The final glmnet model, as trained on EnSiWiki2020 and described in the paper, is found in `r-code/out/final-glmnet-ridge-na.rds`. This version is extracted from MLR3 (the machine learning framework used) to result in a much smaller and easier to work with model file.

The output of the final model when applied to the The Guardian Reading Dataset (DOI: ... ) is included in `r-code/out/final-outputs-theguardian.csv`   

