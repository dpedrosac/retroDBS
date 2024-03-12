#!/bin/bash
# author: David Pedrosa
# version: 2023-12-02, # tidied up the code for readibility purposes
# script converting VTA as per LeadDBS software to ICBM space
# run as: nohup ./retroDBS_coregistrationVTA-ICBM.sh > CoregistrationVTA >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH

# Constants to use throughout the script
RESAMPLED_VOXEL_SIZE=.5
NUM_PROCESSES=10

# Create results folder
OUTPUT_DIR=${PWD}/VATicbm
mkdir -p $OUTPUT_DIR

# Function to coregister the outputs from LeadDBS from native to MNI space
function coregister_VTAestimations() { 
	input_pseud=$2
	input_pseudPD25=$3
	res=.5

	# Resample preoperative segmentation (isotropic $RESAMPLED_VOXEL_SIZE mm voxel)
	ResampleImage 3 $1/VTA/${input_pseud}/anat_t1.nii $1/VTA/${input_pseud}/"resampled_anat_t1.nii" "$RESAMPLED_VOXEL_SIZE"x"$RESAMPLED_VOXEL_SIZE"x"$RESAMPLED_VOXEL_SIZE" 0 4

	# coregister preoperative data to MNI space (2009c non-linear, symmetric template)
	flirt \
	-in $1/VTA/${input_pseud}/"resampled_anat_t1.nii" \
	-ref $1/preoperative_planningNIFTI/${input_pseud}/"resampled_${input_pseud}_.nii" \
	-dof 12 \
	-out $1/VTA/${input_pseud}/"${input_pseud}_native2preoperative.nii" \
	-omat $1/VTA/${input_pseud}/"${input_pseudPD25}-T1native2preoperative.mat"

	# in theory, this should work, but it has not for some reason. Two steps are necessary (see below)
	convert_xfm -omat $1/VTA/${input_pseud}/"${input_pseud}_native2IBCM.mat" -concat $1/VTA/${input_pseud}/$input_pseudPD25-T1native2preoperative.mat $1/segmentationPD25/$input_pseudPD25-T1nav-N4brain-icbm.mat
}


# Step 1: Coregistering LeadDBS results to different space
function process_subjects() {
for SUBJ_DIR in ${PWD}/preoperative_planningNIFTI/subj*; do     # list directories in the form "/tmp/dirname/"
	((i=i%NUM_PROCESSES)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Coregistering LeadDBS results to different space on $WORKING_DIR:"
	echo

	echo "Processing subj: ${SUBJ_DIR##*/}"
	subj_no=$(echo ${SUBJ_DIR##*/} | cut -d "^" -f 2)
	prefix="Sub-"
	number="${subj_no//[[:alpha:]]}"
	subj_noPD25="${prefix}${number}"
	coregister_VTAestimations ${PWD} $subj_no $subj_noPD25 & 
done
wait

echo "          ...done coregistering preoperative imaging into MNI space for all subjects. Please perform visual checks"
echo "================================================================"
}

# Call first function
process_subjects


# Function to transform the preoperative segmentation of the STN
function transform_PreoperativeSegmentation() { # function to transform the peroperative segmentation of the STN according to Step3
	input_pseud=$2
	input_pseudPD25=$4
	filename_vat=("vat_left.nii" "vat_right.nii")

	for filename in "${filename_vat[@]}"; do
		
		# Create results folder for each individual, if necessary
		output_dir=${OUTPUT_DIR}/${input_pseud}/
		mkdir -p ${OUTPUT_DIR}/${input_pseud}/

		echo "Processing: $filename of subj: $input_pseud"

		# resamples data and changes the ROI to the one in the anat_t1 file
		mrtransform $1/VTA/${input_pseud}/stimulations/native/retroDBS3.0/${filename} \
		 -template $1/VTA/${input_pseud}/resampled_anat_t1.nii \
		 -oversample 1 \
		 -interp linear \
		 ${OUTPUT_DIR}/${input_pseud}/"native_resampled_${filename}" -force

		# Transformation in 2 steps: i) native->preoperative and ii) preoperative-> MNI
		flirt -in ${OUTPUT_DIR}/${input_pseud}/"native_resampled_${filename}" \
		 -ref $1/preoperative_planningNIFTI/${input_pseud}/"resampled_${input_pseud}_.nii" \
		 -applyxfm -init $1/VTA/${input_pseud}/"${input_pseudPD25}-T1native2preoperative.mat" \
		 -out ${OUTPUT_DIR}/${input_pseud}/"preoperative_${filename}"

		flirt -in ${OUTPUT_DIR}/${input_pseud}/"preoperative_${filename}" \
		 -ref $1/mni_icbm152_t1_tal_nlin_sym_09c_05_noskull.nii.gz \
		 -applyxfm \
		 -init $1/segmentationPD25/"${input_pseudPD25}-T1nav-N4brain-icbm.mat" \
		 -out ${OUTPUT_DIR}/${input_pseud}/"ICBM_${filename}"


		fslchfiletype NIFTI_GZ ${OUTPUT_DIR}/${input_pseud}/"native_resampled_${filename}" ${OUTPUT_DIR}/${input_pseud}/"native_resampled_${filename}.gz"
		rm -rf ${OUTPUT_DIR}/${input_pseud}/"native_resampled_${filename}"
	done
}


# Step 2: Transforming VAT to MNI space
function transform_subjects() {
    for SUBJ_DIR in ${PWD}/preoperative_planningNIFTI/subj*; do
        ((i=i%NUM_PROCESSES)); ((i++==0)) && wait
        echo "======================================================================"
        echo
        echo "Transforming VAT to MNI space on $WORKING_DIR:"
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
    echo "================================================================"
}


# Call the second function
transform_subjects
