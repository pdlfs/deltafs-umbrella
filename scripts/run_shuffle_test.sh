#!/bin/bash -eu
#
#MSUB -N deltafs-shuffle
#MSUB -l walltime=1:00:00
#MSUB -l nodes=5:haswell
#MSUB -o /users/$USER/joblogs/deltafs-shuffle-$MOAB_JOBID.out
#MSUB -j oe
##MSUB -V
##MSUB -m b
##MSUB -m $USER@lanl.gov

######################
# Tunable parameters #
######################

# Notes:
# ------
#
# nodes: Use an odd number of nodes. The number of particles is a multiple of
# the number of cores, but 1 node is reserved for DeltaFS server, so you want
# to be left with power-of-2 cores to get better particle numbers.

# Node topology
cores_per_node=4
nodes=3

# Paths
umbrella_build_dir="$HOME/src/deltafs-umbrella/build"
output_dir="$HOME/src/vpic/decks/dump"

# DeltaFS config
ip_subnet="10.92"


###############
# Core script #
###############

bbos_buddies=0
build_op_dir="$umbrella_build_dir/vpic-prefix/src/vpic-build"
deck_dir="$umbrella_build_dir/vpic-prefix/src/vpic/decks/trecon-part"
logfile=""

message () { echo "$@" | tee -a $logfile; }
die () { message "Error $@"; exit 1; }

source ./run_common.sh

rm $logfile
gen_hosts

np=1
while [ $np -le $cores_per_node ]
do
    cores=$((np * (nodes-1)))
    parts=$((cores * 8))

    #build_deck "file-per-process" $parts
    #do_run "baseline" $parts

    build_deck "file-per-particle" $parts
    do_run "shuffle-test" $parts $np

    np=$(( np * 2 ))
done
