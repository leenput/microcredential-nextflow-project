# STEP BY STEP PROJECT OVERVIEW 
## OVERVIEW OF PROJECT REQUIREMENTS
**Requirements**
* Should be on Github (Please add the link to projects.md):  ✅
* Docker and Apptainer compatibility (bonus points if also conda compatible) of all modules:  ✅
* Should contain at least 3 modules from tools that weren't covered during the training:  ✅
    * at least 1 module should contain a custom script ✅
    * at least 1 module should contain an external tool  ✅
* Should contain at least 1 config profile  ✅
* Should not need any prior setup (the pipeline should work out-of-the-box on the infrastructure used during the training) with minimal test data:  ✅
* Should output relevant files to an output directory:  ✅
* Should contain at least 3 different operators: *.map, .view, .collect, .last* ✅

**Nice to haves**
* Process resources should be managed in the nextflow.config using process labels ✅
* Follow the nf-core best practice guidelines: tried to best of my knowledge ❗
* The pipeline contains a subworkflow ❌


## DEFINE PROJECT OUTLINE
### Project scope
I will develop a nextflow pipeline for preprocessing human genome sequencing data generated by Oxford Nanopore Technologies. I will implement the following steps and a final bash script that evaluates metrics:
- Step 0: Basecalling (will skip this because this requires gpus and not sure how to configure that)
- Step 1: QC of ONT reads after basecalling using NanoPlot
- Step 2: ONT read filtering based on read quality and length using Chopper
- Step 3: read mapping against the T2T genome using minimap2, followed by sorting and indexing using samtools 
- Step 4: QC of read mapping using NanoPlot and mosdepth
- Step 5: Script to screen QC parameters and give green light or warning if some parameters dont meet the filter criteria to proceed with pipeline. 

### Tools to use
- [Nanoplot](https://github.com/wdecoster/NanoPlot)
- [Chopper](https://github.com/wdecoster/chopper)
- [Minimap2](https://github.com/lh3/minimap2)
- [Samtools](https://www.htslib.org/)
- custom bash script 

### Input data 
- Human reference genome
- Some fastq files as test data

## SETTING UP

**STEP 1: Start local github repository where we will start building the nextflow pipeline**<br>

To already try to adhere to the nf-core best practice guidelines, I installed nf-core on my laptop and used the template to initiate my nextflow project locally, which also initiates git. 
```
nf-core pipelines create
```
I navigate into the project folder ont-preprocessing and inspect it. Many files that seem a bit too complicated for now, but will try to use the framework as much as possible.<br>

**STEP 2: Link pipeline to remote GitHub repository**<br>

On GitHub profile, i made a new github repository [leenaput/nextflow-microcredential](https://github.com/leenput/microcredential-nextflow-project/tree/main)<br>

On my local system, I linked the local git project to this repository:
```
git@github.com:leenput/microcredential-nextflow-project.git
git push --all origin
```

## PREPARE INPUT TEST DATA

Create directory to store input fastq data in:
```
mkdir data
```
Copy chromosome of T2T reference genome (T2T-CHM13v2) fasta file (Chr21) and fastq test data here.<br>
(Ideally reference genome retrieved using the igenome config and getGenomeAttributes subworkflow supplied by nf-core template.)<br>

## CREATE MODULES
first create a modules directory
```
mkdir modules
```

### 1. QC module - nanoplot
Find appropriate **conda enviroments/containers**.<br>
- conda: https://anaconda.org/bioconda/nanoplot=1.44.1
- container: quay.io/biocontainers/nanoplot:1.44.1--pyhdfd78af_0  <br>

**Define inputs**: the tool takes raw/filtered fastq or ubam files (with --fastq flag) or sorted and mapped bam files (with --bam). 
Therefore, we need to define two seperate processes, one for read QC and one for mapping QC. 
In main.nf we need to include the nanoplot.nf module for NANOPLOT_RAW process as QC_RAW, QC_FILT to use it twice, and the NANOPLOT_BAM for read alignment QC<br>   

As module input: tuple of sample name and reads and a step value<br>
-> match this in main.nf by defining appropriate channel that is shaped like a tuple with three elements (sample, reads-filepath, step)
-> we can use the *map operator* for this

**Define outputs**: the tool generates a bunch of different file formats (html, png, txt, log), so we should specify and emit them in the output section.<br>   

### 2. read processing module - chopper
Find appropriate **conda enviroments/containers**.<br>
- conda: https://anaconda.org/bioconda/chopper=0.10.0
- container: quai.io biocontainers: quay.io/biocontainers/chopper:0.10.0--hcdda2d0_0  

**Define inputs**: the tool takes fastq reads as an input (--input), and optional filtering criteria. We will use the quality score (--quality) and length (--minlength) as filters
As module input: tuple of sample name and reads, qscore value and length value
--> match in main.nf by setting up value channels for qscore and length 
--> feed chopper module with reads channel, qscore and length value channels

**Define outputs**: The tool outputs a filtered fastq file, which we will emit, to then use as input for post-processing QC step and for alignment.  <br>

### 3. alignment module - minimap2
Find appropriate **conda enviroments/containers**.<br>
- conda: https://anaconda.org/bioconda/minimap2=2.29
- container: quay.io/biocontainers/minimap2:2.29--h577a1d6_0  

**Define inputs**: Minimap2 requires the filtered fastq reads and fasta reference as input files.<br>
- set up value channel (fromPath) for fasta reference file in main.nf
- module input is tuple of sample and filtered reads, and path to fasta file.  

**Define outputs**: alignment file in SAM format. <br>
- Specify in samtools module output as tuple of sample and SAM file path.
- Connect in main.nf with chopper fastq output. <br>

### 3a. alignment processing module - samtools
Find appropriate **conda enviroments/containers**.<br>
- conda: https://anaconda.org/bioconda/samtools=1.21
- container: quay.io/biocontainers/samtools:1.21--h96c455f_1  

**Define inputs**: we will use different function of samtools convert (samtools view), sort (samtools sort) and index (samtools index) the SAM aligment file. <br>
- module input is tuple of sample and path to SAM file.
- use module script section to pipe the different functions for efficiency.   

**Define output**: two outputs: sorted bam file and index<br>
So module output is tuple of sample and the sorted BAM, which we will emit as 'bam'. Another output is the index (.bai) file, which we will not emit because not explicitely needed to call upon it in remainder of pipeline.  

**Modify main.nf**: Include samtools.nf module and connect emitted minimap2 output as process input.<br>

### 3b. alignment evaluation 
Using samtools depth, calculate per-position coverage. For this, we create a COVERAGE process in the samtools module file, that uses the sorted bam file as an input and generates a coverage.txt file. We also use Nanoplot again to calculate metrics of aligned reads.<br>
--> include COVERAGE process from samtools module and NANOPLOT_BAM process from nanoplot module in main.nf
--> call upon the processes and connect data channels<br>

### 4. final QC evaluation - custom script
This module will contain a bash script that will parse the output files generated by nanoplot and samtools depth to evaluate if the sample is suitable for downstream analyses (FAIL/PASS).<br>
- input: NanoStat.txt files of raw, filtered and mapped reads, .coverage.txt file, parameter thresholds:
    - RAW_FILE=$1
    - FILT_FILE=$2
    - MAPPED_FILE=$3
    - COV_FILE=$4
    - SAMPLE=$5
    - OUTFILE=$6
    - THRESH_FILTERED=$7
    - THRESH_MAPPED=$8
    - THRESH_COV=$9
    - THRESH_N50=${10}

- output: qc_summary.txt file <br>

This script should be stored in bin/ directory in order to be automatically accessable to Nextflow. 

```
mkdir bin
touch bin/qc_evaluation.sh
```

- make a new module for this process/script: qc_summary.nf
- include ubuntu as container image and conda env (recycled from samtools env)
- define all input channels, modify the nanopstat.txt output tuples to just represent the file using map operator
- include thresholds in params.config <br>

Finally, use operators (.map, .last, .collect and .view) to quickly inspect the QC evaluation summary table and print PASS / FAIL in stdout.

## LABEL PROCESSES
Based on pipeline timeline and report, label the processes with (low, medium, high) based on how much resources they use. 

## UPDATE GITHUB
```
git add *
git commit -m "message that specified progress made during the day"
git push
```

## TRY OUT ON VSC WITH SINGULARITY PROFILE
- STEP1: connect to UGent VSC 
- STEP2: configure VSC for nextflow usage  

```
module load Nextflow/24.10.2
export APPTAINER_CACHEDIR=${VSC_SCRATCH}/.apptainer_cache
export APPTAINER_TMPDIR=${VSC_SCRATCH}/.apptainer_tmp
```  

- STEP3: clone github repository in $VSC_DATA

```
git clone git@github.com:leenput/microcredential-nextflow-project.git
cd microcredential-nextflow-project
```

- STEP4: launch pipeline with apptainer profile 

```
nextflow run main.nf -profile apptainer 
``` 

Status: ✔

## TRY OUT LOCALLY WITH DOCKER PROFILE INSTEAD OF CONDA PROFILE
- STEP1: open Docker Desktop to start the Docker engine
- STEP2: launch pipeline with docker profile

```
nextflow run main.nf -profile docker
```
Status: ✔

