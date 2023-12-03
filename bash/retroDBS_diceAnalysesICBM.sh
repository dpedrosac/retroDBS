#!/bin/bash
# author: David Pedrosa
# version: 2023-10-12, # new version using the standardised (ICBM) data for all segmentations
# run as: nohup ./retroDBS_diceAnalysesICBM.sh > StatisticalAnalysesICBM >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH

# Create results folder
OUTPUT_DIR=${CURRENT_DIR}/results
if [[ ! -d $OUTPUT_DIR ]]; then
    mkdir -p $OUTPUT_DIR
fi

# Create results folder
SEGMENTATION_DIR=${CURRENT_DIR}/segmentation
if [[ ! -d $SEGMENTATION_DIR ]]; then
    mkdir -p $SEGMENTATION_DIR
fi


# Step6: Statistical analyses
echo "======================================================================"
echo
echo " Obtaining Dice coefficients between VTA and segmentations ... "
echo

function stats_on_data() { # function to obtain results; before, some further processing is needed
	input_pseud=$2
	input_pseudPD25=$3

	OUTPUT_DIR=$1/results
	if [[ ! -d $OUTPUT_DIR ]]; then
	    mkdir -p $OUTPUT_DIR
	fi

	## ====================================================================== ##
	# Filenames of interest and check for its existence
	filename_outputLeft=$1/VATicbm/${input_pseud}/"ICBM_vat_left.nii.gz"
	filename_outputRight=$1/VATicbm/${input_pseud}/"ICBM_vat_right.nii.gz"
	filename_outputPD25seg=$1/segmentationPD25/${input_pseudPD25}"-nuclei-seg.nii"

	# Check for existence of all necessary files for the next steps, i.e. segmented PD25 and VAT
	files=( $filename_outputPD25seg $filename_outputLeft $filename_outputRight )
	for file in "${files[@]}"; do
	    echo "Processing file: $file"
	    if [ ! -f "$file" ]; then
		echo "File '$file' for subj '$input_pseud' does not exist. Stopping the script."
		return 1
	    fi
	done

	filename_outputLeft_resampled=$4/resampled_ICBM_vat_left.nii
	mrgrid $filename_outputLeft regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputLeft_resampled -fill 0 -force

	filename_outputRight_resampled=$4/resampled_ICBM_vat_right.nii
	mrgrid $filename_outputRight regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputRight_resampled -fill 0 -force

	## ====================================================================== ##
	# Threshold image, so that only the VTA is kept as a mask and run stats
	ThresholdImage 3 $filename_outputLeft $filename_outputLeft .2 1.4 1 0 
	ThresholdImage 3 $filename_outputRight $filename_outputRight .2 1.4 1 0 
	LabelGeometryMeasures 3 $filename_outputLeft none $1/results/"measures_${input_pseud}_VTA.left.csv"
	LabelGeometryMeasures 3 $filename_outputRight none $1/results/"measures_${input_pseud}_VTA.right.csv"

	## ====================================================================== ##
	# Analyses of preoperativeNIFTI files in order to get the DICE coefficients

	filename_inputLeftpreop=$(find $1/preoperative_planningNIFTI/${input_pseud}/ -type f -name "resampled-ICBM_${input_pseud}*Left*.nii.gz")
	filename_inputRightpreop=$(find $1/preoperative_planningNIFTI/${input_pseud}/ -type f -name "resampled-ICBM_${input_pseud}*Right*.nii.gz")

	filename_outputLeftpreop=$4/resampledSTNleft_preop.nii
	filename_outputRightpreop=$4/resampledSTNright_preop.nii

	filename_outputLeft_preop_temp=$4/resampled_preop_left_temp.nii
	mrgrid $filename_inputLeftpreop regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputLeft_preop_temp -fill 0 -force
	LabelGeometryMeasures 3 $filename_outputLeftpreop none $1/results/"measures_${input_pseud}_STN_preop.left.csv"

	filename_outputRight_preop_temp=$4/resampled_preop_right_temp.nii
	mrgrid $filename_inputRightpreop regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputRight_preop_temp -fill 0 -force
	LabelGeometryMeasures 3 $filename_outputRightpreop none $1/results/"measures_${input_pseud}_STN_preop.right.csv"

	# Threshold image, so that only the VAT is kept as a mask
	ThresholdImage 3 $filename_outputLeft_preop_temp $filename_outputLeftpreop .2 1.4 1 0 
	ThresholdImage 3 $filename_outputRight_preop_temp $filename_outputRightpreop .2 1.4 1 0 

	# Get LabelMeasures
	LabelGeometryMeasures 3 $4/resampledVTAleft.nii none $1/results/"measures_${input_pseud}_VTA.left.csv"
	LabelGeometryMeasures 3 $4/resampledVTAright.nii none $1/results/"measures_${input_pseud}_VTA.right.csv"
	LabelGeometryMeasures 3 $4/resampledSTNleft_preop.nii none $1/results/"measures_${input_pseud}_STN_preop.left.csv"
	LabelGeometryMeasures 3 $4/resampledSTNright_preop.nii none $1/results/"measures_${input_pseud}_STN_preop.right.csv"    


	## ====================================================================== ##
	# Select different parts of the segmentation and run analyses (DICE coefficients)
	ROI=("Ruber_left" "Ruber_right" "STN_left" "STN_right" "SN_left" "SN_right")
	for ((i=1; i<=6; i++)) # this loop is necessary since multiply labelled images do not work.
	do
	    range1=$(echo "$i - 0.3" | bc) # this part serves as lower limit to select only the ROI
	    range2=$(echo "$i + 0.7" | bc) # this part serves as upper limit to select only the ROI
		
		# Select only ROI of interest according to defined list before
		ThresholdImage 3 $filename_outputPD25seg $4/segmentation_temp.nii $range1 $range2 1 0 
		LabelGeometryMeasures 3 $4/segmentation_temp.nii none $1/results/"measures_${input_pseud}_${ROI[i-1]}.csv"

		# Dice coefficient is estimated for both sides separately. which doesn't make much sense but is easier to code.
		filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_PD25_left"
		
		echo "ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputLef"
		echo "ranges: $range1 to $range2 ROI=${ROI[i-1]} and i = $i"
		echo "output file: $filename_outDice"

		ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputLeft_resampled

		filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_PD25_right"
		ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputRight_resampled

		# Dice coefficient is estimated for both sides separately. which doesn't make much sense but is easier to code.
		filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_preop_left"
		ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputLeftpreop

		filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_preop_right"
		ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputRightpreop
		
		filename_copy=$4/"mask_${ROI[i-1]}.nii"
		cp $4/segmentation_temp.nii $filename_copy
	done

}

num_processes=10
WORKING_DIR=${PWD}/"preoperative_planningNIFTI/subj*/"
for SUBJ_DIR in ${WORKING_DIR}     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Extracting Dice coefficients at multiple cores on $WORKING_DIR:"
	echo

	subj_no=$(echo $(basename "$SUBJ_DIR") | cut -d "^" -f 2)
	echo "Processing subj: ${subj_no}"
	prefix="Sub-"
	number="${subj_no//[[:alpha:]]}"
	subj_noPD25="${prefix}${number}"
	RESULTS_DIR=${PWD}/segmentation/${subj_no} # create temporary file to save data to
	mkdir -p $RESULTS_DIR
	
	stats_on_data ${PWD} $subj_no $subj_noPD25 $RESULTS_DIR & 
	find "${TMP_DIR}" -name "*temp*" -type f -exec rm {} \;

done
wait

echo "          ...done extracting dice coefficients for all subjects!"
echo
echo "================================================================"



X

