#!/bin/bash

# usage: ./scriptname <wxs|rnaseq> <fastq1> <fastq2>


export PATH=/home/${USER}/miniconda3/bin:$PATH

fastq1=$2
fastq2=$3

if [ $1 == "wxs" ] ; then
  exp_type="default"
  echo "experiment type: WXS (${exp_type})"
elif [ $1 == "rnaseq" ] ; then
  exp_type="rna-seq"
  echo "experiment type RNAseq (${exp_type})"
else
  echo error: unkown experiment type: \"${1}\"
  exit
fi

# in case of Single End sequencing file ($3 <fastq2> doesn't exist)
if [ ! -f $fastq2 ] ;then
  echo fastq2 \"$fastq2\" does not exist, move to single-end analysis
  fastq2=""
fi

# in case of Single End analysis, the preprocessed fastq ($2 <fastq1> does not exist)
echo $fastq1 |grep -q preprocessed
preproc_test=$?
if [ ! -f $fastq1 ] && [ $preproc_test -eq 0 ]  ;then
  echo preprocessed fastq  \"$fastq1\" does not exist, skip preprocessed analysis
  echo $(date) end mixcr preprocessed analysis
  exit
fi

# make the outname and outdirs
mixcr_path=~/mixcr_cartesius/mixcr-3.0.3
rscript_path=~/mixcr_cartesius/get_full_clone_sequences.R
outname=$(basename $fastq1 .fastq.gz)
outname=$(echo $outname | sed 's/_R[12]$// ; s/_[12]$// ')
echo $outname

outdir=/scratch-shared/${USER}/mixcr/${outname}
mkdir -p $outdir
cd $outdir

# alignment
echo $(date) start alignment
$mixcr_path/mixcr align \
-s hsa \
-p default \
-t $(nproc --all) \
-f \
-r ${outname}_align.report \
$fastq1 $fastq2 \
${outname}.vdjca
echo $(date) end alignment

# assembly
echo $(date) start assembly
$mixcr_path/mixcr assemble \
-a \
-r ${outname}_assemble.report \
-f \
-t $(nproc --all) \
${outname}.vdjca \
${outname}.clna
echo $(date) end assembly

# assemble contigs
echo $(date) start assembleContigs
$mixcr_path/mixcr assembleContigs \
-f \
-r ${outname}_assembleContigs.report.txt \
${outname}.clna \
${outname}_clones.clns
echo $(date) end assembleContigs

# export clones
echo $(date) start exportClones
$mixcr_path/mixcr exportClones \
-f \
-c IG \
-p fullImputed \
${outname}_clones.clns \
${outname}_clones.txt
echo $(date) end exportClones

# export clones pretty
echo $(date) start exportPretty
$mixcr_path/mixcr exportClonesPretty \
-f \
-n 10 \
${outname}.clna \
${outname}_clonesPretty.txt
echo $(date) end exportPretty

# export clone sequences
echo $(date) start export clone sequences
$rscript_path -i ${outname}_clones.txt
echo $(date) end export clone sequences


