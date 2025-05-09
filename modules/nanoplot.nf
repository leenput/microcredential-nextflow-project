process NANOPLOT_READS {
    publishDir "${params.outdir}/${sample}/quality-control/${step}/", mode: 'copy', overwrite: true
    conda 'bioconda::nanoplot=1.44.1'
    container 'quay.io/biocontainers/nanoplot:1.44.1--pyhdfd78af_0'
    label 'low'

    input:
    tuple val(sample), path(reads)
    val(step)

    output:
    tuple val(sample), path("*.html")
    tuple val(sample), path("*.png")
    tuple val(sample), path("${step}_NanoStats.txt"), emit: txt
    tuple val(sample), path("*.log")

    script:
    """
    NanoPlot --fastq ${reads} -f png -t ${task.cpus}
    mv NanoStats.txt ${step}_NanoStats.txt
    """

}

process NANOPLOT_BAM {
    publishDir "${params.outdir}/${sample}/quality-control/${step}/", mode: 'copy', overwrite: true
    conda 'bioconda::nanoplot=1.44.1'
    container 'quay.io/biocontainers/nanoplot:1.44.1--pyhdfd78af_0'
    label 'low'

    input:
    tuple val(sample), path(bam)
    val(step)

    output:
    tuple val(sample), path("*.html")
    tuple val(sample), path("*.png")
    tuple val(sample), path("${step}_NanoStats.txt"), emit: txt
    tuple val(sample), path("*.log")

    script:
    """
    NanoPlot --bam ${bam} -f png -t ${task.cpus}
    mv NanoStats.txt ${step}_NanoStats.txt
    """

}

