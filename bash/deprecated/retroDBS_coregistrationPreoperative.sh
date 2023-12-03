#!/bin/bash
# author: David Pedrosa
# version: 2023-09-21, # changes in the pipeline to put everything into ICBM space according to transform matrices provided by Ximing Xiao
# script coregistering preoperative data to MNI space
# run as: nohup ./retroDBS_coregistrationPreoperative.sh > NormalisationPreoperative >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH


# Step3: Bringing everything into the same space (preoperative -> MNI space)
echo "======================================================================"
echo
echo " Coregistering data to MNI if necessary ... "
echo

function coregister_PreoperativeResults() { # function to coregister the outputs from LeadDBS to MNI space (ICBM152-2009c_symmetric)
	input_pseud=$2	
	input_pseudPD25=$3
	
	antsRegistrationSyNQuick.sh -d 3 \
		-f /$1/mni_icbm152_t1_tal_nlin_sym_09c.nii \
		-m $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_.nii" \
		-o $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_ 
	
	antsApplyTransforms \
	  -d 3 \
	  -i $1/mni_icbm152_t1_tal_nlin_sym_09c_mask.nii \
	  -r $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_Warped.nii.gz \
	  -t [ $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_0GenericAffine.mat, 1 ] \
	  -t $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_1InverseWarp.nii.gz \
	  -o $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz

	# Resample images and bring to same space
	ResampleImage 3 $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz 1x1x1 0 4

	ResampleImage 3 $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_.nii" $1/preoperative_planningNIFTI/${input_pseud}/"resampled_${input_pseud}_.nii" 1x1x1 0 4
	  
	mrtransform $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz -template $1/preoperative_planningNIFTI/${input_pseud}/resampled_"${input_pseud}_.nii" -oversample 1 -interp linear $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz -force
	  
	# Get skull-stripped imaged in preoperative space; 
	ImageMath 3 $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_noskull.nii" m $1/preoperative_planningNIFTI/${input_pseud}/resampled_"${input_pseud}_.nii"  $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz


	# bring preoperative imaging to MNI space using the transformatio matrix
	flirt -in $1/preoperative_planningNIFTI/${input_pseud}/"resampled_${input_pseud}_.nii" \
		-ref $1/mni_icbm152_t1_tal_nlin_sym_09c.nii \
		-dof 12 \
		-out $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}-ICBM.nii" \
		-omat $1/segmentationPD25/${input_pseudPD25}"-T1nav-N4brain-icbm.mat"

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
	coregister_PreoperativeResults ${PWD} $subj_no $subj_noPD25 & 
done
wait

echo "          ...done coregistering preoperative imaging into MNI space for all subjects. Please perform visual checks"
echo
echo "================================================================"


# Step3: Bringing everything into the same space (preoperative -> MNI space)
echo "======================================================================"
echo
echo " Transforming data of STN segmentation (preoperative) to MNI ... "
echo


function transform_PreoperativeSegmentation() { # function to transform the peroperative segmentation of the STN according to Step3

	for data2rename in $3/*BURNED-IN*.nii
	do
		filename_data=$(basename $data2rename)
		filename_data=${filename_data//\#/}
		
		
		
		
		antsApplyTransforms \
			-d 3 \
			-i $data2rename \
			-r $3/preoperative2MNI_Warped.nii.gz \
			-t $3/preoperative2MNI_1Warp.nii.gz \
			-t $3/preoperative2MNI_0GenericAffine.mat \
			-o $3/"Warped_${filename_data}"
		fslchfiletype NIFTI_GZ $3/"Warped_${filename_data}.nii" $3/"Warped_${filename_data}.nii.gz"
		rm -rf $3/"Warped_${filename_data}.nii"
		
		antsApplyTransforms \
			-d 3 \
			-i $data2rename \
			-r $3/preoperative2SST_Warped.nii.gz \
			-t $3/preoperative2SST_1Warp.nii.gz \
			-t $3/preoperative2SST_0GenericAffine.mat \
			-o $3/"Warped_SST_${filename_data}"
		fslchfiletype NIFTI_GZ $3/"Warped_SST_${filename_data}.nii" $3/"Warped_SST_${filename_data}.nii.gz"
		rm -rf $3/"Warped_SST_${filename_data}.nii"
		
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
	#transform_PreoperativeSegmentation ${PWD} $subj_no $SUBJ_DIR & 
	find ${PWD}/preoperative_planningNIFTI/ -type f -name "Warped_Warped*" -exec rm {} \; # removes files that have been preprocessed twice 

done
wait

echo "          ...done applying transformations for all subjects. Please perform visual checks"
echo
echo "================================================================"

