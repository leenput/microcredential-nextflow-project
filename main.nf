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
include { CHOPPER as CHOPPER } from './modules/chopper.nf'

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

    // Create channels
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

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
