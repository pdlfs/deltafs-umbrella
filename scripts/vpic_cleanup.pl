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
# vpic_cleanup.pl  clean up after a vpic experiment
# 26-Jan-2018  chuck@ece.cmu.edu
#

use strict;
$| = 1;
use Getopt::Long qw(:config require_order);

my($rv, $logstats);

$rv = GetOptions(
    "logstats"     => \$logstats,
);

sub usage {
    my($msg) = @_;
    print STDERR "ERR: $msg\n" if ($msg ne '');
    print STDERR "usage: vpic_cleanup.pl [options] jobdir\n";
    print STDERR "general options:\n";
    print STDERR "\t--logstats     clean log files, just save stats\n";
    exit(1);
}

usage() if ($rv != 1 || $#ARGV != 0);
chdir($ARGV[0]) || die "Cannot chdir($ARGV[0]) - $!";

if ($logstats) {
    my(@input);
    @input = glob("deltafs_*/shuflog.*");
    foreach (@input) {
        logstats_file($_);
    }
    printf "logstats: number of inputs was = %d\n", $#input+1;
}

exit(0);


#
# logstats_file: clean up a log file (get rid of everything but the
# "SHUT NOTE" logs that have the stats...
#
sub logstats_file {
    my($in) = @_;
    my($fh, @out, $rv1, $rv2);
    unless (open($fh, $in)) {
        print "logstats_file: can't open $in - $!\n";
    }

    while (<$fh>) {
        next unless (s/^.* shuf.\d+. SHUF (NOTE|WARN|ERR|CRIT|ALRT|EMRG) //);
        push(@out, $_);
    }

    close($fh);

    if (!open($fh, ">$in.new")) {
        print "logstats_file: can't create $in.new - $!\n";
        return;
    }
    $rv1 = print $fh join("", @out);
    $rv2 = close($fh);
    return if ($rv1 && $rv2 && rename("$in.new", "$in"));
    print "logstats_file: I/O error with $in\n";
    unlink("$in.new");
}
