process MINIMAP {
    publishDir "${params.outdir}/${sample}/alignment/", mode: 'copy', overwrite: true
    conda 'bioconda::minimap2=2.29'
    container 'quay.io/biocontainers/minimap2:2.29--h577a1d6_0'
    label 'high'

    input:
    path fasta
    tuple val(sample), path(reads)

    output:
    tuple val(sample), path("${sample}.sam"), emit: sam 

    script:
    """
    minimap2 -ax map-ont ${fasta} ${reads} > ${sample}.sam
    """
}