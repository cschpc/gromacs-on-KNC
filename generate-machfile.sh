#!/bin/bash
# Generate a machinefile for a job running in the Taito-mic cluster.

if !(( $# ))
then
	echo "Usage: ./generate-machfile.sh <machfile>"
	echo "  Environmental variables used:"
	echo "    MPIRUN           -- command to launch MPI jobs (default: mpirun)"
	echo "    HOST_PPN         -- no. of MPI tasks on host CPUs (default: 1)"
	echo "    MIC_PPN          -- no. of MPI tasks per MIC card (default: 12)"
	echo "    NODES (optional) -- number of nodes to use, if unset"
	echo "                        SLURM_NNODES will be used"
	echo "    MICS (optional)  -- no. of MICs to use, if unset will assume a"
	echo "                        dual-socket layout"
	exit
fi

OUTPUT=$1
host=tmp.hostfile
mach=tmp.machfile

[[ ${MPIRUN:+x} ]] || MPIRUN=mpirun
[[ ${NODES:+x} ]] || NODES=$SLURM_NNODES
[[ ${MICS:+x} ]] || MICS=(0 1)
[[ ${HOST_PPN:+x} ]] || HOST_PPN=1
[[ ${MIC_PPN:+x} ]] || MIC_PPN=12

echo "Generating a machinefile for $NODES MIC nodes"
echo "  using offload devices (${MICS[@]})"
echo "  with $HOST_PPN and $MIC_PPN MPI tasks on each host CPU and MIC card, respectively."

$MPIRUN -n $NODES -ppn 1 hostname > $host
cat $host | sort | uniq > $mach

if [ -e $OUTPUT ]
then
	rm $OUTPUT
fi

for i in $(cat $mach)
do
   for d in ${MICS[@]}
   do
      echo ${i}-mic${d}:${MIC_PPN} >> $OUTPUT
      echo ${i}:${HOST_PPN}     >> $OUTPUT
   done
done

(( $DEBUG )) || rm $host $mach

