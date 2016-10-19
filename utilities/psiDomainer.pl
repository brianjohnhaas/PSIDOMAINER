#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;
use CdbTools;

my $usage = "\nusage: $0 fastaFile [EVALUE=1e-6]\n\n";

my $fastaFile = $ARGV[0] or die $usage;
my $EVALUE = $ARGV[1];
unless (defined $EVALUE) {
	$EVALUE = 1e-6;
}

my $min_peptide_length = 20;
my $init_database_size = undef;

main: {

	my %acc_to_FL_sequence = &parse_database_sequences($fastaFile);
	
	my $tmp_db = "tmp.$$.db";
	my $query_file = "tmp.$$.query";
	
	&filter_short_peptides($fastaFile, $tmp_db, $min_peptide_length);
	

	my %seq_lengths = &get_sequence_lengths($tmp_db);
	$init_database_size = &sum(values %seq_lengths);
	
	my $domain_counter = 0;

	my $round = 0;
	while (%seq_lengths) {
		$round++;
		print STDERR "round: $round\n";
		
		&process_cmd("cdbfasta $tmp_db 2> /dev/null"); # ensure fresh index
		
		my $shortest_seq = &find_shortest_sequence(%seq_lengths);
		&write_fasta_seq($shortest_seq, $tmp_db, $query_file);
		
		my %acc_to_hits = &run_psi_blast($query_file, $tmp_db);
		
		my @tentative_domains = &parse_domains($shortest_seq, $tmp_db, \%acc_to_hits);
		if (scalar @tentative_domains > 1) {
			$domain_counter++;
			foreach my $domain (@tentative_domains) {
				my ($peptide, $acc) = @$domain;
				my ($core_acc, @rest) = split (/;/, $acc);
				my $fl_seq = $acc_to_FL_sequence{$core_acc};
				my $peptide_len = length($peptide);
				my $pos = index($fl_seq, $peptide);
				if ($pos < 0) {
					die "Error, cannot locate peptide $peptide in flseq: $fl_seq";
				}
				my $rend = $pos + $peptide_len;
				my $lend = $pos + 1;
				print "D$domain_counter\t$peptide\t$core_acc\t$lend-$rend\n";
			}
			print "\n";
		}
		
		# note tmp_db is now replaced by the unmatched fragments by the above step.
		%seq_lengths = &get_sequence_lengths($tmp_db);
		
	}
	
	exit(0);

}



####
sub get_sequence_lengths {
	my ($fasta_file) = @_;

	my %seq_lengths;

	my $fasta_reader = new Fasta_reader($fasta_file);
	
	while (my $seq_obj = $fasta_reader->next()) {

		my $acc = $seq_obj->get_accession();
		my $sequence = $seq_obj->get_sequence();
		
		$seq_lengths{$acc} = length($sequence);
	}

	return (%seq_lengths);
}


####
sub process_cmd {
	my ($cmd) = @_;

	my $ret = system $cmd;
	if ($ret) {
		die "Error, cmd: $cmd died with ret $ret";
	}

}

####
sub sum {
	my @vals = @_;
	
	my $sum = 0;
	foreach my $val (@vals) {
		$sum += $val;
	}

	return ($sum);
}

	
####
sub find_shortest_sequence {
	my (%seq_lengths) = @_;

	my @accs = sort {$seq_lengths{$a}<=>$seq_lengths{$b}} keys %seq_lengths;

	my $shortest_seq = shift @accs;

	return ($shortest_seq);
}

####
sub write_fasta_seq {
	my ($acc, $fasta_db, $outputfile) = @_;

	my $fasta_seq = &cdbyank_linear($acc, $fasta_db);
	
	open (my $fh, ">$outputfile") or die "Error, cannot write to file $outputfile";
	print $fh ">querySeq\n$fasta_seq\n";
	close $fh;

	return;
}

####
sub filter_short_peptides {
	my ($fastaFile, $outputFile, $min_peptide_length) = @_;

	open (my $fh, ">$outputFile") or die "Error, cannot create output file $outputFile";

	my $fasta_reader = new Fasta_reader($fastaFile);
	while (my $seq_obj = $fasta_reader->next()) {
		my $fasta_format = $seq_obj->get_FASTA_format();
		my $sequence = $seq_obj->get_sequence();
		if (length($sequence) < $min_peptide_length) { 
			next;
		}
	
		print $fh $fasta_format;
	}
	close $fh;

	return;
}


#####
sub run_psi_blast {
	my ($query_file, $database) = @_;

	my $blast_output = "psiblastp.$$.out";
	
	my $cmd = "formatdb -p T -i $database";
	&process_cmd($cmd);

	# note blast parameters are those described in mkdom paper  (Gouzy, et al., 1999, Computers and Chemistry)
	$cmd = "blastpgp -d $database -i $query_file -m 8 -e $EVALUE -j 10 -h 1e-3 -G 9 -E 2 -c 2 -F F -v 10000 -b 10000 -z $init_database_size > $blast_output";
	&process_cmd($cmd);

	## parse output:
	my %hits;
	
	open (my $fh, $blast_output) or die "Error, cannot open file $blast_output";
	while (<$fh>) {
		chomp;
		my @x = split (/\t/);
		my ($query, $query_lend, $query_rend, $hit_acc, $hit_lend, $hit_rend) = ($x[0], $x[6], $x[7], $x[1], $x[8], $x[9]);
		push (@{$hits{$hit_acc}}, [$hit_lend, $hit_rend]);
		push (@{$hits{$query}}, [$query_lend, $query_rend]);
	}
	
	close $fh;

	unlink($blast_output);
	
	return (%hits);
}

####
sub parse_domains {
	my ($shortest_seq, $db, $acc_to_hits_href) = @_;

	my @domains; 
	my $tmp_db = "tmp.$$.db2";
	open (my $fh, ">$tmp_db") or die "Error, cannot open $tmp_db";
	
	my $fasta_reader = new Fasta_reader($db);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		my $sequence = $seq_obj->get_sequence();
		
		my $hits_aref = $acc_to_hits_href->{$acc};
		if (ref $hits_aref) {
			my @hits = @$hits_aref;
			my @seqchars = split (//, $sequence);
			my @chosen;
			foreach my $hit (@hits) {
				if (&overlaps_chosen_hits($hit, \@chosen)) {
					next;
				}
				my ($lend, $rend) = @$hit;
				push (@chosen, $hit);
				
				my $peptide = substr($sequence, $lend - 1, $rend - $lend + 1);
				push (@domains, [$peptide, $acc]) if (length($peptide) >= $min_peptide_length);
				for (my $i = $lend; $i <= $rend; $i++) {
					$seqchars[$i-1] = 'X';
				}
			}
			if ($acc eq $shortest_seq) {
				next;
			}
			my $newseq = join ("", @seqchars);
			my @remaining_peptides;
			while ($newseq =~ /([^X]+)/g) {
				push (@remaining_peptides, $1);
			}
			my $counter = 0;
			foreach my $remaining_peptide (@remaining_peptides) {
				if (length($remaining_peptide) >= $min_peptide_length) {
					$counter++;
					print $fh ">$acc;$counter\n$remaining_peptide\n";
				}
			}
		}
		elsif ($acc ne $shortest_seq) {
			print $fh ">$acc\n$sequence\n";
		}
	}
	
	close $fh;
	
	&process_cmd("mv $tmp_db $db");

	return (@domains);

}

####
sub overlaps_chosen_hits {
	my ($hit, $hit_list_aref) = @_;

	my ($lend, $rend) = @$hit;

	foreach my $other_hit (@$hit_list_aref) {
		my ($other_lend, $other_rend) = @$other_hit;
		
		if ($other_lend < $rend && $other_rend > $lend) {
			# got overlap
			return (1);
		}
	}

	return (0); # no overlap detected
}


####
sub parse_database_sequences {
	my ($fasta_file) = @_;

	my %acc_to_seq;
	
	my $fasta_reader = new Fasta_reader($fasta_file);
	while (my $seq_obj = $fasta_reader->next()) {
		
		my $acc = $seq_obj->get_accession();
		my $sequence = $seq_obj->get_sequence();
		
		$acc_to_seq{$acc} = $sequence;
	}

	return (%acc_to_seq);
}
