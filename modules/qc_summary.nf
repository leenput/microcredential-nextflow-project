process QC_SUMMARY {
    publishDir "${params.outdir}/${sample}/quality-control/", mode: 'copy', overwrite: true
    conda 'bioconda::samtools=1.21'
    container 'ubuntu:22.04'
    label 'low'

    input:
    val(sample)
    path(raw)
    path(filt)
    path(mapped)
    path(coverage)
    val(min_pct_filtered)
    val(min_pct_mapped)
    val(min_coverage)
    val(min_filt_n50)

    output:
    tuple val(sample), path("${sample}_QC_summary.txt"), emit: QC_EVAL

    script:
    """
     bash qc_evaluation.sh $raw $filt $mapped $coverage $sample ${sample}_QC_summary.txt $min_pct_filtered $min_pct_mapped $min_coverage $min_filt_n50
    """
}