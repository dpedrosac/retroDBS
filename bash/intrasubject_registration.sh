#!/bin/bash
# this script intends to register t2-weighted sequences to t1-weighted ones for all subjects listed in the metadata csv-file 
# for this purpose, ANTs should be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted 
# (ANTSPATH, INPUT_DIR, OUTPUT_DIR, METADATA)

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
INPUT_DIR=${PWD}/convertedImaging/
OUTPUT_DIR=${PWD}/registeredImaging/
METADATA=${PWD}/metadata/metadata_retroDBS.csv

if [[ ! -d $OUTPUT_DIR ]];
  then
  
  echo
  echo "--------------------------------------------------------------------------------------"
  "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
  echo "--------------------------------------------------------------------------------------"
  echo

  mkdir -p $OUTPUT_DIR
  fi

  echo "--------------------------------------------------------------------------------------"
  "Realigning t2-weighted sequences to t1-weighted ones according to metadata"
  echo "--------------------------------------------------------------------------------------"


OLDIFS=$IFS
IFS=','
[ ! -f $METADATA ] && { echo "$METADATA file not found"; exit 99; }
while read Surname Name pseud rest
do
	echo
	echo "--------------------------------------------------------------------------------------"
	echo "Registering: $pseud" 
	echo 
	idx1=${pseud}"_t1*defaced.nii"
	FILENAME_T1=$(find ${INPUT_DIR} -iname "$idx1")	

	idx2=${pseud}"_t2*.nii"
	FILENAME_T2=$(find ${INPUT_DIR} -iname "$idx2")	

	if [[ -z "$FILENAME_T1" || -z "$FILENAME_T2" ]]; then
			echo "Either the preprocessed T1- or T2-weighted imaging is missing. Proceeding with next subject..." 
		else
			filename_check=$OUTPUT_DIR/${pseud}_t2_spc_Warped.nii.gz
			if [[ ! -e $filename_check ]];
			then 
				echo "Registration of T2-weighted imaging to T1-weighted sequences using ANTs routines"
				${ANTSPATH}/antsRegistrationSyNQuick.sh -d 3 \
					-f $FILENAME_T1  \
					-m $FILENAME_T2 \
					-o $OUTPUT_DIR/${pseud}_t2_spc_ \
					# -t a \
					-j 1

				echo
				echo "--------------------------------------------------------------------------------------"
				echo " Done registering images for subj: $pseud"
				echo "--------------------------------------------------------------------------------------"
				echo
			else
				echo "Registration of T2-weighted imaging to T1-weighted sequences using ANTs routines for subj: $pseud already finished."
			fi
		fi

	done < $METADATA
IFS=$OLDIFS
