#!/bin/bash
# author: David Pedrosa
# version: 2023-07-05, # created a new version for normalisation of PD25 imaging to MNI space (ibcm152-2009c_symmetric); added compression of NIFTI
# script coregistering preoperative data to MNI space
# run as: nohup ./retroDBS_coregistrationPD25.sh > NormalisationPD25 >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH


# Step3: Bringing everything into the same space (PD25 -> MNI space)
echo "======================================================================"
echo
echo " Coregistering data to MNI if necessary ... "
echo

function coregister_PD25segmentation() { # function to coregister the outputs from LeadDBS to MNI space
	input_pseud=$3
	$1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_0GenericAffine.mat ]]
	antsRegistrationSyNQuick.sh -d 3 \
		-f /$1/t2_noskull.nii.gz \
		-m $1/segmentationPD25/"${input_pseud}-T2w-N4brain-icbm.nii.gz" \
		-o $1/segmentationPD25/"${input_pseud}_PD25_2MNI_" 
}

num_processes=10
for SUBJ_DIR in ${PWD}/preoperative_planningNIFTI/subj*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running antsRegistrationSyNQuick at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${SUBJ_DIR##*/}"
	subj_no=$(echo ${SUBJ_DIR##*/} | cut -d "^" -f 2)
	
	prefix="Sub-"
	number="${subj_no//[[:alpha:]]}"
	subj_noPD25="${prefix}${number}"
	coregister_PD25segmentation ${PWD} $subj_no $subj_noPD25 & 
done
wait

echo "          ...done coregistering preoperative imaging into MNI space for all subjects. Please perform visual checks"
echo
echo "================================================================"


# Step3: Bringing everything into the same space (Segmentation of nuclei (PD25) -> MNI space)
echo "======================================================================"
echo
echo " Transforming data of segmentation (PD25) to MNI ... "
echo


function transform_PreoperativeSegmentation() # function to transform the peroperative segmentation of the STN according to Step3
{

input_pseud=$4
for data2rename in $1/segmentationPD25/"${input_pseud}-nuclei-seg.nii"
do
	filename_data=$(basename $data2rename)
	filename_data=${filename_data//\#/}
	antsApplyTransforms \
		-d 3 \
		-i $data2rename \
		-r $1/segmentationPD25/${input_pseud}_PD25_2MNI_Warped.nii.gz \
		-t $1/segmentationPD25/${input_pseud}_PD25_2MNI_1Warp.nii.gz \
		-t $1/segmentationPD25/${input_pseud}_PD25_2MNI_0GenericAffine.mat \
		-o $1/segmentationPD25/"Warped_${filename_data}"
	fslchfiletype NIFTI_GZ $3/"Warped_${filename_data}.nii" $3/"Warped_${filename_data}.nii.gz"
	rm -rf $3/"Warped_${filename_data}.nii"

done
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
	prefix="Sub-"
	number="${subj_no//[[:alpha:]]}"
	subj_noPD25="${prefix}${number}"

	transform_PreoperativeSegmentation ${PWD} $subj_no $SUBJ_DIR $subj_noPD25 & 
done
wait

echo "          ...done applying transformations for all subjects. Please perform visual checks"
echo
echo "================================================================"


