#!/bin/bash
# Purpose: Read Comma Separated CSV File and convert DICOM to nifti with
# Chris Rorden's software (dcm2niix, cf. https://github.com/rordenlab/dcm2niix)
# Author: Kenan Steidel, Philipp Loehrer and David Pedrosa under MIT
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

INSTALL_DIR=/opt/dcm2niix # directory at which dcm2niix will be built
export PATH2DCM2NIIX=${INSTALL_DIR}/build/bin/
export PATH=${PATH2DCM2NIIX}:$PATH

echo
echo "--------------------------------------------------------------------------------------"
echo " Checking 'dcm2niix' existence to process DICOMs... "

if ! command -v dcm2niix &> /dev/null; then
    echo "            dcm2niix is not installed in the default directory, building it from source"
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
    echo "            dcm2niix is built and can be called. Proceeding!"
    echo "--------------------------------------------------------------------------------------"
    echo
fi

# Read csv-file to get the necessary information
# INPUT_DIR=${CURRENT_DIR}/testdata
INPUT_DIR="/media/dplab/retro_DBS/DAICOM"
if [[ ! -f ${INPUT_DIR} ]]; then
    echo
    echo "--------------------------------------------------------------------------------------"
    echo " Directory of DICOM folders not defined. Aborting the script "
    echo "--------------------------------------------------------------------------------------"
    echo
    # exit
fi

# OUTPUT_DIR=${CURRENT_DIR}/convertedImaging
OUTPUT_DIR=${CURRENT_DIR}/convertedImaging_MRI

if [[ ! -d $OUTPUT_DIR ]]; then
    mkdir -p $OUTPUT_DIR
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
    source ${venv_DIR}/bin/activate
    pip install pydeface
fi


# imagingModality=( CT MRT )
imagingModality=( MRT CT )
OLDIFS=$IFS
IFS=','
[ ! -f $METADATA ] && { echo "$METADATA file not found"; exit 99; }
while read ID Surname Name pseud rest; do
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "Converting: $Surname, $Name to nifti as $pseud"
    echo

    for i in "${imagingModality[@]}"; do
        DATA_FOLDER=${INPUT_DIR}/"${Surname,,}_${Name,,}${i}/"
        echo " $i-sequences from $DATA_FOLDER"

        if [[ ! -d ${DATA_FOLDER} ]]; then
            echo
            echo " ... folder ${DATA_FOLDER} inexistent. Continuing!"
            echo

        else
            echo
            echo " ... extracting sequences ..."
            echo

            TMP_DIR=${PWD}/tmp$RANDOM
            mkdir -p $TMP_DIR

            ${PATH2DCM2NIIX}/dcm2niix \
                -b y \
                -ba y \
                -f ${pseud}_$i_%d \
                -o ${TMP_DIR} \
                ${DATA_FOLDER}

            find ${TMP_DIR} \( -name "*t1_mpr*12ch*.*" -o -name "*t2_spc*12ch*.*" -o -name "*H30*.*" -o -name "*t2_spc*12CH*.*" -o -name "*t2_spc*12CH*.*" \) -exec cp {} ${OUTPUT_DIR} \;
            rm -rf ${TMP_DIR}
        fi
    done
    echo "--------------------------------------------------------------------------------------"

done < $METADATA
IFS=$OLDIFS
find ${OUTPUT_DIR} \( -name "*REFORMATION*" -o -name "*SCOUT*" \) -exec rm -rf {} \; #remove all scouts and reconstructions

# progress bar function
prog() {
    local w=80 p=$1;  shift
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.};
    # print those dots on a fixed-width space plus the percentage etc. 
}

FSLDIR=/usr/local/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

echo
echo "--------------------------------------------------------------------------------------"
echo
echo " Defacing data: "
echo
echo "--------------------------------------------------------------------------------------"

i=1
for f in ${OUTPUT_DIR}/*.nii; do
    #prog "$i"
    echo " ... ${f}"
    sleep .1   # do some work here
    pydeface $f
    i=$((i+1))
done

