#!/bin/bash
# Purpose: Read Comma Separated CSV File and convert DICOM to nifti with
# Chris Rorden's software (dcm2niix, cf. https://github.com/rordenlab/dcm2niix)
# Author: Kenan Steidel, Philipp Loehrer and David Pedrosa under MIT
# -----------------------------------------------------------------

CURRENT_DIR=${PWD}
METADATA=${PWD}/metadata/iPS-DBS.csv

if [[ ! -f $METADATA ]] ; then
	echo
	echo "--------------------------------------------------------------------------------------"
	echo " Metadata unavailable. Make sure that csv-file is present "
	echo "--------------------------------------------------------------------------------------"
	echo
	exit
fi

INSTALL_DIR=/opt/dcm2niix # directory at which dcm2niix will be built
export PATH2DCM2NIIX=${INSTALL_DIR}/build/bin/
export PATH=${PATH2DCM2NIIX}:$PATH

echo
echo "--------------------------------------------------------------------------------------"
echo " Checking 'dcm2niix' existence to process DICOMs... "

if ! command -v dcm2niix &> /dev/null #add dcm2nii
then
	echo "			dcm2niix is not installed in the default directory, building it from source"
	echo "--------------------------------------------------------------------------------------"
	echo

    sudo rm -rf ${INSTALL_DIR}
	echo "dcm2niix could not be found, building it from scratch to default folder /opt/dcm2niix/"
    cd /opt/
	sudo git clone https://github.com/rordenlab/dcm2niix.git
	sudo chmod 755 -R ${INSTALL_DIR}/*

	cd dcm2niix
    sudo mkdir build && cd build
    sudo cmake ..
    sudo make
	cd ${DIR}
else
	echo "			dcm2niix is built and can be called. Proceeding!"
	echo "--------------------------------------------------------------------------------------"
	echo
fi

# Read csv-file to get the necessary information
INPUT_DIR=${CURRENT_DIR}/testdata
if [[ ! -f ${INPUT_DIR} ]] ; then
	echo
	echo "--------------------------------------------------------------------------------------"
	echo " Directory of DICOM folders not defined. Aborting the script "
	echo "--------------------------------------------------------------------------------------"
	echo
    # exit
fi

OUTPUT_DIR=${CURRENT_DIR}/convertedImaging
if [[ ! -d $OUTPUT_DIR ]];
  then
    mkdir -p $OUTPUT_DIR
  fi

# Creates virtual environment if not present, activates it and tries to install packages needed 
venv_DIR=${CURRENT_DIR}/venv
if [[ ! -d ${venv_DIR} ]] ; then
	echo
	echo "--------------------------------------------------------------------------------------"
	echo " Virtual environment is needed. Processing with activation"
	echo "--------------------------------------------------------------------------------------"
	echo

    python3 -m venv ${venv_DIR}
    source venv ${venv_DIR}/venv/bin/activate
    pip install pydeface
fi


imagingModality=( CT MRI )
OLDIFS=$IFS
IFS=','
[ ! -f $METADATA ] && { echo "$METADATA file not found"; exit 99; }
while read Surname Name pseud rest
do
	echo
	echo "--------------------------------------------------------------------------------------"
	echo "Converting: $Surname, $Name to nifti as $pseud" 
	echo 
	
  for i in "${imagingModality[@]}"
    do    
	TEMP_FOLDER=${INPUT_DIR}/"${Surname,,}_${Name,,}${i}/"
	echo " $i-sequences from $TEMP_FOLDER"
	
	if [[ ! -d ${TEMP_FOLDER} ]]; then
		echo
		echo " ... folder ${TEMP_FOLDER} inexistent. Continuing!"
		echo
	
	else
		echo
		echo " ... extracting sequences ..."
		echo

		${PATH2DCM2NIIX}/dcm2niix \
		-b y \
		-ba y \
		-f ${pseud}_$i_%d.nii.gz\
		-o ${OUTPUT_DIR} \
		${TEMP_FOLDER}

	fi
  done
echo "--------------------------------------------------------------------------------------"

done < $METADATA
IFS=$OLDIFS


# A part is needed where only sequences of interest are maintained 

# Defacing with python package should be included