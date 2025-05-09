workflow ALIGNMENT {
    take:
      fasta_ch
      filtered_fastq

    main:
      MINIMAP(fasta_ch, filtered_fastq)
      SAMTOOLS(MINIMAP.out.sam)
      COVERAGE(SAMTOOLS.out.bam)

    emit:
      bam = SAMTOOLS.out.bam
      coverage = COVERAGE.out.coverage
}