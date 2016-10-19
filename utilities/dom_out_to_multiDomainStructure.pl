#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 mkdomOutputFile\n\n";

my $domOut = $ARGV[0] or die $usage;


my %acc_to_domains;

open (my $fh, $domOut) or die "Error, cannot open file $domOut";
while (<$fh>) {
	chomp;
	unless (/\w/) { next; }
	my ($domain_acc, $peptide, $seqAcc, $range) = split (/\t/);
	my ($lend, $rend) = split (/-/, $range);
	push (@{$acc_to_domains{$seqAcc}}, { domain => $domain_acc,
										 lend => $lend,
										 rend => $rend, 
									 } );
}
close $fh;

foreach my $acc (sort keys %acc_to_domains) {
	my @domains = sort {$a->{lend}<=>$b->{lend}} @{$acc_to_domains{$acc}};
	
	my @domain_report;
	foreach my $domain (@domains) {
		my ($domAcc, $lend, $rend) = ($domain->{domain}, $domain->{lend}, $domain->{rend});
		push (@domain_report, "$domAcc\[$lend-$rend]");
	}
	
	print "$acc\t" . join (" ", @domain_report) . "\n";
}


exit(0);


	
