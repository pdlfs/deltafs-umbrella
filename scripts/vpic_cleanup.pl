#!/usr/bin/env perl
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
    @input = glob("shuflog.*");
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
        next unless / SHUF NOTE /;
        s/^.* shuf.\d+. SHUF NOTE //;
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
