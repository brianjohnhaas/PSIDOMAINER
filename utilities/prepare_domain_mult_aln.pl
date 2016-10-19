#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;

my $usage = "\nusage: $0 domain.pepFile\n\n";

my $domains_txt = $ARGV[0] or die $usage;

my $domain_mult_aln_dir = "domain_mult_aln";
if (-d $domain_mult_aln_dir) {
	die "Error, dir $domain_mult_aln_dir exists already";
}
else {
	mkdir ($domain_mult_aln_dir) or die "Error, cannot mkdir $domain_mult_aln_dir";
}

my $fasta_reader = new Fasta_reader($domains_txt);
while (my $seq_obj = $fasta_reader->next()) {
	my $acc = $seq_obj->get_accession();
	my $sequence = $seq_obj->get_sequence();

	$acc =~ /^(\w+)\./;
	my $core_acc = $1 or die "Error, cannot parse domain name from $acc";
	
	open (my $fh, ">>$domain_mult_aln_dir/$core_acc") or die "Error, cannot open file $domain_mult_aln_dir/$core_acc";
	print $fh ">$acc\n$sequence\n";
	close $fh;
}




exit(0);

