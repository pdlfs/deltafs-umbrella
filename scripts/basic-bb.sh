#!/bin/bash
#
#SBATCH --time=0:10:00
#SBATCH --nodes=1
#SBATCH --output /users/%u/joblogs/basic-bb-%j.out
# DataWarp striped scratch allocation
#DW jobdw type=scratch access_mode=striped capacity=5GiB optimization_strategy=interference

module load dws

echo "striped $DW_JOB_STRIPED"
echo "private: $DW_JOB_PRIVATE"
echo "DW_PERSISTENT_STRIPED_bws=$DW_PERSISTENT_STRIPED_bws"

# XXX: assume token is encoded in the dir path
# (at least on slurm the token is the job id)
dwtoken=$(basename $DW_JOB_STRIPED | cut -f 1 -d _)
sessid=$(dwstat sessions | \
                 awk -v token=$dwtoken '{if ($3 == token) print $1}')

echo "DW the token is: $dwtoken"
echo "DW Session ID: $sessid"

echo "Output of dwstat sessions--look for $sessid for us"
dwstat sessions

srun -n 1 touch $DW_JOB_STRIPED/file.txt
srun -n 1 ls $DW_JOB_STRIPED

module load dws
dwstat instances fragments
