nextflow.enable.dsl=2


include {fastp} from "./modules/fastp"
include {fastqsplit} from "./modules/splitFastq"
include {samtools; samtools_merge} from "./modules/samtools"
include {star_index; star_align} from "./modules/star"
include {hisat2_index; hisat2_align} from "./modules/hisat2"
include {bowtie2_index; bowtie2_align} from "./modules/bowtie2"
include {cufflinks} from "./modules/cufflinks"

process start_energy_monitoring {
    container 'ubuntu:latest' // Specify a lightweight container
    publishDir '/data' // Ensure signals are written to the shared PVC
    script:
    """
    echo 'start' > /data/start_signal.txt
    """
}

process stop_energy_monitoring {
    input:
    path dummy

    container 'ubuntu:latest' // Specify a lightweight container
    publishDir '/data' // Ensure signals are written to the shared PVC
    script:
    """
    echo 'stop' > /data/stop_signal.txt
    """
}

/*workflow.onComplete {
    //stop_energy_monitoring()  // Stop energy monitoring
    container 'ubuntu:latest' // Specify a lightweight container
    publishDir '/data' // Ensure signals are written to the shared PVC
    script:
    """
    echo 'stop' > /data/stop_signal.txt
    """
}*/

workflow rnaseq_star{

	take:
	input_read

	main:
	if(params.split > 1){
		fastp(input_read, params.strandedness)
		star_index(params.reference, params.gtf, params.strandedness)
		fastqsplit(fastp.out.trimmed) \
		 | map { name, fastq -> tuple( groupKey(name, fastq.size()), fastq ) } \
       	 	 | transpose() \
       	 	 | view()
       		 | set{ splitted_ch }

		star_align(splitted_ch, star_index.out.index, params.gtf, fastp.out.strandedness.first())
		samtools(star_align.out.sam)
		samtools_merge(samtools.out.collect())
		cufflinks(samtools_merge.out, params.gtf, params.strandedness)
	}else{
		fastp(input_read, params.strandedness)
		star_index(params.reference, params.gtf, fastp.out.strandedness)
		star_align(fastp.out.trimmed, star_index.out.index, params.gtf, params.strandedness)
		samtools(star_align.out.sam)
		cufflinks(samtools.out, params.gtf, params.strandedness)
	}
	//stop_energy_monitoring(cufflinks.out)
}


workflow rnaseq_hisat2{

	take:
	input_read

	main:
	if(params.split > 1){
		fastp(input_read, params.strandedness)
		hisat2_index(params.reference, params.strandedness)
		fastqsplit(fastp.out.trimmed) \
	  	 | map { name, fastq -> tuple( groupKey(name, fastq.size()), fastq ) } \
       	 	 | transpose() \
       	 	 | view()
       		 | set{ splitted_ch }

		hisat2_align(splitted_ch, hisat2_index.out.index, fastp.out.strandedness.first())
		samtools(hisat2_align.out.sam)
		samtools_merge(samtools.out.collect())
		cufflinks(samtools_merge.out, params.gtf, params.strandedness)
	}else{
		fastp(input_read, params.strandedness)
		hisat2_index(params.reference, fastp.out.strandedness)
		hisat2_align(fastp.out.trimmed, hisat2_index.out.index, params.strandedness)
		samtools(hisat2_align.out.sam)
		cufflinks(samtools.out, params.gtf, params.strandedness)
	}
	//stop_energy_monitoring(cufflinks.out)
}

workflow rnaseq_bowtie2{

	take:
	input_read

	main:
	if(params.split > 1){
		fastp(input_read, params.strandedness)
		bowtie2_index(params.reference, params.strandedness)
		fastqsplit(fastp.out.trimmed) \
	  	 | map { name, fastq -> tuple( groupKey(name, fastq.size()), fastq ) } \
       	 	 | transpose() \
       	 	 | view()
       		 | set{ splitted_ch }

		bowtie2_align(splitted_ch, bowtie2_index.out.index, params.reference)
		samtools(bowtie2_align.out.sam)
		samtools_merge(samtools.out.collect())
		cufflinks(samtools_merge.out, params.gtf, params.strandedness)
	}else{
		fastp(input_read, params.strandedness)
		bowtie2_index(params.reference, fastp.out.strandedness)
		bowtie2_align(fastp.out.trimmed, bowtie2_index.out.index, params.reference)
		samtools(bowtie2_align.out.sam)
		cufflinks(samtools.out, params.gtf, params.strandedness)
	}
	//stop_energy_monitoring(cufflinks.out)
}

workflow{

    //start_energy_monitoring()  // Start energy monitoring

	if(params.aligner=="star"){
	rnaseq_star(params.read)
	}

	if(params.aligner=="hisat2"){
	rnaseq_hisat2(params.read)
	}

	if(params.aligner=="bowtie2"){
	rnaseq_bowtie2(params.read)
	}

}
