#!/bin/bash
# Launch a program on MIC cards and host CPUs in symmetric mode.
#
# Environmental variables used:
#   HOST_THREADS     -- No. of threads for host CPUs
#   MIC_THREADS      -- No. of threads for MIC cards
#   CMD_PATH         -- Path to program binaries
#   CMD_HOST         -- Program binary (CPU version)
#   CMD_MIC          -- Program binary (MIC version)
#   CMD_FLAGS        -- Optional flags for the program
#   MIC_KMP_AFFINITY -- KMP_AFFINITY for MIC cards

ARCH=`uname -m`
(( $DEBUG)) && echo "MPI task $PMI_RANK: $ARCH"

if [ $ARCH == "x86_64" ]
then
	unset I_MPI_PMI_LIBRARY
	export OMP_NUM_THREADS=$HOST_THREADS
	if (( $DEBUG ))
	then
		echo "Running (on x86_64) [$PMI_RANK]: ${CMD_PATH}${CMD_HOST} $CMD_FLAGS"
	elif [ "$PMI_RANK" == "0" ]
	then
		echo "Running (on x86_64): ${CMD_PATH}${CMD_HOST} $CMD_FLAGS"
	fi
	${CMD_PATH}${CMD_HOST} $CMD_FLAGS
elif [ $ARCH == "k1om" ]
then
	export OMP_NUM_THREADS=$MIC_THREADS
	export KMP_AFFINITY=$MIC_KMP_AFFINITY
	export LD_LIBRARY_PATH=${MKLROOT}/lib/mic:${MKLROOT}/../compiler/lib/mic:$LD_LIBRARY_PATH
	if (( $DEBUG ))
	then 
		echo "Running (on MIC) [$PMI_RANK]: ${CMD_PATH}${CMD_MIC} $CMD_FLAGS"
	elif [ $PMI_RANK == "0" ]
	then
		echo "Running (on MIC): ${CMD_PATH}${CMD_MIC} $CMD_FLAGS"
	fi
	${CMD_PATH}${CMD_MIC} $CMD_FLAGS
fi

