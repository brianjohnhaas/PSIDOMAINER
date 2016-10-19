#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 domain_combos_file domain_frags_file\n\n";

my $combos_file = $ARGV[0] or die $usage;
my $frags_file = $ARGV[1] or die $usage;

my %frag_nodes;
{
	my $domain_counter = 0;
	open (my $fh, $frags_file) or die "Error, cannot open $frags_file";
	while (<$fh>) {
		chomp;
		$domain_counter++;
		my $new_domain_name = "DN$domain_counter";
		my @domains = split (/-/);
		
		my $curr_domain = shift @domains;
		my $curr_node = { 'prev' => undef,
						  'acc' => $curr_domain,
						  'next' => undef,
						  'newname' => $new_domain_name,
					  };
		
		$frag_nodes{$curr_domain} = $curr_node;

		while (@domains) {
			my $next_domain = shift @domains;
			my $next_node = { 'prev' => $curr_node,
							  'acc' => $next_domain,
							  'next' => undef, 
							  'newname' => $new_domain_name,
						  };
			
			$curr_node->{next} = $next_node;
			
			$frag_nodes{$next_domain} = $next_node;
			
			$curr_node = $next_node;
		}
	}
	close $fh;
}

open (my $fh, $combos_file) or die "Error, cannot open file $combos_file";
while (<$fh>) {
	my $line = $_;
	chomp;
	my ($acc, @domains) = split (/\s+/);
	my @domain_refs;
	
	my $got_fragment_flag = 0;

	foreach my $domain (@domains) {
		$domain =~ /^(D\d+)\[(\d+)-(\d+)\]$/ or die "Error, cannot parse domain txt $domain";
		my ($domain_acc, $lend, $rend) = ($1, $2, $3);
		push (@domain_refs, { acc => $domain_acc,
							  lend => $lend,
							  rend => $rend,
						  });
		if ($frag_nodes{$domain_acc}) {
			$got_fragment_flag = 1;
		}
	}

	unless ($got_fragment_flag) {
		print $line;
		next;
	}

	my @new_domains;
	while (@domain_refs) {
		my $domain = shift @domain_refs;
		if (my $node = $frag_nodes{$domain->{acc}}) {
			my @combine = ($domain);
			while (@domain_refs && $node->{'next'} && $node->{'next'}->{'acc'} eq $domain_refs[0]->{acc}) {
				my $domain = shift @domain_refs;
				push (@combine, $domain);
				$node = $node->{next};
			}
			push (@new_domains, [@combine]);
		}
		else {
			push (@new_domains, $domain);
		}
	}
	
	## report adjusted domain structure, frags joined.
	my $outline = "$acc";
	foreach my $new_domain (@new_domains) {
		if (ref $new_domain eq 'HASH') {
		    $outline .= "\t" . $new_domain->{acc} . "[" . $new_domain->{lend} . "-" . $new_domain->{rend} . "]";
		}
		else {
			my @coords;
			foreach my $domain (@$new_domain) {
				push (@coords, $domain->{lend}, $domain->{rend});
			}
			my $example_frag_domain = $new_domain->[0]->{acc};
			my $domain_name = $frag_nodes{$example_frag_domain}->{newname};
			@coords = sort {$a<=>$b} @coords;
			my $lend = shift @coords;
			my $rend = pop @coords;
			$outline .= "\t$domain_name\[$lend-$rend]";
		}
		
	}
	print $outline . "\n";
}



exit(0);


	
				   



