#!/bin/bash

#
# Copyright (c) 2019 Carnegie Mellon University,
# Copyright (c) 2019 Triad National Security, LLC, as operator of
#     Los Alamos National Laboratory.
#
# All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.
#

# MUST TELL ME THE FILENAME
if [ ! -z "$1"  ]; then
    logfile="$1"
else
    echo "usage: $0 logfile"
    exit 1
fi

echo "Parsing results from $logfile ..."
# CHECK BASIC CONF
t=`cat $logfile | grep -F tests= | head -n 1 | cut -d= -f2`
e=`cat $logfile | grep -F experiment= | head -n 1 | cut -d= -f2`
r=`cat $logfile | grep -F run= | head -n 1 | cut -d= -f2`
n=`cat $logfile | grep -F nodes= | head -n 1 | cut -d= -f2`
p=`cat $logfile | grep -F ppn= | head -n 1 | cut -d= -f2`
extraopts=`cat $logfile | grep -F extraopts= | head -n 1 | cut -d= -f2-`
skipreads=`cat $logfile | grep -F skipreads= | head -n 1 | cut -d= -f2`
dw=`cat $logfile | grep -F dw= | head -n 1 | cut -d= -f2`
# CHECK DW
if [ x$dw = xint -o x$dw = xbw ]; then
bb_instance_id=`cat $logfile | grep -F ">>> dw ids" | cut -d'/' -f4`
echo "BB INSTANCE ID is $bb_instance_id"
b=`cat $logfile | grep -F "$bb_instance_id" | grep -F nid | wc -l`
else
b=0
fi
echo "exp=$e, run=$r, node=$n, ppn=$p, bb_nodes=$b (mode=$dw), test=$t, mpi=[$extraopts]"
# CHECK CN/BN RATIO
if [ x$dw = xint -a $(($b * 32)) -gt $n ]; then
   echo 'WARNING: TOO MANY BB NODES!'
fi

# CHECK IF THE RUN HAS FINISHED OK
x=`cat $logfile | grep -iF "all done" | wc -l`
echo $x "lines of \"-INFO- all done\"..."
num_ok=2
if [ x"$t" = x"baseline" -o $skipreads -ne 0 ]; then
    num_ok=1
fi
if [ $x -ge $num_ok ]; then
    echo 'OK!'
else
    echo 'NOT OK! THE RUN MAY HAVE FAILED IN THE MIDDLE --- WILL PARSE AS MUCH AS WE CAN'
fi
echo ''

echo 'Extracting important results...'
echo ''

# STEP 1 - TOTAL IO TIME
total_iotime=0
echo "TOTAL IO TIME ($b BB NODES)"
for iotime in `cat $logfile | grep -F "Dumping duration" | cut -d' ' -f4`
do
    total_iotime=`echo "print $total_iotime + $iotime" | python`
    echo "+ $iotime"
done
echo '---------------'
echo "= $total_iotime (secs)"
echo ''

# STEP 2 - TOTAL OUTPUT SIZE
echo "TOTAL OUTPUT SIZE"
output_bytes=`cat $logfile | grep -A 3 -F "du -sb" \
    | grep -v -F 'srun' | grep -v -F 'mpirun' | grep -v -F 'aprun' \
    | grep -v -F 'Output size:' | cut -f1`
echo "$output_bytes bytes"
out=`echo "print format(1.0 * $output_bytes / 1024 / 1024 / 1024 / 1024, '.3f')" | python`
echo "= $out TiB"
echo ''

# STEP 3 - CPU UTIL
echo "CPU UTIL (usr time + sys time)"
total_cpu=0
total_n=0
for cpu in `cat $logfile | grep -F 'avg cpu' | cut -d= -f2 | cut -d' ' -f2 | cut -d'%' -f1`
do
    total_cpu=`echo "print $total_cpu + $cpu" | python`
    total_n=$((total_n + 1))
    echo "> $cpu%"
done
if [ $total_n -ne 0 ]; then
    echo '---------------'
    avg_cpu=`echo "print format(1.0 * $total_cpu / $total_n, '.2f')" | python`
    echo "= $avg_cpu%"
fi
echo ''

# STEP 4 - QUERY LATENCY
if [ $skipreads -ne 0 ]; then
    echo "READ BYPASSED - NO QUERY RESULTS"
else
    echo "QUERY LATENCY"
    if [ x"$t" = x"baseline" ]; then
        cat $logfile | grep "Overall:"
        echo 'NOTE: USE THE SECOND NUMBER'
    else
        cat $logfile | grep "Latency Per Query" | cut -d: -f2- | cut -d' ' -f2-
    fi
fi
echo ''

echo 'Done'

exit 0
