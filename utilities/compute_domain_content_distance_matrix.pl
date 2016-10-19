#!/usr/bin/env perl

use strict;
use warnings;

my @entries;
while (<>) {
	chomp;
	my ($acc, $domain_content) = split (/\s+/);
	$acc =~ s/COMBO://;
	my @domains = split (/_/, $domain_content);
	my %domain_content;
	
	foreach my $domain (@domains) {
		$domain_content{$domain} = 1;
	}
	push (@entries, [$acc, \%domain_content]);
	
}

my $counter=0;
my @distances;
foreach my $entry (@entries) {
	$counter++;
	my $row = [];
	push (@distances, $row);
	my ($acc, $domains_href) = @$entry;
	push (@$row, $acc);
	print STDERR "processing: $acc ($counter)\n";
	
	foreach my $other_entry (@entries) {
		my ($other_acc, $other_domains_href) = @$other_entry;
		my $distance = compute_distance($domains_href, $other_domains_href);
		push (@$row, $distance);
	}
	
}
	
my $num_accs = scalar (@distances);
print "    $num_accs\n";
foreach my $distance (@distances) {
	print join (" ", @$distance) . "\n";
}

exit(0);

	
####
sub compute_distance {
	my ($domainsA_href, $domainsB_href) = @_;

	## how many domains are the same?
	
	my $num_domainsA = scalar (keys %$domainsA_href);
	my $num_domainsB = scalar (keys %$domainsB_href);

	my $smaller_num_domains = ($num_domainsA < $num_domainsB) ? $num_domainsA : $num_domainsB;
	
	my $num_in_common = 0;
	foreach my $domain (keys %$domainsA_href) {
		if ($domainsB_href->{$domain}) {
			$num_in_common++;
		}
	}
	
	# print "small: $smaller_num_domains\tcommon: $num_in_common\n";
	
	my $distance = $smaller_num_domains - $num_in_common;
	
	return ($distance);
}
