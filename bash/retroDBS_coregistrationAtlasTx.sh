#!/bin/bash
# author: David Pedrosa
# version: 2023-07-06, # added the possibility to apply transformations to VTA and changed the atlas; besides compressed output to NIFTI_GZ
# script preprocessing data from VTA generation and segmentation
# run as: nohup ./retroDBS_coregistrationAtlasTx.sh > NormalisationAtlases >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH

# Step1: Bringing everything into same space (atlas_t1 -> MNI space)
echo "======================================================================"
echo
echo " Coregistering data to MNI if necessary ... "
echo

function coregister_leadResults() { # function to coregister the outputs from LeadDBS to MNI space (ICBM152-2009c_symmetric)

	input_pseud=$2
	antsRegistrationSyNQuick.sh -d 3 \
		-f /$1/t1.nii \
		-m $1/VTA/${input_pseud}/anat_t1.nii \
		-o $1/VTA/${input_pseud}/native2MNI_
}


num_processes=10
for SUBJ_DIR in ${PWD}/VTA/subj*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running antsRegistrationSyNQuick at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${SUBJ_DIR##*/}"
	subj_no=$(echo ${SUBJ_DIR##*/} | cut -d "^" -f 2)
	coregister_leadResults ${PWD} $subj_no & 
done
wait

echo "          ...done coregistering atlas_t* into MNI space for all subjects. Please perform visual checks"
echo
echo "================================================================"


function transform_VTA() { # function to transform the VTA according to Step1
	input_pseud=$2

	SEGMENTATION_DIR=$1/VTAsegmented/${input_pseud} # Create results folder
	if [[ ! -d $SEGMENTATION_DIR ]]; then
	    mkdir -p $SEGMENTATION_DIR
	fi

	data2rename=$1/VTA/"${input_pseud}/stimulations/native/retroDBS/vat_left.nii"
	filename_data=$(basename $data2rename)
	filename_data=${filename_data//\#/}
		antsApplyTransforms \
		-d 3 \
		-i $data2rename \
		-r $1/VTA/${input_pseud}/native2MNI_Warped.nii.gz \
		-t $1/VTA/${input_pseud}/native2MNI_1Warp.nii.gz \
		-t $1/VTA/${input_pseud}/native2MNI_0GenericAffine.mat \
		-o ${SEGMENTATION_DIR}/"Warped_${filename_data}"
	fslchfiletype NIFTI_GZ ${SEGMENTATION_DIR}/"Warped_${filename_data}" ${SEGMENTATION_DIR}/"Warped_${filename_data}.gz"
	rm -rf ${SEGMENTATION_DIR}/"Warped_${filename_data}"


	data2rename=$1/VTA/"${input_pseud}/stimulations/native/retroDBS/vat_right.nii"
	filename_data=$(basename $data2rename)
	filename_data=${filename_data//\#/}
		antsApplyTransforms \
		-d 3 \
		-i $data2rename \
		-r $1/VTA/${input_pseud}/native2MNI_Warped.nii.gz \
		-t $1/VTA/${input_pseud}/native2MNI_1Warp.nii.gz \
		-t $1/VTA/${input_pseud}/native2MNI_0GenericAffine.mat \
		-o ${SEGMENTATION_DIR}/"Warped_${filename_data}"
	fslchfiletype NIFTI_GZ ${SEGMENTATION_DIR}/"Warped_${filename_data}" ${SEGMENTATION_DIR}/"Warped_${filename_data}.gz"
	rm -rf ${SEGMENTATION_DIR}/"Warped_${filename_data}"
		
}

num_processes=10
for SUBJ_DIR in ${PWD}/preoperative_planningNIFTI/subj*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running antsApplyTransforms at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${SUBJ_DIR##*/}"
	subj_no=$(echo ${SUBJ_DIR##*/} | cut -d "^" -f 2)
	transform_VTA ${PWD} $subj_no $SUBJ_DIR & 
done
wait

echo "          ...done applying transformations for all subjects. Please perform visual checks"
echo
echo "================================================================"



