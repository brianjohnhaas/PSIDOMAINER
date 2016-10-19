#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: ItolDomainsFile pseudogene_accessions [length=200]\n\n";

my $itolFile = $ARGV[0] or die $usage;
my $pseudogene_accs = $ARGV[1] or die $usage;
my $pseudo_glyph_length = $ARGV[2] || 200;

my %pseudo;
{
	open (my $fh, $pseudogene_accs) or die "Error, cannot open file $pseudogene_accs\n";
	while (<$fh>) {
		s/\s+//g;
		$pseudo{$_} = 1;
	}
	close $fh;
}


open (my $fh, $itolFile) or die "Error, cannot open file $itolFile";
while (<$fh>) {
	chomp;
	my @x = split (/,/);
	my $acc = $x[0];
	if ($pseudo{$acc}) {
		my $seqLen = $x[1];
		push (@x, "EL|" . ($seqLen+1) . "|" . ($seqLen+$pseudo_glyph_length) . "|#000000|PSEUDO");
		$x[1] += $pseudo_glyph_length;
		
		print join (",", @x) . "\n";
	}
	else {
		print "$_\n";
	}
}


exit(0);


	
	
		
		
		
