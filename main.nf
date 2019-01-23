#!/usr/bin/env nextflow

/*
========================================================================================
                                k W I P - n f
========================================================================================
 Nextflow pipeline to estimate sample dis(similarity) using kWIP
 #### Homepage / Documentation
 https://github.com/Gregor-Mendel-Institute/kWIP-nf
 #### Author
 Patrick Hüther <patrick.huether@gmi.oeaw.ac.at>
----------------------------------------------------------------------------------------
*/

// Pipeline version
version = "0.1"

params.outdir = "./results"
params.reads = false
params.pairedEnd = false

params.clip_r1 = 0
params.clip_r2 = 0
params.three_prime_clip_r1 = 0
params.three_prime_clip_r2 = 0
params.k_size = 20
params.tablesize = 1e9

log.info "=================================================="
log.info " kWIP-nf ${version}"
log.info "=================================================="
log.info "Current home          : $HOME"
log.info "Current user          : $USER"
log.info "Current path          : $PWD"
log.info "Script dir            : $baseDir"
log.info "Working dir           : $workDir"
log.info "Output dir            : ${params.outdir}"
log.info "---------------------------------------------------"
log.info "Paired End            : ${params.pairedEnd}"
log.info "Trim R1               : ${params.clip_r1}"
log.info "Trim R2               : ${params.clip_r2}"
log.info "Trim 3' R1            : ${params.three_prime_clip_r1}"
log.info "Trim 3' R2            : ${params.three_prime_clip_r2}"
log.info "K-mer size            : ${params.k_size}"
log.info "Max tablesize         : ${params.tablesize}"
log.info "=================================================="

// Channel reads

Channel
	.fromFilePairs( params.reads, size: params.pairedEnd ? 2 : 1 )
	.ifEmpty { exit 1, "no read files found" }
	.set { ch_reads }

// TODO: check input parameters

process trimGalore {
	tag "$name"
	publishDir "${params.outdir}/trimGalore", mode: 'copy'

	input:
	set val(name), file(reads) from ch_reads

	output:
	set val(name), file('*fq.gz') into ch_trimmed_reads

	script:
	c_r1 = params.clip_r1 > 0 ? "--clip_r1 ${params.clip_r1}" : ''
	c_r2 = params.clip_r2 > 0 ? "--clip_r2 ${params.clip_r2}" : ''
	tpc_r1 = params.three_prime_clip_r1 > 0 ? "--three_prime_clip_r1 ${params.three_prime_clip_r1}" : ''
	tpc_r2 = params.three_prime_clip_r2 > 0 ? "--three_prime_clip_r2 ${params.three_prime_clip_r2}" : ''
	if( !params.pairedEnd ) {
		"""
		trim_galore --fastqc --gzip $c_r1 $tpc_r1 $reads
		"""
	} else {
		"""
		trim_galore --paired --fastqc --gzip $c_r1 $c_r2 $tpc_r1 $tpc_r2 $reads
		"""
	}
}


if( !params.pairedEnd ){
	ch_trimmed_reads.set {ch_fq_for_khmerHashing}
} else {
	process khmerInterleaving {
		tag "$name"
		publishDir "${params.outdir}/interleavedReads", mode: 'copy'

		input:
		set val(name), file(reads) from ch_trimmed_reads

		output:
		set val(name), file('interleaved/*fq.gz') into ch_fq_for_khmerHashing 

//		when:
//		params.pairedEnd

		script:
		"""
		mkdir interleaved
		interleave-reads.py ${reads} --gzip -o interleaved/${name}.fq.gz
		"""
	}
}

process khmerHashing {
	tag "$name"
	publishDir "${params.outdir}/khmerHashes", mode: 'copy'

	input:
	set val(name), file(reads) from ch_fq_for_khmerHashing

	output:
	set val(name), file('hashes/*ct.gz') into ch_hashes_for_kWIP 

	script:
	"""
	mkdir hashes

	load-into-counting.py	\\
		-N 1	\\
		-x ${params.tablesize} \\
		-T ${task.cpus}	\\
		-k ${params.k_size}	\\
		-b	\\
		-f	\\
		-s tsv	\\
		hashes/${name}.ct.gz	\\
		${reads}	
	"""
}

process kWIP {
	publishDir "${params.outdir}/kWIP", mode: 'copy'

	input:
	file(hash) from ch_hashes_for_kWIP.collect()

	output:
	file('result.*') into result 

	script:
	"""
	kwip \\
		-t 4	\\
		-k result.kern	\\
		-d result.dist	\\
		*.ct.gz

	img.R result
	"""	
}

