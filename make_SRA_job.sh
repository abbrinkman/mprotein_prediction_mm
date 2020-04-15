#!/bin/bash

# ./usage ./scriptname <SRRxxxxxxx> <wxs|rnaseq>

if [ $# -ne 2 ] ; then
  echo error: provide all arguments!
  exit
fi

if [ $2 != "rnaseq" ] && [ $2 != "wxs" ] ; then
  echo error: experiment type \'${2}\' unknown!
  exit
fi

out=SRA_job_${1}.sh

# 1. download SRA, no dependencies
echo jid1=\$\(sbatch -p staging -t 1:00:00 --job-name=${1}_sra_download --output=${1}_sra_download.slurm.out ~/mixcr_cartesius/sra_download.sh ${1}\) > $out
echo wait >> $out
echo jid1=\$\(echo \$jid1 \|awk \''{print $(NF)}'\'\) >> $out

# 2. fastq-dump, dependent on 1.
echo jid2=\$\(sbatch -t 2:00:00 --dependency=afterok:\${jid1} --job-name=${1}_fastq_dump --output=${1}_fastq_dump.slurm.out ~/mixcr_cartesius/fastq_dump.sh ${1}\) >> $out
echo wait >> $out
echo jid2=\$\(echo \$jid2 \|awk \''{print $(NF)}'\'\) >> $out

# 4. mixcr w/o preprocessing, dependent on 2.
echo jid3=\$\(sbatch -t 6:00:00 --dependency=afterok:\${jid2} --job-name=${1}_mixcr --output=${1}_mixcr.slurm.out ~/mixcr_cartesius/mixcr.sh ${2} /scratch-shared/${USER}/fastq/${1}_1.fastq.gz /scratch-shared/${USER}/fastq/${1}_2.fastq.gz\) >> $out
echo wait >> $out
echo jid3=\$\(echo \$jid3 \|awk \''{print $(NF)}'\'\) >> $out

# 5. clean up sra and fastq files
echo jid4=\$\(sbatch -t 00:00:30 --dependency=afterok:\${jid4}:\${jid3} --job-name=${1}_cleanup --output=${1}_cleanup.slurm.out ~/mixcr_cartesius/cleanup.sh ${1}\) >> $out
