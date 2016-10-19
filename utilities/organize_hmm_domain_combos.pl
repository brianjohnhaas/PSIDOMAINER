#!/usr/bin/env perl

use strict;
use warnings;

use lib $ENV{EUK_MODULES};
use DPchain;


my %acc_to_domain_list;

while (<>) {
	chomp;
	my @x = split (/\t/);
	unless ($x[0] eq 'DOMAIN') {
		next;
	}
	
	my ($acc, $domain_acc, $lend, $rend, $bit_score, $evalue) = ($x[1], $x[2], $x[6], $x[7], $x[8], $x[11]);
	unless ($bit_score > 0) { next;}
	
	push (@{$acc_to_domain_list{$acc}}, { domain => $domain_acc,
										  lend => $lend,
										  rend => $rend,
										  bit_score => $bit_score,
										  evalue => $evalue, } );
}


my $get_base_score_sref = sub {
	my ($struct_href) = @_;
	return ($struct_href->{bit_score});
};

my $are_chainable_sref = sub {
	my ($before_href, $after_href) = @_;

	if ($after_href->{lend} > $before_href->{rend} - 5) {
		return (1);
	}

	return (0);
};




foreach my $acc (keys %acc_to_domain_list) {
	my @domains = sort {$a->{lend}<=>$b->{lend}} @{$acc_to_domain_list{$acc}};
	
	## dp scan to connect 
	my @chained_domains = &DPchain::find_highest_scoring_chain(\@domains, $get_base_score_sref, $are_chainable_sref);
		
	my @domain_combo;
	print "$acc";
	foreach my $domain (@chained_domains) {
		my ($domain_acc, $lend, $rend, $evalue, $bit_score) = ($domain->{domain},
															   $domain->{lend},
															   $domain->{rend},
															   $domain->{evalue},
															   $domain->{bit_score});
		
		print "\t[$domain_acc $lend-$rend E:$evalue S:$bit_score] ";
		push (@domain_combo, $domain_acc);
	}
	print "\n";
	
	print "COMBO:$acc\t" . join ("_", @domain_combo) . "\n";
}

exit(0);


