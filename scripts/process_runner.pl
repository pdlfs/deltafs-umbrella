#!/usr/bin/env perl
#
# process_runner.pl  process mercury-runner output
# 03-Mar-2017  chuck@ece.cmu.edu
#

#
# feed both the client and server output for a set of runs into this
# and it will produce a short report...  the runs should have the same
# settings (e.g. same protocol, number of instances).
#

use strict;

my($type, $ninst, $count, $mode, $limit, $run, $time);
my($key, $max, $lcv);
my(%kcount, %ktot, %stcount, %sttot);

while (<STDIN>) {
    chop;

    # extract the protocol from input
    if ($type eq '' && /localspec\s+=\s+(\w+)/) {
        $type = $1;
        next;
    }

    # look for client final output
    if (/: client-(\d+)-(\d+)-(c|s)-(\d+)-(\d+):.*(\d+)\.(\d+) sec per op/) {
        $ninst = $1;           # instances number
        $count = $2;           # number of RPCs we did
        $mode = $3;            # c (client)
        $limit = $4;           # limit on # of outstanding RPCs
        $run = $5;             # run/iteration number 
        $time = "$6.$7";       # run time in seconds
    
        $key = $limit;         # use limit as key
        $max = $key if ($max < $key);  # track largest limit we used
        $kcount{$key}++;
        $ktot{$key} += $time;
        next;
    }

    # ALL-1-100000-c-256-3: ... times sys=4.784000 (secs)
    next unless (/^ALL-(\d+)-(\d+)-(c|s)-(\d+)-(\d+)/);
    $ninst = $1;               # same format as above
    $count = $2;       
    $mode = $3;
    $limit = $4;
    $run = $5;

    next unless (/sys=(\d+)\.(\d+)/);
    $time = "$1.$2";
    $key = "$mode-$limit";     # key include client/server and limit
    $stcount{$key}++;
    $sttot{$key} += $time;
}

for ($lcv = 1 ; $lcv <= $max ; $lcv = $lcv * 2) {
    my($kc, $kt, $kspo);
    my($cc, $ct, $ctime, $sc, $st, $stime);

    $key = "$lcv";
    $kc = $kcount{$key};
    $kt = $ktot{$key};
    $kspo = ($kc) ? sprintf("%f", $kt / $kc) : "<none>";

    $key = "c-$lcv";
    $cc = $stcount{$key};
    $ct = $sttot{$key};
    $ctime = ($cc) ? sprintf("%f", $ct / $cc) : "<none>";

    $key = "s-$lcv";
    $sc = $stcount{$key};
    $st = $sttot{$key};
    $stime = ($sc) ? sprintf("%f", $st / $sc) : "<none>";

    printf "%s %3d %s sec per op, cli/srv sys time %s / %s sec, r=%d\n", 
        $type, $lcv, $kspo, $ctime, $stime, $kc;
}

exit(0);