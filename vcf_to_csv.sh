#!/bin/bash

# Script: vcf_to_csv.sh
# Description: Convert VCF files to CSV format with additional computed fields.
# Usage: ./vcf_to_csv.sh -w <working_directory> [-h]

# Display usage
usage="Usage: $0 -w <working_directory> [-h]
Options:
  -w  Working directory containing input files and where output will be stored.
  -h  Display this help message and exit."


while :; do
    case "$1" in
        -h | --help)
            echo "$usage"
            exit 0
            ;;
       
        -w)
            WORKING_DIR=$(realpath "$2")
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "$usage" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done


SECONDS=0

echo "Converting VCF files to CSV output."

BCFTOOLS=$(which bcftools)
if [ -z "$BCFTOOLS" ]; then
    echo "Error: bcftools not found in PATH." >&2
    exit 1
fi

mkdir -p "$WORKING_DIR/vcf_csv_output"

for sample_dir in "$WORKING_DIR"; do
    sample_name=$(basename "$sample_dir")
    input_vcf="${sample_dir}/snv.vcf"
    
    if [ ! -f "$input_vcf" ]; then
        echo "Error: snv.vcf not found in $sample_dir." >&2
        continue
    fi

    filtered_vcf="$WORKING_DIR/${sample_name}_filtered.vcf"
    temp_vcf="$WORKING_DIR/${sample_name}_temp.vcf"
    final_vcf="$WORKING_DIR/${sample_name}_final_snv.vcf"
    final_csv="$WORKING_DIR/vcf_csv_output/${sample_name}_final_snv.csv"

    "$BCFTOOLS" query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%FILTER[\t%FAU\t%FCU\t%FGU\t%FTU\t%RAU\t%RCU\t%RGU\t%RTU][\t%GT\t%GQ\t%DP\t%AF\t%AD\t%AU\t%CU\t%GU\t%TU]\n' "$input_vcf" > "$filtered_vcf"

    awk -F ',' '{split($19, a, " "); $19 = a[1]; $20 = a[2]; print $0;}' "$filtered_vcf" > "$temp_vcf"

    awk 'BEGIN {
        header = "Chromosome\tPosition\tReference_Allele\tAlternate_Allele\tQuality\tFilter\tCount_of_A_in_forward_strand_in_the_tumor_BAM\tCount_of_C_in_forward_strand_in_the_tumor_BAM\tCount_of_G_in_forward_strand_in_the_tumor_BAM\tCount_of_T_in_forward_strand_in_the_tumor_BAM\tCount_of_A_in_reverse_strand_in_the_tumor_BAM\tCount_of_C_in_reverse_strand_in_the_tumor_BAM\tCount_of_G_in_reverse_strand_in_the_tumor_BAM\tCount_of_T_in_reverse_strand_in_the_tumor_BAM\tGenotype\tGenotype_Quality\tReadDepth\tVAF\tAllelic_depth_ref\tAllelic_depth_for_alt\tCount_of_A_in_the_tumor_BAM\tCount_of_C_in_the_tumor_BAM\tCount_of_G_in_the_tumor_BAM\tCount_of_T_in_the_tumor_BAM"
        print header
    } 
    {
        print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15"\t"$16"\t"$17"\t"$18"\t"$19"\t"$20"\t"$21"\t"$22"\t"$23"\t"$24
    }' "$temp_vcf" > "$final_vcf"

    cut -f18 -d$'\t' "$final_vcf" > "$WORKING_DIR/${sample_name}_vaf.txt"

    awk 'BEGIN {print "RAF"} {if ($1 ~ /^[0-9.]+$/) print 1 - $1}' "$WORKING_DIR/${sample_name}_vaf.txt" > "$WORKING_DIR/${sample_name}_ref_allele_frequency.txt"

    paste "$final_vcf" "$WORKING_DIR/${sample_name}_ref_allele_frequency.txt" > "$WORKING_DIR/${sample_name}_annotated_final_snv.vcf"

    awk 'BEGIN {FS="\t"; OFS=","} {print}' "$WORKING_DIR/${sample_name}_annotated_final_snv.vcf" > "$final_csv"

    
    rm "$filtered_vcf" "$temp_vcf" "$WORKING_DIR/${sample_name}_vaf.txt" "$WORKING_DIR/${sample_name}_ref_allele_frequency.txt"
    rm -f "$WORKING_DIR"/*final_snv.vcf
done

echo "Completed converting VCF files to CSV output."

mkdir -p "$WORKING_DIR/snp_plot"

for csv_file in "$WORKING_DIR/vcf_csv_output"/*.csv; do
        base_name=$(basename "$csv_file".csv)
        Rscript ~/loh_plotting/src/snp_plot.R "$csv_file"
done

mv "$WORKING_DIR/vcf_csv_output/*_final_snv" "$WORKING_DIR/snp_plot"
