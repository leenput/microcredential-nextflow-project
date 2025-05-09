#!/usr/bin/env bash

# Define input arguments
RAW_FILE=$1
FILT_FILE=$2
MAPPED_FILE=$3
COV_FILE=$4
SAMPLE=$5
OUTFILE=$6
THRESH_FILTERED=$7
THRESH_MAPPED=$8
THRESH_COV=$9
THRESH_N50=${10}

# Function to extract values from NanoStats.txt
extract_value() {
    grep "$2" "$1" | grep -oE '[0-9.,]+' | head -n1 | tr -d ',' 
}

# Extract values from key parameters from NanoStats.txt: read counts, mean read quality, read length N50 and percent identity
RAW_READS=$(extract_value "$RAW_FILE" "Number of reads")
RAW_N50=$(extract_value "$RAW_FILE" "Read length N50")
FILT_READS=$(extract_value "$FILT_FILE" "Number of reads")
FILT_N50=$(extract_value "$FILT_FILE" "Read length N50")
MAPPED_READS=$(extract_value "$MAPPED_FILE" "Number of reads")
MAPPED_N50=$(extract_value "$MAPPED_FILE" "Read length N50")
MAPPED_API=$(extract_value "$MAPPED_FILE" "Average percent identity")

# Calculate % reads that passed filtering criteria (avoid division by zero)
if [[ "$RAW_READS" -eq 0 ]]; then
    PCT_PASSED=0
else
    PCT_PASSED=$(awk "BEGIN { printf \"%.1f\", ($FILT_READS / $RAW_READS) * 100 }")
fi

# Calculate % mapped (avoid division by zero)
if [[ "$FILT_READS" -eq 0 ]]; then
    PCT_MAPPED=0
else
    PCT_MAPPED=$(awk "BEGIN { printf \"%.1f\", ($MAPPED_READS / $FILT_READS) * 100 }")
fi

# Calculate average coverage
AVG_COV=$(awk '{sum+=$3} END {if (NR>0) printf "%.2f", sum/NR; else print "0"}' "$COV_FILE")

# Apply thresholds
RECOMMENDATION="PASS"
if (( $(echo "$PCT_PASSED < $THRESH_FILTERED" | bc -l) )) || \
   (( $(echo "$PCT_MAPPED < $THRESH_MAPPED" | bc -l) )) || \
   (( $(echo "$AVG_COV < $THRESH_COV" | bc -l) )) || \
   [[ "$FILT_N50" -lt $THRESH_N50 ]]; then
    RECOMMENDATION="FAIL"
fi

# Output results in summarizing table 
echo -e "sample\traw_reads\tfiltered_reads\t%_passed\tN50_passed\tmapped_reads\t%_mapped\tAPI\tavg_coverage\trecommendation" > "$OUTFILE"
echo -e "$SAMPLE\t$RAW_READS\t$FILT_READS\t$PCT_PASSED\t$FILT_N50\t$MAPPED_READS\t$PCT_MAPPED\t$MAPPED_API\t$AVG_COV\t$RECOMMENDATION" >> "$OUTFILE"