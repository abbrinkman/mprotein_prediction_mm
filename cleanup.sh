#!/bin/bash

# usage: ./scriptname <srr_id>

# specify directories
sra_dir=/scratch-shared/${USER}/sra
fastq_dir=/scratch-shared/${USER}/fastq

# clean up
echo $(date) start cleaning up
rm -v ${sra_dir}/${1}.sra
rm -v ${fastq_dir}/${1}_[12].fastq.gz
echo $(date) end cleaning up




