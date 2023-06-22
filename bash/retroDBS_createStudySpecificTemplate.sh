#!/bin/bash
# This script creates a subject-specific template (SST) using ANTs.
# ANTs should be built from the source code, and folders need to be adapted (ANTSPATH, INPUT_DIR, sequence-name for input).
# Author: Kenan Steidel, Philipp Loehrer and David Pedrosa under MIT
# -----------------------------------------------------------------

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
INPUT_DIR=${PWD}/convertedImaging_nodefaced/
OUTPUT_DIR=${PWD}/template/

if [[ ! -d $OUTPUT_DIR ]]; then
  echo "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
  mkdir -p $OUTPUT_DIR
fi

echo "--------------------------------------------------------------------------------------"
echo "--------------------- Creating subject specific template (SST) ---------------------"
echo "--------------------------------------------------------------------------------------"


time_start=$(date +%s)

${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -o ${OUTPUT_DIR}iPS_DBSpatients_ \
  -i 4 \
  -g 0.15 \
  -c 2 \
  -k 1 \
  -w 1 \
  -f 8x4x2x1 \
  -s 3x2x1x0 \
  -q 100x70x50x10 \
  -n 1 \
  -r 1 \
  -j 20 \
  -m CC \
  -t BSplineSyN[0.1,75,0] \
  ${INPUT_DIR}*.nii > antsCreateSST.txt 2>&1

time_end_template_creation=$(date +%s)
time_elapsed_template_creation=$((time_end_template_creation - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done with template creation: $((time_elapsed_template_creation / 3600))h $((time_elapsed_template_creation % 3600 / 60))m $((time_elapsed_template_creation % 60))s"
echo "--------------------------------------------------------------------------------------"
echo

