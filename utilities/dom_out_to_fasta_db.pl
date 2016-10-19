#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 outputFromMkdom\n\n";

my $mkdomOut = $ARGV[0] or die $usage;

my %domCounter;

open (my $fh, $mkdomOut) or die "Error, cannot open file $mkdomOut";
while (<$fh>) {
	chomp;
	unless (/\w/) { next; }

	my ($dom_acc, $peptide, @rest) = split (/\t/);
	
	$peptide =~ s/(\S{60})/$1\n/g;
	chomp $peptide;
	
	my $dom_accession = $dom_acc . "." . ++$domCounter{$dom_acc};

	print ">$dom_accession " . join (" ", @rest) . "\n$peptide\n";
	
}
close $fh;


exit(0);

