# Gromacs on KNC (Taito-mic)

GROMACS is a molecular dynamics package that is designed for biochemical
molecules like proteins, lipids and nucleic acids that have a lot of
complicated bonded interactions. At CSC it is one of the most heavily
used scientific applications.

The Taito cluster includes a separate partition called Taito-mic that has
45 compute nodes with dedicated Intel Xeon Phi coprocessors based on the Many
Integrated Core (MIC) architecture. Each node has two Intel Xeon-Phi 7120X
coprocessors (or KNCs as they are often called after their code name Knights
Corner) and two 6-core Intel Xeon E5-2620-v2 host CPUs, based on the Ivy
Bridge microarchitecture. Memory wise, there are 32 GB of DDR3 1600 Mhz
memory, and the local disks are 500 GB SATA3 HDD. These compute nodes part of
a supercomputer from Bull acquired in 2014, and have been integrated tightly
to the Taito cluster to appear as one entity.

To best utilise the hardware, we have chosen an approach where the MD workload
is divided in such a way that PME calculations are done on the host CPUs and
the pairwise force calculations are done on the MIC cards. In this document we
document how to run Gromacs optimally on Taito-mic using this approach, and
discuss which cases are useful to run there.


## Instructions for running

This document is part of a repository containing ready-to-use launcher scripts
that automatically run correct binaries on the host CPUs and the MIC cards.
Specifications for Taito-mic are included (_specs.taito_), so no modifications
should be needed to start using them on Taito-mic.

If you haven't got the full repository, you can get it from:
 https://github.com/cschpc/gmx-knc-launcher

Please see README.md for instructions on how to use the launcher scripts.


## Best Practices on Taito-mic

**Best practice: Use half a node (one CPU & one KNC) for smaller jobs, and
one node (two CPUs & two KNCs) for larger jobs.**

In general the scalability to multiple nodes is very poor. Only the very
biggest cases show acceptable scalability to 2 or even 4 nodes. Especially for
smaller cases half a node (reserving only one KNC per job) is most beneficial
in the sense that the two jobs get the best throughput.


**Best practice: Use 1 MPI task per CPU.**

By running 1, 2, 3 and 6 MPI tasks per host CPU one can see that running 1
task each having 6 threads is up to 4x faster than the other options.


**Best practice: No generally optimal value, but use 30 MPI tasks with 8
threads each (4 threads per core) per KNC when in doubt.**

One cannot recommend one single value as being the optimal. The optimal choice
depends on the number of nodes Gromacs is running on, and on the number of
atoms.  The general rule is:
* User more processes per MIC when the number of atoms increases
* Use less processes per MIC when the number of nodes increases

In Table 4 some good values are shown for three different use cases (details
below) on 1/2 - 4 nodes. These can be used as reasonable first guesses for the
number of MPI tasks and threads depending on the system size.


**Best practice: Always run 4 threads per core**

One can run 1 - 4 threads per core on the Xeon Phi coprocessor. The optimal
choice in general is 4 threads per core. The recommended value of 30 MPI tasks
and 8 threads implies that each task is running on 2 cores, with 4 threads on
each core. Thus all 60 compute-cores are in use.


**Best practice: Use KMP_AFFINITY=balanced on MIC cards.**

This is set by default in the mic-job.sh script:
~~~bash
export MIC_KMP_AFFINITY=verbose,balanced
~~~

Looking at a range of thread counts it is clear that `compact` and 
`balanced` provide stable performance with `balanced` being in general
slightly better, while `scattered` has very poor performance for some thread
counts.


**Best practice: Larger systems have better relative performance**

For small simulations (less than 100k atoms) the taito-MIC partition is not
very efficient, but as the system size goes up the performance for one node
jobs approaches that of Sisu. The best bang-for-BUs is thus achieved with
simulations comprising hundreds of thousands of atoms.

## Benefits and drawbacks of using Taito-mic

The cases best suited for the Taito-mic partition are those where one can
parallelize the scientific problem by running a large number of shorter
simulations, instead of trying to get as good performance as possible when
running just one simulations. Since Taito-mic often has free resources, while
the other machines may be very loaded, this can provide a nice tool for
finishing the simulations in a shorter time than otherwise possible. From a
billing unit (BU) point of view the MIC resources are also relatively cheap,
since they are only billed according to the CPU cores. This means that the one
node simulations of case 2 and case 3 use less BUs on Taito-mic.

To get maximum ns/day one should instead investigate scaling the run to Sisu,
or to use the GPU resources. The new K80 resources provide excellent
performance for Gromacs, while the older K40 resources are less well suited
due to the weak CPU.


## Detailed performance comparison

### Description of test-cases

* **Case 1:** 48k atoms. Lipid bilayer of 200 lipids (100 per leaflet) and about 2
  nm water layer on top and bottom of the system. An umbrella potential was
  used in simulations, which has small effect on MIC performance. Time step 2
  fs. Box size 7.8x7.8x7.7 nm^3.
* **Case 2:** 142k atoms. Ion-channel. 304 lipids and a protein (339 amino
  acids). PRACE Test Case A, designed to run on Tier-1 sized systems.  Time
  step 2.5 fs. Box size 11.3x9.7x14.8 nm^3.
* **Case 3:** 592k atoms. Spherical High-density lipoprotein (HDL), which
  consists of 219 lipids and 4 apolipoproteins (4x203 amino acids). Diameter
  of HDL is 9 nm. Time step 2 fs. Box size 18.2x18.2x18.2 nm^3.

### CPU performance

For reference we have computed the performance (ns/day) of the tests on a
variety of normal CPU nodes, including ones with 12-core Haswell (Table 1) and
6-core Ivy Bridge (Table 2) processors.


**Table 1.** Haswell (Xeon E5-2690v3, 12-core) processors on Sisu using 12
MPI processes per CPU and 1 threads per process.

(ns/day) | 1 node | 2 nodes | 4 nodes
---------|--------|---------|--------
  Case 1 | 23.395 |  41.870 |  65.363
  Case 2 | 16.650 |   2.005 |  59.389
  Case 3 |  3.740 |   7.199 |  13.679


**Table 2.** Ivy bridge (Xeon E5-2620-v2, 6-core) host CPUs on Taito-mic
(without MIC cards) using 6 MPI process per CPU and 1 thread per process.

(ns/day) | 1 node | 2 nodes | 4 nodes
---------|--------|---------|--------
  Case 1 | 11.949 |  19.038 |  33.158
  Case 2 |  7.186 |  12.493 |  23.718
  Case 3 |  1.506 |   2.755 |   5.304


### MIC-KNC performance

Performance (ns/day) on Taito-mic as a function of nodes is shown in Table 3.
In these runs we used one process per host CPU with 6 threads, i.e. as many
MPI processes on the host has we had KNC cards. On the KNC an optimal process
count per case was used (see Table 4). In the 1/2 node case the time is the
average execution speed when running 2 jobs per node.

**Table 3.** Knights Corner (Xeon-Phi 7120X + Xeon E5-2620-v2) MIC nodes on
Taito-mic.

(ns/day) | 1/2 node | 1 node | 2 nodes | 4 nodes
-------- |----------|--------|---------|--------
  Case 1 |     11.6 |  13.2  |    15.3 |
  Case 2 |      9.5 |  13.14 |    16.0 |    22.0
  Case 3 |      2.1 |   3.3  |     5.1 |     7.6


**Table 4.** Optimal process count (MPI tasks vs. threads) on the KNC for each
case and node count.

(MPI tasks, threads) | 1/2 node | 1 node | 2 nodes | 4 nodes
---------------------|----------|--------|---------|--------
              Case 1 |   30,  8 | 12, 20 |   8, 30 |
              Case 2 |   40,  6 | 30,  8 |  12, 20 |  10, 24
              Case 3 |   40,  6 | 30,  8 |  24, 10 |  12, 20

