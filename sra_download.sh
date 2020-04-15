#!/bin/bash

# usage: ./scriptname <srr_id>

bin_config=${HOME}/mixcr_cartesius/sratoolkit.2.9.2-ubuntu64/bin/vdb-config
prj_ngc=${HOME}/mixcr_cartesius/prj_18095.ngc
bin_prefetch=${HOME}/mixcr_cartesius/sratoolkit.2.9.2-ubuntu64/bin/prefetch
bin_ascp=${HOME}/.aspera/connect/bin/ascp
etc_id_dsa=${HOME}/.aspera/connect/etc/asperaweb_id_dsa.openssh
ascp_path=\"$bin_ascp"|"$etc_id_dsa\"

# create necessary directories
sra_dir=/scratch-shared/${USER} # config tool creates an 'sra' subdir automatically !!
mkdir -p $sra_dir
cd $sra_dir

# create the sra subdir also manually incase of 'public' sra files
mkdir -p ${sra_dir}/sra

# configure for SRA download
$bin_config -p -o n |grep -q $sra_dir
if [[ $? -eq 1 ]] ; then
  echo $(date) start configuring NCBI download 
  $bin_config --import $prj_ngc $sra_dir
  echo $(date) end configuring NCBI download
fi

# download
echo $(date) start downloading sra
#args="$bin_prefetch -t ascp --ascp-path $ascp_path $1"
args="$bin_prefetch -O ${sra_dir}/sra -t ascp --ascp-path $ascp_path $1"
eval $args
echo $(date) end downloading sra





