process CHOPPER {
    publishDir "${params.outdir}/filtered_reads-${sample}/", mode: 'copy', overwrite: true
    conda 'bioconda::chopper'
    container 'quay.io/biocontainers/chopper:0.10.0--hcdda2d0_0'

    input:
    tuple val(sample), path(reads)
    val(qscore)
    val(length)

    output:
    tuple val(sample), path("*.fastq"), emit: filtered_fastq

    script:
    """
    chopper --input ${reads} -q ${qscore} --minlength ${length} > ${sample}_filtered.fastq 
    """
}