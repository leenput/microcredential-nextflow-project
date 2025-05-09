process SAMTOOLS {
    publishDir "${params.outdir}/${sample}/alignment/", mode: 'copy', overwrite: true
    conda 'bioconda::samtools=1.21'
    container 'quay.io/biocontainers/samtools:1.21--h96c455f_1'
    label 'medium'

    input:
    tuple val(sample), path(sam)

    output:
    tuple val(sample), path("${sample}.sorted.bam"), emit: bam
    path("${sample}.sorted.bam.bai")

    script:
    """
    samtools view -Sb ${sam} > ${sample}.bam 
    samtools sort  ${sample}.bam -o ${sample}.sorted.bam
    samtools index ${sample}.sorted.bam 
    """
}


process COVERAGE {
    publishDir "${params.outdir}/${sample}/alignment/", mode: 'copy', overwrite: true
    conda 'bioconda::samtools=1.21'
    container 'quay.io/biocontainers/samtools:1.21--h96c455f_1'
    label 'medium'

    input:
    tuple val(sample), path(bam)

    output:
    tuple val(sample), path("${sample}.coverage.txt"), emit: coverage

    script:
    """
    samtools depth -a ${bam} > ${sample}.coverage.txt
    """  
}