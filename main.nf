#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    leenaput/microcredential-nextflow-project
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/leenaput/microcredential-nextflow-project
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { NANOPLOT_READS as QC_RAW } from './modules/nanoplot.nf'
include { NANOPLOT_READS as QC_FILT } from './modules/nanoplot.nf'
include { NANOPLOT_BAM as QC_MAPPED } from './modules/nanoplot.nf'
include { CHOPPER as CHOPPER } from './modules/chopper.nf'
include { MINIMAP as MINIMAP } from './modules/minimap2.nf'
include { SAMTOOLS as SAMTOOLS } from './modules/samtools.nf'
include { COVERAGE as COVERAGE } from './modules/samtools.nf'

/*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    log.info """\
             LIST OF PARAMETERS
    ===================================
                 GENERAL
    Data-folder     : ${params.datadir}
    Results-folder  : ${params.outdir}
    ===================================
          INPUT AND REFERENCES
    Reference       : ${params.fasta}
    Input reads     : ${params.reads}
    ===================================
           FILTERING THRESHOLDS
    Qscore          : ${params.qscore}
    Read length     : ${params.minlength}
    ===================================
    """

    // Create initial channels
    def reads = Channel
            .fromPath(params.reads)
            .ifEmpty { error "No reads found at: ${params.reads}"}
            .map {file -> tuple(file.baseName, file)}

    def raw_step = Channel   
            .value("raw")

    def filtered_step = Channel   
            .value("filtered")

    def mapped_step = Channel 
            .value("mapped")

    // QC on raw reads
    QC_RAW(reads, raw_step)     

    // filter reads based on Q score
    def quality = Channel
             .value(params.qscore)
    
    def minlen = Channel
             .value(params.minlength)

    CHOPPER(reads, quality, minlen)

    // QC on filtered reads
    QC_FILT(CHOPPER.out.filtered_fastq, filtered_step)


    // read mapping
    def fasta_ch = Channel
             .fromPath(params.fasta)

    MINIMAP(fasta_ch, CHOPPER.out.filtered_fastq)

    // Convert, sort and index alignment file
    
    SAMTOOLS(MINIMAP.out.sam)

    // QC of read mapping
    COVERAGE(SAMTOOLS.out.bam)
    QC_MAPPED(SAMTOOLS.out.bam, mapped_step)

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
