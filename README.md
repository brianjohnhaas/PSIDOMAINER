Given a protein multi-fasta file, PsiDomainer will compute a domain structure based on regions of homology found in common between segments of protein sequences.

PsiDomainer is a reimplementation of 'domainer' described by ProDom.  PsiDomainer extends the algorithm in an attempt to unify likely domain fragments.

Requirements:
*  you must have the the utilities 'cdbyank' and 'cdbfasta' available in via your PATH setting.
*  you must have NCBI blast installed (including blastpgp)
 

Usage:

     % run_PsiDomainer.pl  /path/to/target_protein_database.fasta


The above script will generate several tmp files, in addition to two primary output files:

	${filename}.psiDom.FINAL_domains.structure
    ${filename}.psiDom.FINAL_domains.pep




