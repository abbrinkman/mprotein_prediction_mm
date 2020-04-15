# README #



This repository contains code that was used for analyses in the study: 

### Title

In silico prediction of M-protein derived clonotypic peptides (for Mass Spectrometric analysis) yields novel personalized biomarkers in multiple myeloma

### Authors

P. Langerhorst, A. Brinkman, M.M van Duijn, J. Gloerich, B. Scheijen, J.F.M. Jacobs

### Notes

For running mixcr on the Multiple Myeloma COMPASS data, a high-performance linux cluster with slurm job scheduling system (https://www.surf.nl/en/dutch-national-supercomputer-cartesius) was used, on which the data was downloaded, analyzed, and processed. The following scripts were used for this:

* sra_download.sh
* fastq_dump.sh
* mixcr.sh
* cleanup.sh
* make_SRA_job.sh

Amino acid sequences from assembled clones were obtained using the following scripts:

* get_full_clone_sequences.R
* export_clones_v2.sh

DNA sequences from the assembled clones were obtained using the following scripts:

* export_clones_v3.sh
* primary_rnaseq_nt_sequences.txt.R
* primary_relapse_rnaseq_nt_sequences.txt.R
