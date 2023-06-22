#!/bin/bash
# author: David Pedrosa
# version: 2023-05-04, modified 2023-06-22; added step 7
# Explanation of the analysis pipeline for retroDBS


# Step 1: Extract DICOM content to nifti files; all necessary sequences for the MRI are selected and the rest is deleted (./bash/retroDBS_dcm2nii.sh)
# Step 2: Deface and anonimise data in general so that no patient specific information may be found (./bash/retroDBS_dcm2nii.sh or ./bash/retroDBS_defaceStandalone.sh)
# Step 3: Register all MR-sequences to "common space" (./bash/retroDBSintrasubject_registration.sh) 
# Step 4: Create a study specific template if needed (./bash/retroDBS_createStudySpecificTemplate.sh)

# Further steps outside bash: VTA were generated using LeadDBS with the pre- and postoperative imaging and using the FastField algorithm (./data/VTA/). Besides, a different segmentation of the STN was obtained using the algorithms from Ximing Xiao (./data/segmentationPD25/). Finally, preoperative planning was obtained from the planning software along with the segmentation of the imaging (./data/preoperative_planningDCM), converted in a NIFTI-file (./data/preoperative_planningNIFTI)

# Step5: Bringing everything into same space, i.e. atlas_t1 (leadDBS) -> MNI (./bash/retroDBS_coregistrationAtlasTx.sh)
# Step6: Bringing everything into same space, i.e. preoperativeNIFTI (neurosurgery) -> MNI (./bash/retroDBS_coregistrationPreoperative.sh)

# "======================================================================"
# Definitions of space, etc. at this point
# ./data/PD25/subj_{x}/						-> MNI space
# ./data/VTA/subj_{x}/atlas_t_{1/2}.nii.gz			-> native space -> MNI space (Step 5)
# ./data/preoperative_planningNIFTI/subj_{x}			-> native space -> MNI space (Step 5)
# ./data/VTA/subj_{x}/stimulartions_retroDBS/vat_left.nii.gz	-> MNI space
# "======================================================================"

# Step 7: Align preoperative data with the rest, i.e. dice coefficient (./bash/retroDBS_diceAnalyses.sh)

