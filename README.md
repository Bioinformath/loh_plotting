# VCF to CSV Conversion and LOH Plotting

This repository contains scripts for converting Variant Calling Format (VCF) file to CSV format and visualizing Loss of Heterozygosity (LOH) through plots.

## Overview

1. **Convert VCF to CSV Format**: A script that processes VCF data and converts it into a structured CSV file. This allows easy analysis and visualization of VCF data. It counts RAF from VAF. And shows mirror image of the VAF and RAF.

2. **LOH Plotting**: A script to generate visualizations of Loss of Heterozygosity (LOH) based on VAF data, providing insights into genetic variations.

## Prerequisites  

awk  
bcfools  
R

## Usage

```bash 
./vcf_to_csv.sh -w <working_directory>
```
