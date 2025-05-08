process NANOPLOT_READS {
    publishDir "${params.outdir}/quality-control-${sample}/${step}/", mode: 'copy', overwrite: true
    conda 'bioconda::nanoplot'
    container 'quay.io/biocontainers/nanoplot:1.44.1--pyhdfd78af_0'

    input:
    tuple val(sample), path(reads)
    val(step)

    output:
    path("*.html"), emit: html
    path("*.png"), optional: true, emit: png
    path("*.txt"), emit: txt
    path("*.log"), emit: log

    script:
    """
    NanoPlot --fastq ${reads} -f png
    """

}

process NANOPLOT_BAM {
    publishDir "${params.outdir}/quality-control-${sample}/${step}/", mode: 'copy', overwrite: true
    conda 'bioconda::nanoplot'
    container 'quay.io/biocontainers/nanoplot:1.44.1--pyhdfd78af_0'

    input:
    tuple val(sample), path(bam)
    val(step)

    output:
    path("*.html"), emit: html
    path("*.png"), optional: true, emit: png
    path("*.txt"), emit: txt
    path("*.log"), emit: log

    script:
    """
    NanoPlot --bam ${bam} -f png -t ${task.cpus}
    """

}

