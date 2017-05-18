#!/usr/bin/env perl
#
#SBATCH --job-name ethq-quick
#SBATCH --time=0:05:00
#SBATCH --nodes=1
#SBATCH --constraint=haswell
#SBATCH --output /users/%u/joblogs/ethq-quick.out
#

#
# ethq.pl  query compute node for ethtool params
# 18-May-2017  chuck@ece.cmu.edu
#

use strict;

###########################################################################
#
# config info here
#
my(%skipif, @skip, @cmds);

#
# %skipif: skip any interface with this name
# @skip: skip any interface whose ifconfig info has this string in it
# @cmds: list of commands to run -- '%s' will get the interface name
#

# %skipif = ( "eth1" => 1 );   # example
%skipif = ();
@skip = ("LOOP");
@cmds = ( "ethtool %s", "ethtool -i %s", "ethtool -k %s" );
###########################################################################

#
# run_prefix depends on the batch env we are using, should end in a space
# if defined...
#
my($run_prefix);

if (defined($ENV{'SLURM_JOBID'})) {
     $run_prefix = "srun -n 1 ";
} elsif (defined($ENV{'PBS_JOBID'})) {
     $run_prefix = "aprun -n 1 ";
} else {
     # no need to run it through anyway...
} 

#
# get_ifs(): return interface names and ifconfig info
#
sub get_ifs {
    my($ph, $ifname, $ifline, %rv);

    # scan ifconfig for network interfaces of interest
    return(undef) unless (open($ph, "${run_prefix}ifconfig -a |"));

    $ifname = $ifline = '';
    while (<$ph>) {
        chop;
        # check for start new interface
        if (/^(\w+)[\s|:]/) {
            $rv{$ifname} = $ifline if ($ifname ne '');
            $ifname = $1;
            $ifline = $_;
        } else {
            $ifline = $ifline . " $_";
        }
    }
    close($ph);
    $rv{$ifname} = $ifline if ($ifname ne '');

    return(%rv);
}

#
# main
#
my(%ifs, @inames, $icnt, $i, $lcv, $sflag, $cmd);

%ifs = get_ifs();
@inames = sort keys %ifs;
$icnt = $#inames+1;

if ($icnt < 1) {
    printf("NO INTERFACES DETECTED -- EXITING!\n");
    exit(0);
}

print "Running command: ${run_prefix}ifconfig -a\n";
system("${run_prefix}ifconfig -a");
printf "DONE\n\n";

printf "ethq: number of interfaces detected = %d\n", $icnt;
print  "ethq: interface list = ", join(", ", @inames), "\n";

foreach $i (@inames) {
    printf("Processing $i ...\n");

    if ($skipif{$i}) {
        print "Skipping interface (name=$i)\n\n";
        next;
    }

    $sflag = 0;
    foreach $lcv (@skip) {
        if (index($ifs{$i}, $lcv) != -1) {
            print "Skipping interface (skip=$lcv)\n\n";
            $sflag = 1;
            last;
        }
    }
    next if ($sflag);

    print "running commands\n";
    foreach $lcv (@cmds) {
        $cmd = sprintf("${run_prefix}$lcv", $i);
        print "Running command: $cmd\n";
        system($cmd);
        print "\n";
    }

    print "DONE with $i\n\n";
    
}
