#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(optparse))

option_list <- list(
    make_option(c("-i", "--inputfile"), type="character", action="store", dest="fname",
        help="input file (xxx_full_clones.txt)")
    )
opt <- parse_args(OptionParser(option_list=option_list))

if (class(opt$fname)=="NULL") {
  print_help(OptionParser(option_list=option_list))
  stop("incorrect arguments")
}


suppressPackageStartupMessages(library(tidyverse))

fname <- opt$fname

fname2tib <- function(x) {
	read_delim(x, delim="\t", col_types = cols(targetQualities="c")) %>%
	mutate(sample_id = gsub("_clones.txt","",basename(x))) %>%
        mutate(allVHitsWithScore = as.character(allVHitsWithScore), 
               allDHitsWithScore = as.character(allDHitsWithScore),
               allJHitsWithScore = as.character(allJHitsWithScore),
               allCHitsWithScore = as.character(allCHitsWithScore))}

selectClones <- function(x, max_clones=10) {
	# x: e.g. column "allVHitsWithScore"
	# all clones with the (same) max score, only the first 2 of them
	clones <- lapply(strsplit(x, ","), function(y) {
				 gsub("\\(.+$","", y)})
	scores <- lapply(strsplit(x, ","), function(y) {
				 as.numeric(gsub("\\)","", gsub("^.+\\(","",y)))})
	clones_selected <- lapply(1:length(clones), function(x) {
					  clones[[x]][scores[[x]]==max(scores[[x]])]})
	clones_selected <- lapply(clones_selected, head, max_clones)
	clones_selected <- lapply(clones_selected, unique)
	clones_selected <- sapply(clones_selected, paste, collapse="/")
	clones_selected
}

get_full_clone_seq <- function(tb) {
out <- tb %>% 
	filter(cloneFraction >= 0.01) %>%
	mutate(V = selectClones(allVHitsWithScore), D = selectClones(allDHitsWithScore),
				J = selectClones(allJHitsWithScore), 
				C = selectClones(allCHitsWithScore),
				VDJC = gsub(",",", ",
					    gsub(",,",",",
						 gsub("NA","", 
						      paste(V, D, J, sep=","))))) %>%
  mutate(nSeqImputedFR1 = replace_na(nSeqImputedFR1, ""),
         nSeqImputedCDR1 = replace_na(nSeqImputedCDR1, ""),
         nSeqImputedFR2 = replace_na(nSeqImputedFR2, ""),
         nSeqImputedCDR2 = replace_na(nSeqImputedCDR2, ""),
         nSeqImputedFR3 = replace_na(nSeqImputedFR3, ""),
         nSeqImputedCDR3 = replace_na(nSeqImputedCDR3, ""),
         nSeqImputedFR4 = replace_na(nSeqImputedFR4, ""),
         aaSeqImputedFR1 = replace_na(aaSeqImputedFR1, ""),
         aaSeqImputedCDR1 = replace_na(aaSeqImputedCDR1, ""),
         aaSeqImputedFR2 = replace_na(aaSeqImputedFR2, ""),
         aaSeqImputedCDR2 = replace_na(aaSeqImputedCDR2, ""),
         aaSeqImputedFR3 = replace_na(aaSeqImputedFR3, ""),
         aaSeqImputedCDR3 = replace_na(aaSeqImputedCDR3, ""),
         aaSeqImputedFR4 = replace_na(aaSeqImputedFR4, "")) %>% 
  mutate(fullCloneSeq = paste0(nSeqImputedFR1, nSeqImputedCDR1, nSeqImputedFR2 , 
				     nSeqImputedCDR2, nSeqImputedFR3, nSeqImputedCDR3, 
				     nSeqImputedFR4),
	       fullCloneAAseq = paste0(aaSeqImputedFR1, aaSeqImputedCDR1, aaSeqImputedFR2,
				       aaSeqImputedCDR2, aaSeqImputedFR3, aaSeqImputedCDR3, 
				       aaSeqImputedFR4)) %>%
	select(cloneCount, cloneFraction, VDJC, fullCloneSeq, fullCloneAAseq)
	out
}

tb1 <- fname2tib(fname) %>%
	get_full_clone_seq()

write.table(tb1, file = paste0(gsub("\\.txt$","",basename(fname)), "_sequences.tsv"),
			       sep="\t", quote=F, col.names=T, row.names=F)

