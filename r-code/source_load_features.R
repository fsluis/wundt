library('DBI')
library("RMySQL")
drv = dbDriver("MySQL")

com1_query_art <- function(database, size, conditions, col_names=com1_colnames) {
  paste0("SELECT com1.pair_id, com1.lang, ", paste(col_names, collapse=', '), "
                FROM `", database, "`.`features_word_",size,"` AS com1  
                LEFT JOIN `", database, "`.`features_altlex_",size,"` AS com2 ON com1.page_id=com2.page_id AND com2.section IS NULL AND com2.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_coref_",size,"` AS com3 ON com1.page_id=com3.page_id AND com3.section IS NULL AND com3.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_esacoh_",size,"` AS com4 ON com1.page_id=com4.page_id AND com4.section IS NULL AND com4.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_lm_",size,"` AS com5 ON com1.page_id=com5.page_id AND com5.section IS NULL AND com5.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_locality_",size,"` AS com6 ON com1.page_id=com6.page_id AND com6.section IS NULL AND com6.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_swe_",size,"` AS com7 ON com1.page_id=com7.page_id AND com7.section IS NULL AND com7.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_wordnet_",size,"` AS com8 ON com1.page_id=com8.page_id AND com8.section IS NULL AND com8.paragraph IS NULL
                LEFT JOIN `", database, "`.`features_kenlm_",size,"` AS com9 ON com1.page_id=com9.page_id AND com9.section IS NULL AND com9.paragraph IS NULL
                WHERE com1.section IS NULL AND com1.paragraph IS NULL AND ", conditions) }

com1_query <- function(database, conditions, col_names=com1_colnames) {
  paste0("SELECT com1.page_id, ", paste(col_names, collapse=', '), "
                FROM `", database, "`.`features_word` AS com1  
                LEFT JOIN `", database, "`.`features_altlex` AS com2 ON com1.page_id=com2.page_id
                LEFT JOIN `", database, "`.`features_coref` AS com3 ON com1.page_id=com3.page_id
                LEFT JOIN `", database, "`.`features_esacoh` AS com4 ON com1.page_id=com4.page_id
                LEFT JOIN `", database, "`.`features_lm` AS com5 ON com1.page_id=com5.page_id
                LEFT JOIN `", database, "`.`features_locality` AS com6 ON com1.page_id=com6.page_id
                LEFT JOIN `", database, "`.`features_swe` AS com7 ON com1.page_id=com7.page_id
                LEFT JOIN `", database, "`.`features_wordnet` AS com8 ON com1.page_id=com8.page_id
                LEFT JOIN `", database, "`.`features_kenlm` AS com9 ON com1.page_id=com9.page_id
                WHERE ", conditions) }

load_features_with_query <- function(query) {
  # keep con inside function so there won't be run-away connections in a parallel setting!
  con = dbConnect(drv, user="wundt", dbname="com1_ensiwiki-2020_agerank", host="localhost", password="PaSSWoRD")
  assert(dbIsValid(con))
  data = dbGetQuery(con, query)
  dbDisconnect(con)
  return(data)  
}

#data <- load_features("phd_art_1k")
#cor(as.matrix(data[,2]), as.matrix(data[,-c(1,2)]), use="pairwise.complete.obs")
