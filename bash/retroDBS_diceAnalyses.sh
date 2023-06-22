#!/bin/bash
# author: David Pedrosa
# version: 2023-06-15, # first version of analysis pipeline for differences between the segmentations using the 
# dice coefficient
# run as: nohup ./retroDBS_diceAnalyses.sh > StatisticalAnalyses >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH

# Create results folder
OUTPUT_DIR=${CURRENT_DIR}/results
if [[ ! -d $OUTPUT_DIR ]]; then
    mkdir -p $OUTPUT_DIR
fi

# Step6: Statistical analyses
echo "======================================================================"
echo
echo " Obtaining Dice coefficients between VTA and segmentations ... "
echo

function stats_on_data() # function to obtain results; before, some further processing is needed
{

# Get input sorted
input_pseud=$2
input_pseudPD25=$3

# Check for existence of all necessary files for the next steps
files=($1/segmentationPD25/"${input_pseudPD25}-nuclei-seg.nii" \
$1/VTA/${input_pseud}/stimulations/MNI_ICBM_2009b_NLIN_ASYM/retroDBS/vat_right.nii \
$1/VTA/${input_pseud}/stimulations/MNI_ICBM_2009b_NLIN_ASYM/retroDBS/vat_left.nii)
for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "File '$file' for subj '$input_pseud' does not exist. Stopping the script."
        return 1
    fi
done

## ====================================================================== ##
# Align VTA and segmentation with same spacing and same dimensions
filename_outputLeft=$4/resampledVTAleft.nii
ResampleImage 3 $1/VTA/${input_pseud}/stimulations/MNI_ICBM_2009b_NLIN_ASYM/retroDBS/vat_left.nii \
$filename_outputLeft .5x.5x.5 0 4

filename_outputRight=$4/resampledVTAright.nii
ResampleImage 3 $1/VTA/${input_pseud}/stimulations/MNI_ICBM_2009b_NLIN_ASYM/retroDBS/vat_right.nii \
	$filename_outputRight .5x.5x.5 0 4

filename_input=$1/segmentationPD25/"${input_pseudPD25}"-nuclei-seg.nii
filename_outputPD25seg=$4/resampledPD25.nii

ResampleImage 3 $filename_input $filename_outputPD25seg .5x.5x.5 0 4

## ====================================================================== ##
# Bring the 'resliced' VTA into same dimension as segmentation (PD25)
filename_outputLeft_temp=$4/resampledVTAleft_temp.nii
mrgrid $filename_outputLeft regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputLeft_temp -fill 0

filename_outputRight_temp=$4/resampledVTAright_temp.nii
mrgrid $filename_outputRight regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputRight_temp -fill 0

## ====================================================================== ##
# Threshold image, so that only the VTA is kept as a mask
ThresholdImage 3 $filename_outputLeft_temp $filename_outputLeft .95 1.4 1 0 
ThresholdImage 3 $filename_outputRight_temp $filename_outputRight .95 1.4 1 0 

## ====================================================================== ##
# Analyses of preoperativeNIFTI files in order to get the DICE coefficients

filename_input=$(find $1/preoperative_planningNIFTI/${input_pseud} -type f -name 'Warped*BURNED-IN*Left*[0-9].nii')
filename_outputLeftpreop=$4/resampledSTNleft_preop.nii
ResampleImage 3 $filename_input $filename_outputLeftpreop .2x.2x.2 0 4

filename_input=$(find $1/preoperative_planningNIFTI/${input_pseud} -type f -name 'Warped*BURNED-IN*Right*[0-9].nii')
filename_outputRightpreop=$4/resampledSTNright_preop.nii
# ResampleImage 3 $1/VTA/${input_pseud}/stimulations/MNI_ICBM_2009b_NLIN_ASYM/retroDBS/vat_right.nii \
# 	$filename_outputRight .5x.5x.5 0 4

# Right side is missing because of problems with filenames! 

filename_outputLeft_preop_temp=$4/resampled_preop_left_temp.nii
mrgrid $filename_outputLeftpreop regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputLeft_preop_temp -fill 0

# filename_outputRight_preop_temp=$4/resampled_preop_right_temp.nii
# mrgrid $filename_outputRightpreop regrid -template $filename_outputPD25seg -scale 1,1,1 $filename_outputRight_preop_temp -fill 0


# Threshold image, so that only the VAT is kept as a mask
ThresholdImage 3 $filename_outputLeft_preop_temp $filename_outputLeftpreop .95 1.4 1 0 
# ThresholdImage 3 $filename_outputRight_temp $filename_outputRight .95 1.4 1 0 

## ====================================================================== ##
# Select different parts of the segmentation and run analyses (DICE coefficients)
ROI=("RN_left" "RN_right" "STN_left" "STN_right" "SN_left" "SN_right")
for ((i=1; i<=6; i++)) # this loop is necessary since multiply labelled images do not work.
do
    range1=$(echo "$i - 0.3" | bc) # this part serves as lower limit to select only the ROI
    range2=$(echo "$i + 0.7" | bc) # this part serves as upper limit to select only the ROI
	
	# Select only ROI of interest according to defined list before
	ThresholdImage 3 $filename_outputPD25seg $4/segmentation_temp.nii $range1 $range2 1 0 
	
	# Dice coefficient is estimated for both sides separately. which doesn't make much sense but is easier to code.
	filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_PD25left"
	ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputLeft

	filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_PD25right"
	ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputRight

	# Dice coefficient is estimated for both sides separately. which doesn't make much sense but is easier to code.
	filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_preopleft"
	ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputLeftpreop

	#filename_outDice=$1/results/"segmentation_${input_pseud}_${ROI[i-1]}_VTA_preopright"
	#ImageMath 3 $filename_outDice DiceAndMinDistSum $4/segmentation_temp.nii $filename_outputRightpreop
	
done

}

num_processes=10
for SUBJ_DIR in ${PWD}/preoperative_planningNIFTI/subj*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Extracting Dice coefficients at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${SUBJ_DIR##*/}"
	subj_no=$(echo ${SUBJ_DIR##*/} | cut -d "^" -f 2)
	prefix="Sub-"
	number="${subj_no//[[:alpha:]]}"
	subj_noPD25="${prefix}${number}"
	TMP_DIR=${PWD}/results/temp/´tmp$RANDOM # create temporary file to save data to
	mkdir -p $TMP_DIR
	
	stats_on_data ${PWD} $subj_no $subj_noPD25 $TMP_DIR & 
done
wait

echo "          ...done extracting dice coefficients for all subjects!"
echo
echo "================================================================"


