#!/bin/bash
# Purpose: Read Comma Separated CSV File and convert DICOM to nifti with
# Chris Rorden's software (dcm2niix, cf. https://github.com/rordenlab/dcm2niix)
# Author: Kenan Steidel, Philipp Loehrer and David Pedrosa under MIT
# -----------------------------------------------------------------

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"



# check for dcm2nii existence at default location/opt/bin (is that right??)
if ! command -v COMMAND &> /dev/null #add dcm2nii
then
    echo "COMMAND could not be found, building dcm2nii from scratch to default folder"
    TMP_DIR=tmp$RANDOM
    mkdir -p $TMP_DIR    
    
    cd TMP_DIR
    git clone https://github.com/rordenlab/dcm2niix.git
    cd dcm2niix
    mkdir build && cd build
    cmake ..
    make
    rm -rf TMP_DIR
fi

export PATH2DCM2NIIX= #~/usr/local/??/
export PATH=${PATH2DCM2NIIX}:$PATH

# Read csv-file to get the necessary information
INPUT=../../iPS-DBS.csv
INPUT_DIR=abc
OUTPUT_DIR=../../convertedImaging/
if [[ ! -f INPUT_DIR ]] ; then
    echo 'Input directory is not defined, aborting the script.'
    exit
fi

# Creates virtual environment if not present, activates it and tries to install packages needed 
venv_DIR=../../venv/
if [[ ! -f venv_DIR ]] ; then
    echo 'creating virtual environment for defacing.'
    python3 -m venv ../../venv
    source ../../venv/bin/activate
    pip install pydeface
fi


imagingModality=( CT MRI )
OLDIFS=$IFS
IFS=','
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read Surname Name Pseud
do
	echo "converting Surname : $Surname, $Name and saving as $Pseud" 
	# echo "Name : $Name"
	# echo "Pseudonym : $Pseud"

  for i in "${imagingModality[@]}"
  do  
    echo "======== converting $i imaging"
    PATH2DCM2NIIX/dcm2niix.sh 
    -ba y \
    -f $Pseud_$i%s%d.nii.g\
    -i $INPUT_DIR/$Surname_$Name$i/ \
    -o OUTPUT_DIR
  done
done < $INPUT
IFS=$OLDIFS
