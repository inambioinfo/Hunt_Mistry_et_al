#!/share/apps/perl-5.14.2/bin/perl

use lib '/data_n2/vplagnol/libraries/perl/bioperl-live';
use lib '/data_n2/vplagnol/libraries/perl/ensembl_70/modules';

use DBI;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;

use strict;

my $output = "test_out.tab";
my $geneList = "/cluster/project2/vyp/HCM_heart_hospital/sequence_data/support/capture/HCM_geneList.tab";


if ($#ARGV != 2) {die "There should be 2 arguments as follows:\n ./scripts/create_regions.pl genelist outputFile extraBpOnSides";}
my $geneList = $ARGV[0];
my $output = $ARGV[1];
my $extraBpOnSides = $ARGV[2];

###########################                                                                                                                                                                                     
##First of all we need to have a hash table to match gene name with stable IDs from ensembl

my %nameToEnsembl = ();

open (DB, " < support/biomart_refseq_hsapiens_gene_ensembl.tab") or die "Cannot open database";
while (<DB>) {
    chomp $_;
    my @spl = split('\t', $_);
    
    if ($spl[3] eq "HG1304_PATCH") {next;}

    if ($spl[2] ne "") {
	$nameToEnsembl{ $spl[2] } = $spl[1];
    }
}
close (DB);
  
###########################  load the local registry that stores all the data (could read form the web, but locally is faster)
my $registry = 'Bio::EnsEMBL::Registry';

Bio::EnsEMBL::Registry->load_registry_from_db(
  -host    => 'ensembldb.ensembl.org',
  -user    => 'anonymous',
  -verbose => '1');

#$registry->load_registry_from_db(
#				 -host => 'wilder.local',
#				 -user => 'plagnol',
#				 -pass => 'pl@gn0lvi',
#				 -port => 22222,
#				 -database => 'human'
#				 );


my $gene_adaptor    = Bio::EnsEMBL::Registry->get_adaptor( 'homo_sapiens', 'Core', 'Gene' ) or die "Can't get tr_adaptor for:'homo_sapiens', 'Core', 'Transcript' \n";;


################ Now read all the gene names
open (OUT, "> $output") or die "Cannot open $output for writing\n";
open (INP, " < $geneList") or die "Cannot read $geneList\n";

while (<INP>) {
    chomp $_;
    my $geneName = $_;    

    if (!exists $nameToEnsembl{ $geneName }) {
	print "Cannot find a stable ID for $geneName\n";
	next;
    }
    my $stableid = $nameToEnsembl{ $geneName };    
    my $gene = $gene_adaptor->fetch_by_stable_id($stableid);


    if (!defined($gene)) {
	print $geneName."  returns and undefined value.";
	next;
    }

    ##############################################################
    # Get all Transcripts for the Gene and use one with most exons
    ##############################################################
    my (@stable_id);my (@start);my(@end);my(@strand);       
    my ($trans, %h) = ();  
    my $exons = 0;    

    foreach my $transcript (@{$gene->get_all_Transcripts}) {
	my $trans_name = $transcript->external_name() || $transcript->stable_id();
	if(scalar(@{ $transcript->get_all_Exons() }) > $exons){
	    $exons = scalar(@{ $transcript->get_all_Exons() });
	    $trans = $trans_name;
	}
    }

    
############# Now we print the informatin we need
    foreach my $transcript (@{$gene->get_all_Transcripts}) {
	next unless $trans eq ($transcript->external_name() || $transcript->stable_id());
	my $name = $transcript->external_name() || $transcript->stable_id() || 'test';
	$name = $transcript->stable_id();
	
	my @exons = @{ $transcript->get_all_Exons() };
	
	my $nb = 1;
	print OUT $gene->seq_region_name."\t".$gene->start."\t".$gene->end."\t".$geneName."_full"."\t".$geneName."\n";
	if(scalar(@exons) > 1){
	    foreach my $e(@exons){
		my $nstart = $e->start - $extraBpOnSides;
		my $nend = $e->end + $extraBpOnSides;

		print OUT $e->seq_region_name."\t".$nstart."\t".$nend."\t".$geneName."_".$nb."\t".$geneName."\n";
		$nb = $nb + 1;
	    }
	}
    }
}

close (INP);
close (OUT);
print "Final output in $output\n";
