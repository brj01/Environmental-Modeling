#!/bin/bash


FSRCS="src/datatypes.F90 \
       src/io_mod.F90 \
       src/soil.F90 \
       src/vegetation.F90 \
       src/BiomeE.F90 \
       src/main.F90"
CPPFLAGS=''
#CPPFLAGS+='-DHydro_test'
#CPPFLAGS+=' -DDemographyOFF'

fparameter='./para_files/parameters_CRU_BCI_forcing.nml'

#### THIS IS A FUNCTION
simulation_fcn () {	
	
	IFS=' ' read -a x <<< $1
	name1=${x[0]}
	name2=${x[1]}
	name3=${x[2]}
	name4=${x[3]}
	mkdir simulation$2
	python3 ./Auxiliary/generate_forcing.py name1 name2 name3 name4 
        gfortran -J./simulation$2 -o ./simulation$2/ess $FSRCS $CPPFLAGS
        sed -e "s/'BiomeE_P0_BCI_aCO2_00'/'simulation$2'/" \ $fparameter > ./para_files/input$2.nml
        ./simulation$2/ess ./para_files/input$2.nml
}
####

python3 ./Auxiliary/generate_cases_forcing.py
IFS=$'\n' read -d '' -r -a lines < ./para_files/cases.txt
len=${#lines[@]}

IFS=' ' read -a x <<< "${lines[0]}"

#job=0

for((i=1;i<$len;i++))
do
	simulation_fcn "${lines[i]}" $i &
#	((job+=1))
#	if [ $job = 10 ];
#	then
#		wait
#		job=0
#	fi
done



