#!/usr/bin/env perl

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

#
# process_runner.pl  process mercury-runner output
#
#
# feed both the client and server output for a set of runs into this
# and it will produce a short report...  the runs should have the same
# settings (e.g. same protocol, number of instances).
#

use strict;

my($type, $ninst, $count, $mode, $limit, $run, $time);
my($key, $max, $lcv);
my(%modes);                    # what modes we've seen (for sanity check)
my(%nsecperop, %secperopsum);  # total# of sec/op seen, sum of sec per op
my(%stcount, %wallsum, %usrsum, %syssum);  # stat count, sums of times
my($walltime, $usrtime, $systime, $bi);

while (<STDIN>) {
    chop;

    # extract the protocol from input
    if ($type eq '' && /localspec\s+=\s+(\w+)/) {
        $type = $1;
        next;
    }

    # look for client final output
    if (/: client-(\d+)-(\d+)-(c|s|cs)-(\d+)-(\d+):.*(\d+)\.(\d+) sec per /) {
        $ninst = $1;           # instances number
        $count = $2;           # number of RPCs we did
        $mode = $3;            # c (client)
        $limit = $4;           # limit on # of outstanding RPCs
        $run = $5;             # run/iteration number
        $time = "$6.$7";       # sec per op

        $modes{$mode} = 1;     # for sanity check
        $key = $limit;         # use limit as key
        $max = $key if ($max < $key);  # track largest limit we used
        $nsecperop{$key}++;
        $secperopsum{$key} += $time;
        next;
    }

    # ALL-1-100000-c-256-3: ... times sys=4.784000 (secs)
    next unless (/^ALL-(\d+)-(\d+)-(c|s|cs)-(\d+)-(\d+)/);
    $ninst = $1;               # same format as above
    $count = $2;
    $mode = $3;
    $limit = $4;
    $run = $5;
    next unless (/wall=(\d+)\.(\d+)/);
    $walltime = "$1.$2";
    next unless (/usr=(\d+)\.(\d+)/);
    $usrtime = "$1.$2";
    next unless (/sys=(\d+)\.(\d+)/);
    $systime = "$1.$2";

    $key = "$mode-$limit";     # key include client/server and limit
    $modes{$mode} = 1;         # for sanity check
    $stcount{$key}++;
    $wallsum{$key} += $walltime;
    $usrsum{$key} += $usrtime;
    $syssum{$key} += $systime;
}

# do some sanity checks
$bi = $modes{'cs'};            # got bi-directional output?
if ($bi && ($modes{'c'} || $modes{'s'})) {
    printf STDERR "process_runner.pl: ERROR: mixed modes\n";
    exit(1);
}
if ($bi) {
    for ($lcv = 1 ; $lcv <= $max ; $lcv = $lcv * 2) {
        if ($nsecperop{"$lcv"} & 1) {
            printf STDERR "process_runner.pl: ERROR: odd# of bidir results\n";
            exit(1);
        }
    }
}


for ($lcv = 1 ; $lcv <= $max ; $lcv = $lcv * 2) {
    my($nresults, $resultsum, $avgspo);
    my($statcnt, $cwall, $cusr, $csys, $swall, $susr, $ssys);

    $key = "$lcv";
    $nresults = $nsecperop{$key};
    $resultsum = $secperopsum{$key};
    $avgspo = ($nresults) ? sprintf("%f", $resultsum / $nresults) : "<none>";

    $key = ($bi) ? "cs-$lcv" : "c-$lcv";   # for bi-dir, use client vars
    $statcnt = $stcount{$key};
    if ($statcnt) {
        $cwall = sprintf("%f", $wallsum{$key} / $statcnt);
        $cusr  = sprintf("%f", $usrsum{$key}  / $statcnt);
        $csys  = sprintf("%f", $syssum{$key}  / $statcnt);
    } else {
        $cwall = $cusr = $csys = "<none>";
    }

    $key = "s-$lcv";
    $statcnt = $stcount{$key};
    if ($statcnt) {
        $swall = sprintf("%f", $wallsum{$key} / $statcnt);
        $susr  = sprintf("%f", $usrsum{$key}  / $statcnt);
        $ssys  = sprintf("%f", $syssum{$key}  / $statcnt);
    } else {
        $swall = $susr = $ssys = "<none>";
    }

    if ($bi) {
        printf "%s %3d %s sec/op, %.2fs, u/sys  %.2f/%.2f, r=%d\n",
            $type, $lcv, $avgspo, $cwall, $cusr, $csys, $nresults/2;
    } else {
        printf "%s %3d %s sec/op, %.2fs, u/sys  " .
               "c=%.2f/%.2f  s=%.2f/%.2f, r=%d\n",
            $type, $lcv, $avgspo, $cwall, $cusr, $csys, $susr, $ssys, $nresults;
    }
}

exit(0);
