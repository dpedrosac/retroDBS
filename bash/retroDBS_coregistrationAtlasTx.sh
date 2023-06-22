#!/bin/bash
# author: David Pedrosa
# version: 2023-05-28, # debugging completed and separated functions so that parallel processing is possible
# script preprocessing data from VTA generation and segmentation
# run as: nohup ./retroDBS_coregistrationAtlasTx.sh > NormalisationAtlases >&1 & disown

CURRENT_DIR=${PWD}
export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH

## Definitions of space, etc.
# PD25				-> MNI space
# atlas_t1/2.nii.gz	-> native space -> MNI space (step 1)
# lh/rh 			-> native space -> MNI space (step 1)
# VTAright/left		-> MNI space
# preoperative 		-> native space -> MNI space (step 3)

# Step1: Bringing everything into same space (atlas_t1 -> MNI space)
echo "======================================================================"
echo
echo " Coregistering data to MNI if necessary ... "
echo

function coregister_leadResults() # function to coregister the outputs from LeadDBS to MNI space
{
input_pseud=$2
if [[ ! -e $1/VTA/${input_pseud}/native2MNI_0GenericAffine.mat ]]; then
	antsRegistrationSyNQuick.sh -d 3 \
	-f /$1/t1.nii \
	-m $1/VTA/${input_pseud}/anat_t1.nii \
	-o $1/VTA/${input_pseud}/native2MNI_ 
fi
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


