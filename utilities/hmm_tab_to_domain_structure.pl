#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use DPchain;

my $usage = "usage: $0 hmmpfam_results_parsed.tab [DP_flag=0] [protToCDScoordFlag=0]\n\n";

my $domain_hits_file = $ARGV[0] or die $usage;
my $DPflag = $ARGV[1] || 0;
my $protCoordToCDScoord = $ARGV[2] || 0;

my $ALLOWABLE_OVERLAP = 10; ## allow domains to overlap by no more than 10 bases.


my %acc_to_domain_hits;
open (my $fh, $domain_hits_file) or die "Error, cannot open file $domain_hits_file";
while (<$fh>) {
	chomp;
	my @x = split (/\t/);
	my ($seq_acc, $domain_instance, $evalue, $score, $orient, $lend, $rend) = ($x[1], $x[2], $x[11], $x[8], 1, $x[6], $x[7]);
	if ($orient < 0) { next; } # not counting matches to opposite strand. weird.

	my ($core_domain, $domain_entry) = split (/\./, $domain_instance);

	push (@{$acc_to_domain_hits{$seq_acc}->{$core_domain}}, { domain => $core_domain,
															  lend => $lend,
															  rend => $rend,
															  score => $score, 
															  evalue => $evalue,
														  } );
	
}
close $fh;



foreach my $acc (keys %acc_to_domain_hits) {
	
	my @chosen_domains;
		
	foreach my $core_domain (keys %{$acc_to_domain_hits{$acc}}) {
		
		my @instances = reverse sort {$a->{score}<=>$b->{score}} @{$acc_to_domain_hits{$acc}->{$core_domain}};
		
		foreach my $instance (@instances) {
			if (! &overlaps(\@chosen_domains, $instance) ) {
				push (@chosen_domains, $instance);
			}
		}
	}
		
	if ($DPflag) {
		@chosen_domains = &find_highest_scoring_nonoverlapping_domains(@chosen_domains);
	}
	
	@chosen_domains = sort {$a->{lend}<=>$b->{lend}
							||
								$b->{score}<=>$a->{score}
							
						} @chosen_domains;
	
	
	print "$acc";
	foreach my $chosen_domain (@chosen_domains) {
		my ($domain, $lend, $rend, $evalue, $score) = ($chosen_domain->{domain}, 
													   $chosen_domain->{lend}, 
													   $chosen_domain->{rend}, 
													   $chosen_domain->{evalue}, 
													   $chosen_domain->{score});
		
 
		if ($protCoordToCDScoord) {
			$lend = $lend * 3 - 2;
			$rend = $rend * 3;
		}
		
		print "\t$domain\[$lend-$rend,$evalue,$score]";
	}
	
	print "\n";
	
}

exit(0);

####
sub overlaps {
	my ($domain_list_aref, $instance) = @_;

	my ($instance_domain, $instance_lend, $instance_rend) = ($instance->{domain}, $instance->{lend}, $instance->{rend});

	foreach my $domain (@$domain_list_aref) {
		my ($dom_domain, $dom_lend, $dom_rend) = ($domain->{domain}, $domain->{lend}, $domain->{rend});
		

		if ($instance_domain eq $dom_domain) {

			if ($instance_lend < $dom_rend && $instance_rend > $dom_lend) {
				
				## yes, overlaps
				return(1);
			}
		}
	}

	return (0);
}


####
sub find_highest_scoring_nonoverlapping_domains {
	my @chosen_domains = @_;

	@chosen_domains = sort {$a->{lend}<=>$b->{lend}} @chosen_domains;

	my $base_score_sref = sub { my $ele = shift; return ($ele->{score}); };
	
	my $are_chainable_sref = sub { my $before = shift;
								   my $after = shift;
								   if ($after->{lend} >= $before->{rend} - $ALLOWABLE_OVERLAP) {
									   return (1);
								   }
								   else {
									   return (0);
								   }
							   };

	my @highest_scoring_chain = &DPchain::find_highest_scoring_chain(\@chosen_domains, $base_score_sref, $are_chainable_sref);

	return (@highest_scoring_chain);
}


	
		
		
