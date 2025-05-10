# leenaput/microcredential-nextflow-project

## Introduction

**leenaput/microcredential-nextflow-project**\n
For the Microcredential Nextflow project, I developed a pipeline to processes nanopore sequencing data from raw FASTQ to alignment, coverage calculation, and QC summary evaluation. A step-by-step outline of how the project was developed can be found [here](https://github.com/leenput/microcredential-nextflow-project/blob/main/STEPBYSTEP.md).\n


## Pipeline overview

**Pipeline steps:**
1. **Raw read QC** - Generates stats for raw using [NanoPlot]()
2. **Read filtering** - Quality and length filtering of raw reads using [Chopper]()
2. **Filtered reads QC** - Generates stats for filtered reads using NanoPlot
3. **Read alignment** -Maps reads to reference genome using [minimap2](), sorts and indexes with [SAMtools]()
4. **Alignment QC** – Computes coverage using SAMtools and generates stats of mapped reads using NanoPlot
4. **QC Summary** – Evaluates QC values against user-defined thresholds using custom script 
5. **Final report** – Quickly displays QC pass/fail per sample 


# Usage
## Installation
Clone the repository:
```
git clone git@github.com:leenput/microcredential-nextflow-project.git
```

Note: Nextflow should be installed on your system.\n
If working on VSC, make sure to carry out the following configurations before running the pipeline:
```
module load Nextflow/24.10.2
export APPTAINER_CACHEDIR=${VSC_SCRATCH}/.apptainer_cache
export APPTAINER_TMPDIR=${VSC_SCRATCH}/.apptainer_tmp
``` 

## Set parameters
The parameters are included in params.config. Please modify according to your experimental needs. 

### General parameters

| Parameter      | Description                          | Example                                  |
|----------------|--------------------------------------|------------------------------------------|
| `--reads`      | Path to input FASTQ files            | `./data/*.fastq`                         |
| `--fasta`      | Reference genome FASTA file          | `./data/genome.fasta`                    |\n


Please make sure to store your genome sequence file (*.fasta*) and basecalled ONT reads (*.fastq*) in the /data workfolder.\n

For now, you can find the following **test data** there:\n
- reference sequence: chr21 of the new human reference genome T2T-CHM13v2 
- ONT data: subsampled reads of GIAB sample HG002 


### Optional parameters

| Parameter         | Description                             | Default  |
|------------------|-----------------------------------------|----------|
| `--qscore`       | Minimum quality score (CHOPPER)         | `7`      |
| `--minlength`    | Minimum read length (CHOPPER)           | `1000`   |
| `--pct_filtered` | % reads passing filtering (QC summary)  | `80`     |
| `--pct_mapped`   | % reads mapped (QC summary)             | `50`     |
| `--coverage`     | Minimum average coverage                | `10`     |
| `--filt_n50`     | Minimum N50 for filtered reads          | `5000`   |


## Run the pipeline

Run the workflow with the following command:

```
nextflow run main.nf -profile <docker/singularity/conda> \
```

## Output structure
```
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
                     
```    
