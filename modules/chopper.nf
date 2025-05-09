process CHOPPER {
    publishDir "${params.outdir}/${sample}/filtered_reads/", mode: 'copy', overwrite: true
    conda 'bioconda::chopper=0.10.0'
    container 'quay.io/biocontainers/chopper:0.10.0--hcdda2d0_0'
    label 'high'

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