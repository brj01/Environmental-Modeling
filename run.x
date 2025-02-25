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
	mkdir $2$3$4
        gfortran -J./$2$3$4 -o ./$2$3$4/ess $FSRCS $CPPFLAGS
        sed -e "s/'BiomeE_P0_BCI_aCO2_00'/'$2$3$4'/" \
        -e "s/Sc_prcp = 1/Sc_prcp = ${x[0]}/" \
        -e "s/Tchange = 0/Tchange = ${x[1]}/" $fparameter > ./para_files/input$2$3$4.nml
        ./$2$3$4/ess ./para_files/input$2$3$4.nml
}
####

python3 ./Auxiliary/generate_cases_forcing.py
IFS=$'\n' read -d '' -r -a lines < ./para_files/cases.txt
len=${#lines[@]}

IFS=' ' read -a x <<< "${lines[0]}"
name1=${x[0]}
name2=${x[1]}
job=0

for((i=1;i<$len;i++))
do
	simulation_fcn "${lines[i]}" $name1 $name2 $i &
	((job+=1))
	if [ $job = 10 ];
	then
		wait
		job=0
		rm -r Sc_prcpTchange*
		rm ./para_files/inputSc_prcpTchange*		
	fi
done

rm -r Sc_prcpTchange*
rm ./para_files/inputSc_prcpTchange*		
rm ./para_files/cases.txt


