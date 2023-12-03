#!/bin/bash
# author: David Pedrosa
# version: 2023-10-15, # minor bugs such as the wrong template to normalise data
# script coregistering preoperative data to MNI space
# run as: nohup ./retroDBS_coregistrationPreoperativeICBM.sh > NormalisationPreoperative >&1 & disown

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
	res=.5

	# coregister preoperative data to MNI space (2009c non-linear, symmetric template) and apply transform to mask
	antsRegistrationSyNQuick.sh -d 3 \
		-f /$1/mni_icbm152_t1_tal_nlin_sym_09c_05.nii \
		-m $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_.nii" \
		-o $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_

	antsApplyTransforms \
	  -d 3 \
	  -i $1/mni_icbm152_t1_tal_nlin_sym_09c_05_mask.nii \
	  -r $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_Warped.nii.gz \
	  -t [ $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_0GenericAffine.mat, 1 ] \
	  -t $1/preoperative_planningNIFTI/${input_pseud}/preoperative2MNI_1InverseWarp.nii.gz \
	  -o $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz

	# Resample images (mask for preoperative data and preoperative data itself) and bring to same space (isotropic $res mm voxel)
	ResampleImage 3 $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz "$res"x"$res"x"$res" 0 4

	ResampleImage 3 $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_.nii" $1/preoperative_planningNIFTI/${input_pseud}/resampled_"${input_pseud}_.nii.gz" "$res"x"$res"x"$res" 0 4

	mrtransform $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz -template $1/preoperative_planningNIFTI/${input_pseud}/resampled_"${input_pseud}_.nii.gz" -oversample 1 -interp linear $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz -force

	# Get skull-stripped imaged in preoperative space by multioplying mask and preoperative data 
	ImageMath 3 $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_noskull.nii.gz" m $1/preoperative_planningNIFTI/${input_pseud}/"resampled_${input_pseud}_.nii.gz"  $1/preoperative_planningNIFTI/${input_pseud}/t1_maskPREOP.nii.gz

	# Apply linear transformation on individual data with the individual transformation from Yiming Xiao 
	flirt -in $1/preoperative_planningNIFTI/${input_pseud}/"${input_pseud}_noskull.nii.gz" \
		-ref $1/mni_icbm152_t1_tal_nlin_sym_09c_05_noskull.nii.gz \
		-applyxfm \
		-init $1/segmentationPD25/"${input_pseudPD25}-T1nav-N4brain-icbm.mat" \
		-out $1/preoperative_planningNIFTI/${input_pseud}/"resampled_${input_pseud}-ICBM.nii.gz"

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
	# coregister_PreoperativeResults ${PWD} $subj_no $subj_noPD25 & 
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
	input_pseud=$2
	input_pseudPD25=$4
	res=.5

	for data2rename in $3/*BURNED-IN*.nii
	do
		filename_data=$(basename $data2rename)
		filename_data=${filename_data//\#/}

		# Resample the preoperative segmentation to standard space (isotropic $res mm voxel)
		ResampleImage 3 $data2rename $3/"resampled_${filename_data}" "$res"x"$res"x"$res" 0 4

		echo "filename is: $3/resampled_${filename_data}"
		echo "template is: $3/${input_pseud}_noskull.nii.gz"

		# Transform everything to same dimensions as preoperative, skull-stripped data
		mrtransform $3/"resampled_${filename_data}"  \
		 -template $3/"${input_pseud}_noskull.nii" \
		 -oversample 1 \
		 -interp linear \
		 $3/"resampled_${filename_data}" \
		 -force

		# This step is necessary as the "strides" were different and so the dimensions did not matcgh
		mrconvert $3/"resampled_${filename_data}" -strides 1,2,3 $3/"resampled_${filename_data}" -force
		fslchfiletype NIFTI_GZ $3/"resampled_${filename_data}" $3/"resampled_${filename_data}.gz"
		rm -rf $3/"resampled_${filename_data}"

		# Apply ilnear transformation on individual data with the individual transformation from Yiming Xiao
		flirt -in $3/"resampled_${filename_data}.gz" \
			-ref $1/mni_icbm152_t1_tal_nlin_sym_09c_noskull.nii.gz \
			-applyxfm \
			-init $1/segmentationPD25/"${input_pseudPD25}-T1nav-N4brain-icbm.mat" \
			-out $3/"resampled-ICBM_${filename_data}.gz"
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
	find ${PWD}/preoperative_planningNIFTI/ -type f -name "resampled_resampled*" -exec rm {} \; # removes files that have been preprocessed twice 

done
wait

echo "          ...done applying transformations for all subjects. Please perform visual checks"
echo
echo "================================================================"

