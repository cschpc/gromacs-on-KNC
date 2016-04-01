#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH -t 00:60:00
#SBATCH -J knc-test
#SBATCH -o job-%J.out
#SBATCH -e job-%J.err
#SBATCH -p mic
#SBATCH --gres=mic:1

MIC_PPN=40    # no. of MPI tasks per MIC card


#============== MACHINE SPECIFIC (taito.csc.fi) ===============
# Hardware definition (Taito)
HOST_CORES=6  # no. of CPU cores in a processor
MIC_CORES=61  # no. of MIC cores in a card (use 60 for compute)
MIC_TPC=4     # no. of threads per MIC core
# load any modules needed
module load gromacs-env/5.1.1-mic

#affinity for dual mic jobs
export KMP_AFFINITY=verbose,compact,1,0
if [ $OFFLOAD_DEVICES == "0" ]
then
  export KMP_AFFINITY="explicit,proclist=[0,1,2,3,4,5],verbose"
fi
if [ $OFFLOAD_DEVICES == "1" ]
then
  export KMP_AFFINITY="explicit,proclist=[6,7,8,9,10,11],verbose"
fi

#=================== DO NO CHANGE ============================

# set  no. of threads/tasks for the job on HOST side
HOST_PPN=1    # no. of MPI tasks per CPU, only 1 is a sensible value
HOST_PE=$(echo ${OFFLOAD_DEVICES//,/ }|wc -w  ) # no. of host CPUs per job, set to number of mic cards

export HOST_PPN MIC_PPN
export HOST_THREADS=$(( $HOST_CORES / $HOST_PPN ))
export MIC_THREADS=$(( ($MIC_CORES - 1) * $MIC_TPC / $MIC_PPN ))


# PME nodes for GROMACS (remove for others!)
NPME=$(( $HOST_PE * $HOST_PPN * $SLURM_NNODES ))

# Uncomment the following lines to turn on debugging
#export DEBUG=1
#export I_MPI_DEBUG=5

# MPI environment
export MPIRUN="mpiexec.hydra"
export I_MPI_MIC=1
export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=disable

export MIC_KMP_AFFINITY=balanced
export I_MPI_FABRICS=shm:dapl
export I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1


# generate a machine file for this run
#   note: uses environmental variables MPIRUN, HOST_PPN, MIC_PPN, OFFLOAD_DEVICES, and 
#         NODES (optional)
./generate-machfile.sh machfile

# define the commands to run on the HOST and MIC nodes with mic-launch.sh
#   note: if using modules (above) CMD_PATH can most likely be empty
export CMD_PATH=
export CMD_HOST=mdrun_mpi
export CMD_MIC=mdrun_mic
export CMD_FLAGS="-npme ${NPME} -ntomp_pme ${HOST_THREADS} -maxh 0.1 -dlb yes"


# launch the job
#   note: uses environmental variables MIC_THREADS, HOST_THREADS, CMD_PATH, 
#         CMD_HOST, CMD_MIC, CMD_FLAGS, and MIC_KMP_AFFINITY and modifies 
#         OMP_NUM_THREADS and LD_LIBRARY_PATH


$MPIRUN -machinefile machfile ./mic-launch.sh

