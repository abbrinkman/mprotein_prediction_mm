library(tidyverse)
library(parallel)
library(openxlsx)

setwd("~/path/data/jacobs/mixcr/primary_relapsed_rnaseq/")

# get the list of samples: patients, SRA files, Primary/Relapse status
meta <- read_tsv("~/path/data/jacobs/metadata/primary_relapse_pairs_RNAseqOnly.tsv")
meta <- split(meta, meta$Run)

# get the result files, use the non-preprocessed data to start with
fnames <- list.files(path="~/path/data/jacobs/mixcr/clones_v3", 
                     pattern="_clones_v3.txt", recursive = T,
                     full.names=T)

# for now, take only the non-preprocessed data
fnames <- fnames[-grep("preprocessed", fnames)]

# select only the ones present in the metadata table
fnames <- fnames[gsub("_.+txt$","", basename(fnames)) %in% names(meta)]

# function to read "_clones_v3.txt" files, limit to the top 'max_clones' clones, to reduce load
fname2tib <- function(x, max_clones=100) {
  tb <- read_delim(x, delim="\t", n_max=max_clones) 
  if (nrow(tb) == 0) {
    tbl_colnames <- c("cloneId", "cloneCount", "cloneFraction", "allVHitsWithScore", "allDHitsWithScore", 
                      "allJHitsWithScore", "allCHitsWithScore", "nSeqFR1", "nSeqImputedFR1", 
                      "nMutationsFR1", "nSeqCDR1", "nSeqImputedCDR1", "nMutationsCDR1", "nSeqFR2", 
                      "nSeqImputedFR2", "nMutationsFR2", "nSeqCDR2", "nSeqImputedCDR2", 
                      "nMutationsCDR2", "nSeqFR3", "nSeqImputedFR3", "nMutationsFR3", "nSeqCDR3", 
                      "nSeqImputedCDR3", "nSeqGermlineVCDR3Part", "nSeqImputedGermlineVCDR3Part", 
                      "nMutationsGermlineVCDR3Part", "nSeqDRegion", "nSeqImputedDRegion", 
                      "nMutationsDRegion", "nSeqGermlineJCDR3Part", "nSeqImputedGermlineJCDR3Part", 
                      "nMutationsGermlineJCDR3Part", "nSeqFR4", "nSeqImputedFR4", "nMutationsFR4", 
                      "Chains")
    tb <- as_tibble(data.frame(matrix(nrow=0,ncol=length(tbl_colnames))))
    colnames(tb) <- tbl_colnames
  }
  tb %>% 
    mutate(sample_id = gsub("_clones_v3.txt","",basename(x))) %>%
    mutate(allVHitsWithScore = as.character(allVHitsWithScore), 
           allDHitsWithScore = as.character(allDHitsWithScore),
           allJHitsWithScore = as.character(allJHitsWithScore),
           allCHitsWithScore = as.character(allCHitsWithScore))
}
  
# function to reduce the number of clone names per clonotype
selectClones <- function(x, max_clone_names=10) {
  # x: e.g. column "allVHitsWithScore"
  # all clones with the (same) max score, only the first 'max_clones' of them
  clones <- lapply(strsplit(x, ","), function(y) {
    gsub("\\(.+$","", y)})
  scores <- lapply(strsplit(x, ","), function(y) {
    as.numeric(gsub("\\)","", gsub("^.+\\(","",y)))})
  clones_selected <- lapply(1:length(clones), function(x) {
    clones[[x]][scores[[x]]==max(scores[[x]])]})
  clones_selected <- lapply(clones_selected, head, max_clone_names)
  clones_selected <- lapply(clones_selected, unique)
  clones_selected <- sapply(clones_selected, paste, collapse="/")
  clones_selected
}

get_full_clone_seq <- function(tb) {
  if (nrow(tb)==0) {
    out <- tibble()
  } else {
  out <- tb %>% 
    mutate(V = selectClones(allVHitsWithScore), D = selectClones(allDHitsWithScore),
           J = selectClones(allJHitsWithScore), 
           C = selectClones(allCHitsWithScore),
           VDJC = gsub(",",", ",
                       gsub(",,",",",
                            gsub("NA","", 
                                 paste(V, D, J, sep=","))))) #%>%
  }
  out
}

# function to get all data in one tibble, making use of the functions above
clones_sequences_tsv2tibble <- function(x) { # x = '_clones_v3.txt' filename
  message(x)
  tb <- fname2tib(x) %>%
    get_full_clone_seq()
  if (nrow(tb)==0) {
    tb <- tibble()
  } else {
  sra <- gsub("_.+$","", basename(x))
  tb$sra <- sra
  if (grepl("preprocessed", x)) {
    tb$preproc <- "preprocessed"
  } else {
    tb$preproc <- "not preprocessed"
  }
  tb$exp_type <- meta[[sra]]$Assay_Type
  tb$disease_state <- meta[[sra]]$PRIMARY_METASTATIC_TUMOR
  tb$patient_id <- meta[[sra]]$patient_id
  }
  tb
}
tb1 <- do.call(rbind, lapply(fnames, clones_sequences_tsv2tibble))

# mark heavy and light chain clonotypes
tb1 <- tb1 %>% 
  mutate(chain = "light")
tb1$chain[grepl("IGH", tb1$Chains)] <- "heavy"

# get the relevant clonotypes for each patient:
# select for each patient, chain, disease_state, the most abundant clone
tb2 <- tb1 %>%
  group_by(preproc, patient_id, chain, disease_state) %>%
  filter(cloneFraction >= max(cloneFraction)) %>%
  ungroup() 
  
tb2 <- tb2 %>%
  mutate(nSeqFR1 = replace_na(nSeqFR1,""),
         nSeqCDR1 = replace_na(nSeqCDR1,""),
         nSeqFR2 = replace_na(nSeqFR2,""),
         nSeqCDR2 = replace_na(nSeqCDR2,""),
         nSeqFR3 = replace_na(nSeqFR3,""),
         nSeqCDR3 = replace_na(nSeqCDR3,""),
         nSeqFR4 = replace_na(nSeqFR4,""),
         
         nSeqImputedFR1 = replace_na(nSeqImputedFR1,""),
         nSeqImputedCDR1 = replace_na(nSeqImputedCDR1,""),
         nSeqImputedFR2 = replace_na(nSeqImputedFR2,""),
         nSeqImputedCDR2 = replace_na(nSeqImputedCDR2,""),
         nSeqImputedFR3 = replace_na(nSeqImputedFR3,""),
         nSeqImputedCDR3 = replace_na(nSeqImputedCDR3,""),
         nSeqImputedFR4 = replace_na(nSeqImputedFR4,""),
         
         # replace all NA's with '-', checked this, this is OK, there are no mutations at NA's
         nMutationsFR1 = replace_na(nMutationsFR1,"-"),
         nMutationsCDR1 = replace_na(nMutationsCDR1,"-"),
         nMutationsFR2 = replace_na(nMutationsFR2,"-"),
         nMutationsCDR2 = replace_na(nMutationsCDR2,"-"),
         nMutationsFR3 = replace_na(nMutationsFR3,"-"),
         nMutationsGermlineVCDR3Part = replace_na(nMutationsGermlineVCDR3Part,"-"),
         nMutationsDRegion = replace_na(nMutationsDRegion,"-"),
         nMutationsGermlineJCDR3Part = replace_na(nMutationsGermlineJCDR3Part,"-"),
         nMutationsFR4 = replace_na(nMutationsFR4,"-"),
         
         nSeqImputedFullClone = paste0(nSeqImputedFR1,
                                        nSeqImputedCDR1,
                                        nSeqImputedFR2,
                                        nSeqImputedCDR2,
                                        nSeqImputedFR3,
                                        nSeqImputedCDR3,
                                        nSeqImputedFR4))

# # determine whether we have a 'valid' clonotype sequence, function returns TRUE if valid
# testValidSequence <- function(aa_seq) {
#   # lower case (combined with stopcodons/underscore) in-between upper case sequence?
#   test1 <- str_detect(aa_seq, "[A-Z]_?[a-z\\*]+_?[a-z\\*]+_?[A-Z]")
#   # stopcodons within upper case?
#   test2 <- str_detect(aa_seq, "[A-Z]\\*+[A-Z]")
#   # underscores within upper case? 
#   test3 <- str_detect(aa_seq, "[A-Z]_+[A-Z]")
#   !c(test1 | test2 | test3)
# }
# tb2 <- tb2 %>% 
#   mutate(aaSeqImputedFullClone_valid = testValidSequence(aaSeqImputedFullClone))

# select columns of interest to export to EXCEL
tb3 <- tb2 %>% 
  select(cloneCount, cloneFraction, VDJC, nSeqImputedFullClone, 
         patient_id, sra, preproc, exp_type, disease_state, chain) %>% 
  arrange(patient_id, chain, disease_state)

# save the table
write.xlsx(tb3, file="RNAseq_Primary_Relapse_nt_sequences.xlsx")

