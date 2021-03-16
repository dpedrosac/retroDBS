#!/bin/bash
# Purpose: Read Comma Separated CSV File
# Author: Kenan Steidel, Philipp Loehrer and David Pedrosa under MIT
# -----------------------------------------------------------------

export PATH2DCM2NIIX= #~/usr/local/fsl/
export PATH=${PATH2DCM2NIIX}:$PATH

# Read csv-file to get the necessary information
INPUT=iPS-DBS.csv

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
    dcm2nii
  done
done < $INPUT
IFS=$OLDIFS



# Convert images.
cmd="$exenam $endian -b y -z n -f %p_%s -o $outdir $indir"

echo "Running command:"
echo $cmd

$cmd


# Validate JSON.
exists python &&
    {
        printf "\n\n\nValidating JSON files.\n\n\n"
        for file in $outdir/*.json; do
            echo -n "$file "
            ! python -m json.tool "$file" > /dev/null || echo " --  Valid."
        done
        printf "\n\n\n"
    }
