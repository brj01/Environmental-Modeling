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

fparameter='./para_files/parameters_CRU_BCI.nml'

#### THIS IS A FUNCTION
simulation_fcn () {    
    IFS=' ' read -a x <<< $1
    simulation_dir="simulation$2"
    mkdir $simulation_dir
    gfortran -J./$simulation_dir -o ./$simulation_dir/ess $FSRCS $CPPFLAGS
    sed -e "s/'BiomeE_P0_BCI_aCO2_00'/'$simulation_dir'/" \
    -e "74s/s,/${x[0]},/" \
    -e "81s/s,/${x[1]},/" \
    -e "85s/s,/${x[2]},/" \
    -e "50s/s1,/${x[3]},/" \
    -e "50s/s2,/${x[4]},/" $fparameter > ./para_files/simulation$2.nml || { echo "Error in sed command"; exit 1; }
    ./simulation$2/ess ./para_files/simulation$2.nml
}

MH_algorithm () {
    IFS=' ' read -a x <<< $1
    simulation_dir="simulation$2"
    mkdir $simulation_dir
    gfortran -J./$simulation_dir -o ./$simulation_dir/ess $FSRCS $CPPFLAGS
    sed -e "s/'BiomeE_P0_BCI_aCO2_00'/'$simulation_dir'/" \
    -e "74s/s,/${x[0]},/" \
    -e "81s/s,/${x[1]},/" \
    -e "85s/s,/${x[2]},/" \
    -e "50s/s1,/${x[3]},/" \
    -e "50s/s2,/${x[4]},/" $fparameter > ./para_files/simulation$2.nml || { echo "Error in sed command"; exit 1; }
    ./simulation$2/ess ./para_files/simulation$2.nml
    flag=$(python3 ./Auxiliary/MH_algo.py $2)
    echo "${x[0]} ${x[1]} ${x[2]} ${x[3]} ${x[4]}" >> ./output/parameters$2.txt
    if [ "$flag" = 1 ]; then
        sed -i '' -e "$(($2 + 1))s/.*/${x[0]} ${x[1]} ${x[2]} ${x[3]} ${x[4]}/" './running.txt'
        echo "${x[0]} ${x[1]} ${x[2]} ${x[3]} ${x[4]}" >> ./output/accepted.txt
    fi
}

# Main workflow
python3 ./Auxiliary/DataCleaning.py

# Generate the file for accepted parameters
echo "LNbase r0mort_c gamma_LN K0SOM4 K0SOM5" > ./output/accepted.txt

max_jobs=10

# Generate the file for parameters to check convergence
for ((j=1;j<=max_jobs;j++))
do
    echo "LNbase r0mort_c gamma_LN K0SOM4 K0SOM5" > ./output/parameters$j.txt
done

nb_iteration=$((20000 + 1))

# Generate the first set of parameters
python3 ./Auxiliary/generate_parameters_i.py $max_jobs

if [ ! -f ./para_files/parameters.txt ]; then
    echo "Error: parameters.txt not found!"
    exit 1
fi

# Read the lines of the file
IFS=$'\n' read -d '' -r -a lines < ./para_files/parameters.txt

len=${#lines[@]}

# Do the simulation
for ((j=1;j<$len;j++))
do
    simulation_fcn "${lines[j]}" $j &
    echo "0" >> ./prob.txt
done
wait

# Get the results for the probability for MCMC
for ((j=1;j<$len;j++))
do
    IFS=' ' read -a x <<< "${lines[j]}"
    python3 ./Auxiliary/get_initial.py $j
    echo "${x[0]} ${x[1]} ${x[2]} ${x[3]} ${x[4]}" >> ./output/parameters$j.txt
done

mv ./para_files/parameters.txt ./running.txt
rm ./output/simulation*
rm ./para_files/simulation*
rm -r ./simulation*

for ((i=1;i<$nb_iteration;i++))
do
    python3 ./Auxiliary/generate_parametersMCMC.py

    IFS=$'\n' read -d '' -r -a lines < ./para_files/parameters.txt

    len=${#lines[@]}

    for ((j=1;j<$len;j++))
    do
        MH_algorithm "${lines[j]}" $j &
    done
    wait

    rm ./output/simulation*
    rm ./para_files/simulation*
    rm ./para_files/parameters.txt
    rm -r ./simulation*
   # python3 ./Auxiliary/GR_convergence.py $max_jobs $(($i + 1)) 
    echo "$i iterations done"
done


