#!/bin/bash
# this script is a helper function which is used in cases, where registration ran into memory issues and the inverse operation was performed:
# that is T1 -> registereed on t2. With the inverse of theis registration, the final results can be obtained. This was necessary for subj12 and subj52 
# for this purpose, ANTs should be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted 
# (ANTSPATH)


export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH


${ANTSPATH}antsApplyTransforms -d 3 \
-i /home/david/Projects/retroDBS/convertedImaging/subj12_t2_3D_sag_p2_defaced.nii\
-r /home/david/Projects/retroDBS/convertedImaging/subj12_T1_3D_ganzer_Kopf_defaced.nii \
-o ${PWD}/tmpWarped.nii.gz \
-t /home/david/Projects/retroDBS/registeredImaging/subj12_t2_spc_1InverseWarp.nii.gz \
-t [/home/david/Projects/retroDBS/registeredImaging/subj12_t2_spc_0GenericAffine.mat, 1] \
-n GenericLabel \
-v 1
