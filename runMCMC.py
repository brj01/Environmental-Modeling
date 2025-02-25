import os
import subprocess
from multiprocessing import Pool

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running command: {command}\n{result.stderr}")
    return result.stdout

def simulation_fcn(params, sim_id):
    params = params.split()
    simulation_dir = f"simulation{sim_id}"
    os.makedirs(simulation_dir, exist_ok=True)
    
    fsources = "src/datatypes.F90 src/io_mod.F90 src/soil.F90 src/vegetation.F90 src/BiomeE.F90 src/main.F90"
    fparameter = "./para_files/parameters_CRU_BCI.nml"
    
    compile_cmd = f"gfortran -J./{simulation_dir} -o ./{simulation_dir}/ess {fsources}"
    run_command(compile_cmd)
    
    with open(f"./para_files/simulation{sim_id}.nml", "w") as f:
        with open(fparameter, "r") as template:
            content = template.read()
            content = content.replace("'BiomeE_P0_BCI_aCO2_00'", f"'{simulation_dir}'")
            content = content.replace("74s/s,", f"{params[0]},")
            content = content.replace("81s/s,", f"{params[1]},")
            content = content.replace("85s/s,", f"{params[2]},")
            content = content.replace("50s/s1,", f"{params[3]},")
            content = content.replace("50s/s2,", f"{params[4]},")
            f.write(content)
    
    run_command(f"./{simulation_dir}/ess ./para_files/simulation{sim_id}.nml")

def MH_algorithm(params, sim_id):
    simulation_fcn(params, sim_id)
    flag = run_command(f"python3 ./Auxiliary/MH_algo.py {sim_id}").strip()
    
    with open(f"./output/parameters{sim_id}.txt", "a") as f:
        f.write(params + "\n")
    
    if flag == "1":
        with open("./running.txt", "r+") as f:
            lines = f.readlines()
            lines[sim_id] = params + "\n"
            f.seek(0)
            f.writelines(lines)
        with open("./output/accepted.txt", "a") as f:
            f.write(params + "\n")

if __name__ == "__main__":
    run_command("python3 ./Auxiliary/DataCleaning.py")
    os.makedirs("./output", exist_ok=True)
    with open("./output/accepted.txt", "w") as f:
        f.write("LNbase r0mort_c gamma_LN K0SOM4 K0SOM5\n")
    
    max_jobs = 10
    for j in range(1, max_jobs + 1):
        with open(f"./output/parameters{j}.txt", "w") as f:
            f.write("LNbase r0mort_c gamma_LN K0SOM4 K0SOM5\n")
    
    run_command(f"python3 ./Auxiliary/generate_parameters_i.py {max_jobs}")
    
    with open("./para_files/parameters.txt", "r") as f:
        lines = f.readlines()
    
    with Pool(max_jobs) as pool:
        pool.starmap(simulation_fcn, [(line.strip(), i) for i, line in enumerate(lines[1:], start=1)])
    
    for j, line in enumerate(lines[1:], start=1):
        run_command(f"python3 ./Auxiliary/get_initial.py {j}")
        with open(f"./output/parameters{j}.txt", "a") as f:
            f.write(line)
    
    os.rename("./para_files/parameters.txt", "./running.txt")
    for folder in os.listdir("."):
        if folder.startswith("simulation"):
            run_command(f"rm -r {folder}")
    
    nb_iterations = 20000
    for i in range(1, nb_iterations + 1):
        run_command("python3 ./Auxiliary/generate_parametersMCMC.py")
        with open("./para_files/parameters.txt", "r") as f:
            lines = f.readlines()
        
        with Pool(max_jobs) as pool:
            pool.starmap(MH_algorithm, [(line.strip(), j) for j, line in enumerate(lines[1:], start=1)])
        
        for file in ["./output/simulation*", "./para_files/simulation*", "./para_files/parameters.txt"]:
            run_command(f"rm -f {file}")
        
        print(f"{i} iterations done")
