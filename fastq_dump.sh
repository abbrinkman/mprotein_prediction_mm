#!/bin/bash

# usage: ./scriptname <srr_id>

# create necessary directories
mkdir -p /scratch-shared/${USER}/tmp
tmp=$(mktemp -d -p /scratch-shared/${USER}/tmp) # for parallel-fastq-dump
fastq_dir=/scratch-shared/${USER}/fastq
mkdir -p $fastq_dir

sra_dir=/scratch-shared/${USER}
cd $sra_dir

# fastq-dump
echo $(date) start fastq dump of $(realpath sra/${1}.sra) to $tmp
parallel-fastq-dump -s sra/${1}.sra \
--threads $(nproc --all) \
--gzip \
--split-files \
--tmpdir $tmp \
--outdir $fastq_dir
echo $(date) end fastq dump of $(realpath sra/${1}.sra) to $tmp

# clean up
echo $(date) start cleaning up
rm -rv $tmp
echo $(date) end cleaning up




