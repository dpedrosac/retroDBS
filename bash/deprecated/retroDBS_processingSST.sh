#!/bin/bash
# author: David Pedrosa
# version: 2023-09-05, # first version of post-processing of SST after its creation
# run as: nohup ./retroDBS_diceAnalyses.sh > StatisticalAnalyses >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH

# Create results folder
OUTPUT_DIR=${PWD}/template/
if [[ ! -d $OUTPUT_DIR ]]; then
    mkdir -p $OUTPUT_DIR
fi

# Co-register t1 in MNI-space to SST
#antsRegistrationSyNQuick.sh -d 3 \
# -f ./t1.nii \
# -m ${OUTPUT_DIR}SST_retroDBS_Ttemplate0.nii.gz \
# -o ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_

# Convert mask from t1 in MNI space (t1_mask.nii) to SST in own space
#antsApplyTransforms \
#  -d 3 \
#  -i ./t1_mask.nii \
#  -r ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_Warped.nii.gz \
#  -t [ ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_0GenericAffine.mat, 1 ] \
#  -t ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_1InverseWarp.nii.gz \
#  -o ${OUTPUT_DIR}t1_maskSST.nii.gz
  

# Resample images and bring to same space
ResampleImage 3 ${OUTPUT_DIR}t1_maskSST.nii.gz ${OUTPUT_DIR}resampled_t1_maskSST.nii.gz 1x1x1 0 4

ResampleImage 3 ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_Warped.nii.gz ${OUTPUT_DIR}resampled_SST_retroDBS_Ttemplate0_Warped.nii.gz 1x1x1 0 4

mrtransform ${OUTPUT_DIR}resampled_t1_maskSST.nii.gz -template ${OUTPUT_DIR}SST_retroDBS_Ttemplate0.nii.gz -oversample 1 -interp linear ${OUTPUT_DIR}resampled_t1_maskSST.nii.gz -force
  
# Multiply mask with image to get skull-stripped imaged in native space; this should be used consecutively for registration with T1/SST 
ImageMath 3 ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_noskull.nii.gz m ${OUTPUT_DIR}SST_retroDBS_Ttemplate0.nii.gz  ${OUTPUT_DIR}resampled_t1_maskSST.nii.gz

# Co-register t1 in MNI-space to SST
antsRegistrationSyNQuick.sh -d 3 \
 -f ${OUTPUT_DIR}SST_retroDBS_Ttemplate0_noskull.nii.gz \
 -m ./t1_noskull.nii.gz \
 -o ${OUTPUT_DIR}MNI2template_
