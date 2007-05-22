#!/usr/bin/perl
# zdispData.pl - extract the node z-disp histories along an output line into
# individual ASCII files to be read into a post-processor.  ls-prepost2 is used
# to extract the data from d3plot files since node history data is in different
# formats when run using ls-dyna vs. mpp-dyna
#
# INPUTS: None (but run-time variables are defined below)
# OUTPUTS: zdispData directory is created with individual ASCII files named by
#   nodes ID (e.g., n######zdisp.asc); these files have two columns of data 
#   (time & z displacement) in the units of the simulation
#
# Mark 05/21/07

use warnings;
use strict;
use fem;

# define parameters for the data extraction
my $depth = -1.5; # cm
my $SearchTol = 0.0001; # spatial search tolerance
my $x_face = 0; # x-coordinate to find the face of interest
my $nodeFileName = 'sw_nodes.dyn';

# make sure that d3plot files exist before doing anything else
if (-e 'd3plot' == 0) { die "d3plot files are not present in the CWD"; }

# create the ASCII output directory
if (-e 'zdispData') { die "zdispData directory already exists"; }
else { system("mkdir zdispData"); }

our %nodeCoords = fem::readNodesCoords($nodeFileName);
my @nodeIDs = keys %nodeCoords;

# how many node IDs have to be processed
my $numNodeIDs = $#nodeIDs + 1;

# create a hash of the output nodes (not sorted yet)
foreach our $nodeID (@nodeIDs) {
    our %outputNodes; 
    if (abs($nodeCoords{$nodeID}[0] - $x_face) < $SearchTol && abs($nodeCoords{$nodeID}[2] - $depth) < $SearchTol) {
        $outputNodes{$nodeID} = $nodeCoords{$nodeID}[1];
    }
}

my @outNodes = keys our %outputNodes;
my $numOutNodes = $#outNodes + 1;
print "$numOutNodes of $numNodeIDs nodes are being output\n";

# sort output nodes by increasing y-coordinate
my @sortedOutNodes = sort { $outputNodes{$a} cmp $outputNodes{$b} } keys %outputNodes;

# create the lookup table and ls-prepost2 command file
open(LOOKUP,">zdispData/zdispDataNodes.asc") || die "zdispDataNodes.asc cannot be created";
open(CFILE,">zdispData.cfile") || die "zdispData.cfile cannot be created";
print CFILE "openc d3plot \"d3plot\"\n";
print CFILE "ntime 7 @sortedOutNodes\n";
for my $nodeCount ( 0 .. $#sortedOutNodes ) {
    my $nodeCount_p1 = $nodeCount + 1;
    print LOOKUP "$nodeCount_p1,$sortedOutNodes[$nodeCount]\n";
    print CFILE "xyplot 1 savefile xypair \"zdispData/n$nodeCount_p1.asc\" 1 $nodeCount_p1\n";
}
close(CFILE);
close(LOOKUP);