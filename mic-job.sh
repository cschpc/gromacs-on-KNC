#!/bin/bash
#SBATCH -N 2
#SBATCH -t 00:60:00
#SBATCH -J gmx-mic 
#SBATCH -o job-%J.out
#SBATCH -e job-%J.err
#SBATCH -p mic
#SBATCH --gres=mic:2
#SBATCH --exclusive

# load any modules needed
module load gromacs-env/5.0.7-mic

# Change these to the desired no. of threads/tasks for the job!
HOST_PPN=1    # no. of MPI tasks per CPU
MIC_PPN=12    # no. of MPI tasks per MIC card
MIC_TPC=4     # no. of threads per MIC core
# Hardware definition (Taito)
HOST_PE=2     # no. of host CPUs
HOST_CORES=6  # no. of CPU cores in a processor
MIC_CORES=61  # no. of MIC cores in a card

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
export KMP_AFFINITY=verbose,compact,1,0
export MIC_KMP_AFFINITY=verbose,balanced
export I_MPI_FABRICS=shm:dapl
export I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1

# generate a machine file for this run
#   note: uses environmental variables MPIRUN, HOST_PPN, MIC_PPN, and 
#         NODES (optional)
./generate-machfile.sh machfile

# define the commands to run on the HOST and MIC nodes with mic-launch.sh
#   note: if using modules (above) CMD_PATH can most likely be empty
export CMD_PATH=
export CMD_HOST=mdrun_mpi
export CMD_MIC=mdrun_mic
export CMD_FLAGS="-npme ${NPME} -ntomp_pme ${HOST_THREADS} -ddorder pp_pme"

# launch the job
#   note: uses environmental variables MIC_THREADS, HOST_THREADS, CMD_PATH, 
#         CMD_HOST, CMD_MIC, CMD_FLAGS, and MIC_KMP_AFFINITY and modifies 
#         OMP_NUM_THREADS and LD_LIBRARY_PATH
$MPIRUN -machinefile machfile ./mic-launch.sh

