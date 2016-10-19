#!/usr/bin/env perl

use strict;
use warnings;

use List::Util qw (shuffle);
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use ColorGradient;

my $usage = "\n\nusage: $0 domainAssignments.txt seqLengthsFile.txt [glyps_n_colors]\n\n"
	. "-specify glyphs_n_colors filename to either load in a set of preferences or to write auto-chosen ones out.\n"
	. "The decision to read or write is based on whether the filename exists or not.\n\n\n\n";;

my $domains_file = $ARGV[0] or die $usage;
my $seqlengths_file = $ARGV[1] or die $usage;
my $glyphs_n_colors_file = $ARGV[2];

my %acc_to_domain_list;
my %domain_tracker;
my %seq_lengths;


my $MAX_SCALED_SEQ_LENGTH = 1000;
my $MAX_SEQ_LENGTH = 0;
my $SCALE_SEQS_FLAG = 1;

## parse seqlengths
open (my $fh, $seqlengths_file) or die "Error, cannot open file $seqlengths_file";
while (<$fh>) {
	chomp;
	my ($seqlength, $acc, @rest) = split (/\s+/);
	$seq_lengths{$acc} = $seqlength;
	if ($seqlength > 2000) {
		$SCALE_SEQS_FLAG = 1;
	}
	if ($seqlength > $MAX_SEQ_LENGTH) {
		$MAX_SEQ_LENGTH = $seqlength;
	}
}
close $fh;


open ($fh, $domains_file) or die "Error, cannot read $domains_file";
while (<$fh>) {
	chomp;
	my ($acc, @domains) = split (/\t/);
	foreach my $domain (@domains) {
		$domain =~ /^(\w+)\[(\d+)-(\d+),?/ or die "Error, cannot pattern match on domain: $domain";
		my ($domain, $lend, $rend) = ($1, $2, $3);
		
		push (@{$acc_to_domain_list{$acc}}, { domain => $domain,
											  lend => $lend,
											  rend => $rend,
										  });
		
		$domain_tracker{$domain} = 1;
	}
}
close $fh;


my %domain_to_glyph_n_color;
if ($glyphs_n_colors_file && -s $glyphs_n_colors_file) {
	open (my $fh, $glyphs_n_colors_file) or die "Error, cannot open file $glyphs_n_colors_file";
	while (<$fh>) {
		unless (/\w/) { next; }
		chomp;
		my ($domain, $glyph_type, $color) = split (/\t/);
		$domain_to_glyph_n_color{$domain} = { glyph => $glyph_type,
											  color => $color,
										  };
	}
	close $fh;
} 
else {
	## assign glyphs and colors to domains:
	
	my @domains = keys %domain_tracker;
	my $num_domains = scalar @domains;
	my @color_gradient = &ColorGradient::convert_RGB_hex(&ColorGradient::get_RGB_gradient($num_domains));
	@color_gradient = shuffle(@color_gradient);
	@domains = shuffle(@domains);
	
	my @glyph_types = qw (RE HH HV EL DI TR TL);
	my $num_glyph_types = scalar (@glyph_types);
	
	my $domain_count = 0;
	foreach my $domain (@domains) {
		my $color = shift @color_gradient;
		my $glyph = $glyph_types[ $domain_count % $num_glyph_types ];
		$domain_to_glyph_n_color{$domain} = { glyph => $glyph,
											  color => $color };
		$domain_count++;
	}
	
}


## write glyphn n color info to a file as needed.	
if ($glyphs_n_colors_file && ! -s $glyphs_n_colors_file) {
	open (my $fh, ">$glyphs_n_colors_file") or die "Error, cannot write to file $glyphs_n_colors_file";
	foreach my $domain (sort keys %domain_to_glyph_n_color) {
		my $struct = $domain_to_glyph_n_color{$domain};
		my $glyph = $struct->{glyph};
		my $color = $struct->{color};
		
		print $fh "$domain\t$glyph\t$color\n";
	}
	close $fh;
}


## output the IToL formatted domain file.
foreach my $acc (keys %acc_to_domain_list) {
	
	my @domains = @{$acc_to_domain_list{$acc}};
	@domains = sort {$a->{lend}<=>$b->{lend}} @domains;
	
	my $seqlength = $seq_lengths{$acc} || die "Error, cannot find seqlength for $acc";

	if ($SCALE_SEQS_FLAG) {
		$seqlength = int ($seqlength / $MAX_SEQ_LENGTH * $MAX_SCALED_SEQ_LENGTH + 0.5);
	}
	
	print "$acc,$seqlength";

	my $prev_rend = 0;
	foreach my $domain (@domains) {
		my ($domain_name, $lend, $rend) = ($domain->{domain},
										   $domain->{lend},
										   $domain->{rend});
		
		# print STDERR "before ($lend, $rend) ";
		if ($SCALE_SEQS_FLAG) {
			$lend = int ($lend / $MAX_SEQ_LENGTH  * $MAX_SCALED_SEQ_LENGTH+ 0.5);
			$rend = int ($rend / $MAX_SEQ_LENGTH * $MAX_SCALED_SEQ_LENGTH + 0.5);
		}
		
		if ($lend <= $prev_rend) {
			$lend = $prev_rend + 1;
		}
		# print STDERR "after ($lend, $rend)\n";
		
		my $glyph_n_color_ref = $domain_to_glyph_n_color{$domain_name} or die "Error, no glyph_n_color ref for $domain_name";
		my $glyph = $glyph_n_color_ref->{glyph};
		my $color = $glyph_n_color_ref->{color};
		
		print ",$glyph|$lend|$rend|$color|$domain_name";
		
		$prev_rend = $rend;
	}
	print "\n";
}


exit(0);


		




	




