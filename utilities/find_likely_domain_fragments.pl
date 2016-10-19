#!/usr/bin/env perl

use strict;
use warnings;

my %nodes;

while (<>) {
	chomp;
	my ($gene, $domain_list) = split (/\s+/, $_, 2);
	my @domains = split (/\s+/, $domain_list);
	my $curr_domain = $domains[0];
	for (my $i = 1; $i <= $#domains; $i++) {
		my $next_domain = $domains[$i];
		
		$curr_domain =~ s/\[\d+-\d+\]//;
		$next_domain =~ s/\[\d+-\d+\]//;
		
		&add_domain_link($curr_domain, $next_domain);
		$curr_domain = $next_domain;
	}
}

## find node series at termini or between branchpoints
## starting from a node with no parents or multiple parents, 
## walk until no children or many children.

my %seen;
foreach my $node_acc (keys %nodes) {
	
	if ($seen{$node_acc}) { next; }
	$seen{$node_acc} = 1;
	
	my $node_ref = &get_node($node_acc);
	my @parents = @{$node_ref->{parents}};
	my @children = @{$node_ref->{children}};
	
	if ( (scalar (@parents) == 0 || scalar(@parents) > 1) && scalar(@children) == 1) {
		
		# walk it:
		my @walked_nodes;
		my $curr_node_acc = $node_acc;
		my $curr_node_ref = $node_ref;
		$seen{$curr_node_acc} = 1;
		push (@walked_nodes, $curr_node_acc);
		@parents = (undef); # one parent
		while (scalar(@parents) == 1 && scalar(@children) == 1) {
			$curr_node_acc = $children[0];
			if ($seen{$curr_node_acc}) { last; } # cycle
			$curr_node_ref = &get_node($curr_node_acc);
			@children = @{$curr_node_ref->{children}};
			@parents = @{$curr_node_ref->{parents}};
			$seen{$curr_node_acc} = 1;
			push (@walked_nodes, $curr_node_acc);
		}
		
		if (scalar @walked_nodes > 1) {
			print join ("-", @walked_nodes) . "\n";
		}
	}
	
}

exit(0);



####
sub add_domain_link {
	my ($curr_domain, $next_domain) = @_;
	
	my $node = &get_node($curr_domain);
	&add_next_node($node, $next_domain);
	
	return;
}


####
sub get_node {
	my ($node_name) = @_;

	my $node = $nodes{$node_name};
	unless (ref $node) {
		$node = $nodes{$node_name} = { name => $node_name,
									   children => [],
									   parents => [],
									   
								   };
	}

	return ($node);
}

####
sub add_next_node {
	my ($node_ref, $next_domain) = @_;
	
	## add next domain as a child of node
	unless (&contains($node_ref->{children}, $next_domain)) {
		push (@{$node_ref->{children}}, $next_domain);
	}
	
	## add node as a parent of next domain

	my $next_domain_ref = &get_node($next_domain);
	unless (&contains($next_domain_ref->{parents}, $node_ref->{name})) {
		push (@{$next_domain_ref->{parents}}, $node_ref->{name});
	}
	
	return;
}

####
sub contains {
	my ($list_aref, $entry) = @_;

	foreach my $ele (@$list_aref) {
		if ($ele eq $entry) {
			return (1);
		}
	}
	
	return (0);
}
