#!/bin/bash
FSRCS="src/datatypes.F90 \
       src/io_mod.F90 \
       src/soil.F90 \
       src/vegetation.F90 \
       src/BiomeE.F90 \
       src/main.F90"

CPPFLAGS=''
#CPPFLAGS+="-DHydro_test"
#CPPFLAGS+="-DDBEN_run"


fparameter='./para_files/parameters_CRU_BCI.nml'
gfortran -o ess $FSRCS $CPPFLAGS
sed -e "50s/s1,/2.0,/" \
-e "50s/s2,/0.05,/" \
-e "74s/s,/0.0006,/" \
-e "81s/s,/0.02,/" \
-e "85s/s,/70.5,/" $fparameter > ./para_files/input.nml
./ess ./para_files/input.nml

rm ./para_files/input.nml
rm ess
rm esdvm.mod
rm datatypes.mod
rm io_mod.mod
rm soil_mod.mod
rm biomee_mod.mod
