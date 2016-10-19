#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use CdbTools;

my $usage = "domain_combos_file  proteins_db.fasta\n\n";

my $domain_combos_file = $ARGV[0] or die $usage;
my $proteins_fasta = $ARGV[1] or die $usage;

my %domain_counter;

open (my $fh, "$domain_combos_file") or die "Error, cannot open file $domain_combos_file";
while (<$fh>) {
	chomp;
	my ($acc, @domains) = split (/\s+/);
	my $protein_seq = &cdbyank_linear($acc, $proteins_fasta);
	
	foreach my $domain (@domains) {
		$domain =~ /^(\w+)\[(\d+)-(\d+)\]$/ or die "Error, cannot parse domain info from $domain";
		my $domain_acc = $1;
		my $lend = $2;
		my $rend = $3;
	
		my $domain_name = $domain_acc . "." . ++$domain_counter{$domain_acc};
		my $peptide = substr($protein_seq, $lend - 1, $rend - $lend + 1);
		print ">$domain_name $acc $lend-$rend\n$peptide\n";
	}
}
close $fh;

exit(0);




	
		
