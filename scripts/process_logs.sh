#!/bin/bash
#
# Process VPIC logs to extract data for plotting

if [ ! -z "$1"  ]; then
    logdir="$1"
else
    echo "usage: $0 [logdir] > outfile.csv"
    exit 1
fi

process_file() {
    file="$1"

    parts=""; procs=""; memfree="";
    logsz=""; simtime=""; iotime="";

    >&2 echo "Processing $file..."

    # Get number of particles
    nx=`cat $file | grep "nx = " | sed 's/.*= //'`
    ny=`cat $file | grep "ny = " | sed 's/.*= //'`
    nz=`cat $file | grep "nz = " | sed 's/.*= //'`
    nppc=`cat $file | grep "nppc = " | sed 's/.*= //'`
    parts=$(( $nx * $ny * $nz * $nppc * 2 ))

    # Get number of processes
    procs=`cat $file | grep "nproc = " | sed 's/.*= //'`

    # Get average % of free node memory
    memfree=`cat $file | grep "Free Mem" | cut -d' ' -f3 | sed 's/%//' | \
             awk 'BEGIN{sum=0;n=0;}{sum+=$1;n++;}END{print sum/n}'`

    # Get VPIC log size
    logsz=`cat $file | grep "Output size" | cut -d' ' -f3`

    # Get total VPIC simulation time
    simtime=`cat $file | grep "simulation time" | cut -d' ' -f4`

    # Get total VPIC simulation time spent on I/O
    iotime=`cat $file | grep "Dumping duration" | cut -d' ' -f4 | \
            awk 'BEGIN{sum=0;}{sum+=$1;}END{print sum}'`

    echo "$parts,$procs,$memfree,$logsz,$simtime,$iotime"
}

echo "particles,processes,memfree,logsize,simtime,IOtime"

# Look for .log files in logdir
for file in $logdir/*.log
do
    if [[ -f $file ]]; then
        process_file "$file"
    fi
done
