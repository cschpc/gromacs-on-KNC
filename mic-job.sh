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

# if needed, change to working directory first (e.g. in PBS)
#cd $PBS_O_WORKDIR

# read machine specific settings (e.g. hardware topology)
#   (see specs.taito for a SLURM example incl. support for half-node jobs
#    and specs.salomon for a PBS example)
source specs.taito

# if needed, change the no. of MPI tasks per MIC card to a more optimal
# value for your simulation system (see docs/taito.md for a rough guideline)
#MIC_PPN=30

# uncomment the following lines to turn on debugging
#export DEBUG=1
#export I_MPI_DEBUG=5


#===== DO NOT CHANGE (skip below for the run commands) =================

# calculate no. of threads for host/mic
export HOST_PPN MIC_PPN
export HOST_THREADS=$(( $HOST_CORES / $HOST_PPN ))
export MIC_THREADS=$(( ($MIC_CORES - 1) * $MIC_TPC / $MIC_PPN ))

# PME nodes for GROMACS (remove for others!)
NPME=$(( $HOST_PE * $HOST_PPN * $NODES ))

# default affinities (add verbose to see the actual placement)
[[ ${KMP_AFFINITY:+x} ]] || KMP_AFFINITY=compact,1,0
[[ ${MIC_KMP_AFFINITY:+x} ]] || MIC_KMP_AFFINITY=balanced
export KMP_AFFINITY MIC_KMP_AFFINITY

# generate a machine file for this run
#   note: uses environmental variables MPIRUN, HOST_PPN, MIC_PPN, MICS, and
#         NODES (optional)
./generate-machfile.sh machfile

#===== END OF DO NOT CHANGE ============================================


# define the commands to run on the HOST and MIC nodes with mic-launch.sh
#   note: if using modules (above) CMD_PATH can most likely be empty
export CMD_PATH=
export CMD_HOST=mdrun_mpi
export CMD_MIC=mdrun_mic
export CMD_FLAGS="-npme ${NPME} -ntomp_pme ${HOST_THREADS} -dlb yes"

# launch the job
#   note: uses environmental variables MIC_THREADS, HOST_THREADS, CMD_PATH,
#         CMD_HOST, CMD_MIC, CMD_FLAGS, and MIC_KMP_AFFINITY and modifies
#         OMP_NUM_THREADS and LD_LIBRARY_PATH
$MPIRUN -machinefile machfile ./mic-launch.sh

