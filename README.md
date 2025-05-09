# leenaput/microcredential-nextflow-project

## Introduction

**leenaput/microcredential-nextflow-project** 
For the Microcredential Nextflow project, I developed a pipeline to processes nanopore sequencing data from raw FASTQ to alignment, coverage calculation, and QC summary evaluation. 


## Pipeline overview

**Pipeline steps:**
1. **Raw read QC** - Generates stats for raw using [NanoPlot]()
2. **Read filtering** - Quality and length filtering of raw reads using [Chopper]()
2. **Filtered reads QC** - Generates stats for filtered reads using NanoPlot
3. **Read alignment** -Maps reads to reference genome using [minimap2](), sorts and indexes with [SAMtools]()
4. **Alignment QC** – Computes coverage using SAMtools and generates stats of mapped reads using NanoPlot
4. **QC Summary** – Evaluates QC values against user-defined thresholds using custom script 
5. **Final report** – Quickly displays QC pass/fail per sample 


## Usage
# Set parameters 
### Required

| Parameter       | Description                          | Example                                  |
|----------------|--------------------------------------|------------------------------------------|
| `--reads`      | Path to input FASTQ files            | `./data/*.fastq`                         |
| `--fasta`      | Reference genome FASTA file          | `./ref/genome.fa`                        |

### Optional

| Parameter         | Description                             | Default  |
|------------------|-----------------------------------------|----------|
| `--qscore`       | Minimum quality score (CHOPPER)         | `7`      |
| `--minlength`    | Minimum read length (CHOPPER)           | `1000`   |
| `--pct_filtered` | % reads passing filtering (QC summary)  | `80`     |
| `--pct_mapped`   | % reads mapped (QC summary)             | `50`     |
| `--coverage`     | Minimum average coverage                | `10`     |
| `--filt_n50`     | Minimum N50 for filtered reads          | `5000`   |


# Run the pipeline
```bash
nextflow run leenaput/microcredential-nextflow-project \
   -profile <docker/singularity/conda \
```

# Output structure
results/
    ├── pipeline_info/
    ├── <sample>/
           ├── filtered_reads/
           ├── alignment/
           ├── quality-control/
                     ├── raw/
                     ├── filtered/
                     ├── mapped/
                     ├── <sample>_QC_summary.txt
      
