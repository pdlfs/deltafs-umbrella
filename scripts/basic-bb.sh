#!/bin/bash
#
#SBATCH --time=0:10:00
#SBATCH --nodes=1
#SBATCH --output /users/%u/joblogs/basic-bb-%j.out
# DataWarp striped scratch allocation
#DW jobdw type=scratch access_mode=striped capacity=5GiB optimization_strategy=interference

echo "striped $DW_JOB_STRIPED"
echo "private: $DW_JOB_PRIVATE"
echo "DW_PERSISTENT_STRIPED_bws=$DW_PERSISTENT_STRIPED_bws"

# No ACDW_JOBID so use the mount directly
sessid=$(basename $DW_JOB_STRIPED |cut -f 1 -d _)
echo "DW Session ID: $sessid"

srun -n 1 touch $DW_JOB_STRIPED/file.txt
srun -n 1 ls $DW_JOB_STRIPED

module load dws
dwstat instances fragments
