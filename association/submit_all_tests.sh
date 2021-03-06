grep full support/target_regions.tab | while read chr start end code gene; do

    for pheno in control_psoriasis control_coeliac control_crohns control_AITD control_ms control_t1d control_allAID; do
    #for pheno in control_allAID; do
    #for pheno in control_crohns; do
	
	script=cluster/submission/C${code}_${pheno}.sh
	
	echo "
#!/bin/bash
#$ -S /bin/bash
#$ -o cluster/out
#$ -e cluster/error
#$ -cwd

export TEMP=/data_n2/vplagnol/Projects/fluidigm/association_v2/temp/Rtemp/

#R CMD BATCH --no-save --no-restore --pheno=${pheno} --code=data/genotypes/${code} scripts/association/test_association.R cluster/R/${code}_${pheno}.out

#R CMD BATCH --no-save --no-restore --pheno=${pheno} --code=data/genotypes/${code} scripts/association/test_association_merge_fluidigm_ichip.R cluster/R/${code}_${pheno}_combined_stepwise.out

R CMD BATCH --no-save --no-restore --pheno=${pheno} --code=data/genotypes/${code} scripts/association/test_association_all_samples.R cluster/R/${code}_${pheno}_all.out

#R CMD BATCH --no-save --no-restore --pheno=${pheno} --code=data/genotypes/${code} scripts/association/test_association_all_samples_uniq.R cluster/R/${code}_${pheno}_uniq.out

" > $script
	
	echo $script    
	qsub -q blades $script
	#qsub -q sunfire $script
	
    done
done
