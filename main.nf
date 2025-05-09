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
//include { ALIGNMENT as ALIGNMENT } from '/workflows/alignment.nf'  did not work so far.
include { QC_SUMMARY as QC_SUMMARY } from './modules/qc_summary.nf'

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
           EVALUATION THRESHOLDS
    Min % Passed    : ${params.pct_filtered}
    Min % Mapped    : ${params.pct_mapped}
    Min coverage    : ${params.coverage}
    Min N50 length  : ${params.filt_n50}
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

    // read mapping and alignment using subworkflow

    def fasta_ch = Channel
             .fromPath(params.fasta)

    MINIMAP(fasta_ch, CHOPPER.out.filtered_fastq)

    // Run samtools on the SAM output to convert, sort and index alignment file
    SAMTOOLS(MINIMAP.out.sam)

    // QC of read mapping
    COVERAGE(SAMTOOLS.out.bam)
    QC_MAPPED(SAMTOOLS.out.bam, mapped_step)

    // QC evaluation and recommendations 
    // Each QC output emits: tuple(sample, path), so extract individual channels by mapping
    def sample_ch   = QC_RAW.out.txt.map { it[0] }  // from any source — sample is the same
    def raw_file    = QC_RAW.out.txt.map { it[1] }
    def filt_file   = QC_FILT.out.txt.map { it[1] }
    def mapped_file = QC_MAPPED.out.txt.map { it[1] }
    def cov_file    = COVERAGE.out.coverage.map { it[1] }

    // define channels for threshold parameters
    def min_filtered = Channel.value(params.pct_filtered)
    def min_mapped = Channel.value(params.pct_mapped)
    def min_cov = Channel.value(params.coverage)
    def min_n50 = Channel.value(params.filt_n50)


    // Final call with 9 channels
    QC_SUMMARY(sample_ch, raw_file, filt_file, mapped_file, cov_file, min_filtered, min_mapped, min_cov, min_n50)

    // Quick inspection of outcome:
    QC_SUMMARY.out.QC_EVAL
    .map { sample, file ->
        def status = file.readLines().last().tokenize('\t').last()
        tuple(sample, status)
    }
    .collect()
    .view()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
