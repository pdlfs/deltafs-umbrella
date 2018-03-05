#!/bin/bash

# MUST TELL ME THE FILENAME
if [ ! -z "$1"  ]; then
    logfile="$1"
else
    echo "usage: $0 logfile"
    exit 1
fi

echo "Parsing results from $logfile ..."
# CHECK BASIC CONF
e=`cat $logfile | grep -F experiment= | head -n 1 | cut -d= -f2`
r=`cat $logfile | grep -F run= | head -n 1 | cut -d= -f2`
n=`cat $logfile | grep -F nodes= | head -n 1 | cut -d= -f2`
p=`cat $logfile | grep -F ppn= | head -n 1 | cut -d= -f2`
# CHECK DW
dw=`cat $logfile | grep -F dw=int | wc -l`
if [ $dw -gt 0 ]; then
bb_instance_id=`cat $logfile | grep -F ">>> dw ids" | cut -d'/' -f4`
b=`head -n 100 $logfile | grep -F $bb_instance_id | grep -F nid | wc -l`
else
b=0
fi
echo "exp=$e, run=$r, node=$n, ppn=$p, bb_nodes=$b"
# CHECK CN/BN RATIO
if [ $(($b * 32)) -gt $n ]; then
   echo 'WARNING: TOO MANY BB NODES!'
fi

# CHECK IF THE RUN HAS FINISHED OK
x=`cat $logfile | grep -iF "all done" | wc -l`
echo $x "lines of \"-INFO- all done\"..."
if [ $x -ge 2 ]; then
    echo 'OK!'
else
    echo 'ABORT!'
    exit 1
fi
echo ''

echo 'Extracting important results...'
echo ''

# STEP 1 - TOTAL IO TIME
total_iotime=0
echo "TOTAL IO TIME"
for iotime in `cat $logfile | grep -F "Dumping duration" | cut -d' ' -f4`
do
    total_iotime=`echo $total_iotime + $iotime | bc`
    echo "+ $iotime"
done
echo '---------------'
echo "= $total_iotime (secs)"
echo ''

# STEP 2 - TOTAL OUTPUT SIZE
echo "TOTAL OUTPUT IN BYTES"
cat $logfile | grep -A 3 -F "du -sb" | grep -v srun | grep -v 'Output size:' | cut -f1
echo ''

# STEP 3 - QUERY LATENCY
echo "QUERY LATENCY"
cat $logfile | grep "Latency Per Query" | cut -d: -f2- | cut -d' ' -f2-
echo ''

echo 'Done'

exit 0
