#!/bin/bash
# Author: David Pedrosa
# Version: 2024-03-12, changed to registration almost completely to FSL routines for consistency, created uniform nomenclature
# Script: Coregistering preoperative data to MNI space
# run as: nohup ./bash/retroDBS_coregistrationPreoperativeICBMv2.0.sh > CoregistrationPreoperative.v3.4 >&1 & disown


# Constants to use throughout the script
SCRIPT_DIR="${PWD}"
MNI_TEMPLATE=${SCRIPT_DIR}/"mni_icbm152_t1_tal_nlin_sym_09c_05.nii"
MNI_TEMPLATE_NOSKULL=${SCRIPT_DIR}/"mni_icbm152_t1_tal_nlin_sym_09c_05_noskull.nii.gz"
MNI_MASK=${SCRIPT_DIR}/"mni_icbm152_t1_tal_nlin_sym_09c_05_mask.nii"
RESAMPLED_VOXEL_SIZE=.5
NUM_PROCESSES=20

# Add ANTs to the PATH
export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

# Function to coregister preoperative results to MNI space
function coregister_PreoperativeResults() {
    local base_dir=$1
    local subject_dir=$2
    local subject_no=$3
    local subject_noPD25=$4
     
    # Coregister preoperative data to MNI space (2009c non-linear, symmetric template)
    flirt -in $subject_dir/"${subject_no}_.nii" \
     -ref $MNI_TEMPLATE \
     -out $subject_dir/"preoperative2MNI_${subject_no}.nii" \
     -dof 12 \
     -interp nearestneighbour \
     -omat $subject_dir/"preoperative2MNI_${subject_no}.mat"

    # create inverse matrix for converting preoeprative data into MNI space
    convert_xfm -omat $subject_dir/"MNI2preoperative_${subject_no}.mat" \
     -inverse $subject_dir/"preoperative2MNI_${subject_no}.mat" 

    # Get skull-stripped imaged in preoperative space by multiplying mask and preoperative data 
    ImageMath 3 $subject_dir/"preoperative2MNI_${subject_no}_noskull.nii" m $subject_dir/"preoperative2MNI_${subject_no}.nii.gz" $MNI_MASK

    # convert skullstripped data to native (preoperative) space
    flirt -in $subject_dir/"preoperative2MNI_${subject_no}_noskull.nii" \
     -ref $subject_dir/"preoperative2MNI_${subject_no}_noskull.nii" \
     -out $subject_dir/"${subject_no}_noskull.nii" \
     -init $subject_dir/"MNI2preoperative_${subject_no}.mat" -applyxfm

    # convert skull-stripped data to MNI-space	
    flirt -in $subject_dir/"${subject_no}_noskull.nii.gz" \
     -ref $MNI_TEMPLATE_NOSKULL \
     -out $subject_dir/"preoperative2MNI_${subject_no}_noskull.nii" \
     -dof 12 \
     -interp nearestneighbour \
     -omat $subject_dir/"preoperative2MNI_${subject_no}_noskull.mat"
}

# Iterate through subject directories
for SUBJECT_DIR in ${SCRIPT_DIR}/preoperative_planningNIFTI/subj*; do
    ((i=i%NUM_PROCESSES)); ((i++==0)) && wait

    echo -e "======================================================================\n\n Running coregistration with FSL at multiple cores on ${WORKING_DIR}:\n"
    echo "Processing subj: ${SUBJECT_DIR##*/}"

    # Extract subject number
    subject_no=$(echo ${SUBJECT_DIR##*/} | cut -d "^" -f 2)
    prefix="Sub-"
    number="${subject_no//[[:alpha:]]}"
    subject_noPD25="${prefix}${number}"

    coregister_PreoperativeResults "${SCRIPT_DIR}" "${SUBJECT_DIR}" "${subject_no}" "${subject_noPD25}" &
done
wait


# Function to transform preoperative segmentation to MNI space
function transform_PreoperativeSegmentation() {

    local base_dir=$1
    local subject_no=$2 
    local subject_dir=$3
    local subject_noPD25=$4

    for data2rename in $subject_dir/*BURNED-IN*.nii; do
        filename_data=$(basename $data2rename)
        filename_data=${filename_data//\#/}

        # Transform everything to same dimensions as preoperative, skull-stripped data
        mrtransform $subject_dir/"${filename_data}"  \
            -template $subject_dir/"${subject_no}_noskull.nii"\
            -oversample 1 \
            -interp nearest \
            $subject_dir/"resampled_${filename_data}.gz" \
            -force -info

        # Necessary step, due to different "strides" so that dimensions did not match
        mrconvert $subject_dir/"resampled_${filename_data}.gz" -strides 1,2,3 $subject_dir/"resampled_${filename_data}.gz" -force

        # Apply linear transformation on individual data with matrix from Yiming Xiao (preoperative -> MNI)
        flirt -in $subject_dir/"resampled_${filename_data}.gz" \
            -ref $MNI_TEMPLATE_NOSKULL \
            -applyxfm \
            -dof 12 \
            -interp nearestneighbour \
            -init $base_dir/segmentationPD25/"${subject_noPD25}-T1nav-N4brain-icbm.mat" \
            -out $subject_dir/"resampled-ICBM_${filename_data}.gz"
    done
}

# Iterate through subject directories for segmentation transformation
for SUBJECT_DIR in ${SCRIPT_DIR}/preoperative_planningNIFTI/subj*; do
    ((i=i%NUM_PROCESSES)); ((i++==0)) && wait

    echo -e "======================================================================\n\n Running antsApplyTransforms at multiple cores on ${WORKING_DIR}:\n"
    echo "Processing subj: ${SUBJECT_DIR##*/}"

    subject_no=$(basename "$SUBJECT_DIR")
    prefix="Sub-"
    number="${subject_no//[[:alpha:]]}"
    subject_noPD25="${prefix}${number}"

    transform_PreoperativeSegmentation "${SCRIPT_DIR}" "${subject_no}" "${SUBJECT_DIR}" "${subject_noPD25}" &
    find "${SCRIPT_DIR}/preoperative_planningNIFTI/" -type f -name "resampled_resampled*" -exec rm {} \; # removes files that have been preprocessed twice
done
wait

echo -e "          ...done applying transformations for all subjects. Please perform visual checks\n\n================================================================"
