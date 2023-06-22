#!/bin/bash
# Purpose: Read Comma Separated CSV File and convert DICOM to nifti with
# Chris Rorden's software (dcm2niix, cf. https://github.com/rordenlab/dcm2niix)
# Author: Kenan Steidel, Philipp Loehrer, and David Pedrosa under MIT
# -----------------------------------------------------------------

CURRENT_DIR=${PWD}
METADATA=${PWD}/metadata/DTIdbs.csv

if [[ ! -f $METADATA ]]; then
    echo
    echo "--------------------------------------------------------------------------------------"
    echo " Metadata unavailable. Make sure that csv-file called 'DTI.dbs.csv' is present "
    echo "--------------------------------------------------------------------------------------"
    echo
    exit
fi

# Creates virtual environment if not present, activates it, and tries to install packages needed
venv_DIR=${CURRENT_DIR}/venv
if [[ ! -d ${venv_DIR} ]]; then
    echo
    echo "--------------------------------------------------------------------------------------"
    echo " Virtual environment is needed. Processing with activation"
    echo "--------------------------------------------------------------------------------------"
    echo

    python3 -m venv ${venv_DIR}
    source venv ${venv_DIR}/venv/bin/activate
    pip install pydeface
fi

OLDIFS=$IFS
IFS=','
[ ! -f $METADATA ] && { echo "$METADATA file not found"; exit 99; }
while read ID Surname Name pseud rest; do
    INPUT_DIR=${CURRENT_DIR}/${pseud}
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "Defacing: $pseud"
    echo

    OUTPUT_DIR=${CURRENT_DIR}/defaced/${pseud}
    if [[ ! -d $OUTPUT_DIR ]]; then
        mkdir -p $OUTPUT_DIR
    fi

    i=1
    for f in ${INPUT_DIR}/*.nii; do
        #prog "$i"
        echo " ... ${f}"
        sleep .1   # do some work here
        pydeface $f
        i=$((i+1))
    done

done < $METADATA

echo
echo " Done!"
echo
echo "--------------------------------------------------------------------------------------"

