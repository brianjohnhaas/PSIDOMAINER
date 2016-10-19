#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Basename;

my $usage = "\nusage: $0 proteins.multiFasta [EVALUE=1e-6]\n\n";

my $proteins_file = $ARGV[0] or die $usage;
my $EVALUE = $ARGV[1] || 1e-6;

my $proteins_file_basename = basename($proteins_file);

my $utility_dir = $FindBin::Bin . "/utilities";

main: {
  ## use psiblast to compute homology regions (domains or domain fragments)
  my $cmd = "$utility_dir/psiDomainer.pl $proteins_file_basename $EVALUE > $proteins_file_basename.psiDom.tmp";
  &process_cmd($cmd);
  
  ## describe domains found in the context of the larger protein sequence
  $cmd = "$utility_dir/dom_out_to_multiDomainStructure.pl $proteins_file_basename.psiDom.tmp > $proteins_file_basename.psiDom.prelim_domain_structure.tmp";
  &process_cmd($cmd);

  ## determine if any of the 'domains' look like fragments to be joined into a more complete domain structure
  $cmd = "$utility_dir/find_likely_domain_fragments.pl  $proteins_file_basename.psiDom.prelim_domain_structure.tmp >  $proteins_file_basename.psiDom.connected_domain_fragments.tmp";
  &process_cmd($cmd);

  ## now, report the domain structure with domain fragments unified
  $cmd = "$utility_dir/join_domain_fragments.pl $proteins_file_basename.psiDom.prelim_domain_structure.tmp $proteins_file_basename.psiDom.connected_domain_fragments.tmp | sort -k 2 > $proteins_file_basename.psiDom.FINAL_domains.structure";
  &process_cmd($cmd);

  ## report domain combinations
  $cmd = "$utility_dir/dom_combos_to_fasta.pl $proteins_file_basename.psiDom.FINAL_domains.structure $proteins_file > $proteins_file_basename.psiDom.FINAL_domains.pep";
  &process_cmd($cmd);
  
  print "\n\nDone.\nSee files *.FINAL_domains.*\n\n\n";
  
  exit(0);
  
}


####
sub process_cmd {
  my ($cmd) = @_;

  print "-executing: $cmd\n\n\n";
  my $ret = system ($cmd);

  if ($ret) {
	die "Error, cmd: $cmd died with ret($ret)";
  }
  return;
}
  
  
  
