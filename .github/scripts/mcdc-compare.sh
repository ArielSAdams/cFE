#!/bin/bash

# Define full paths to the results files
MAIN_RESULTS_FILE="./main-branch-results/mcdc_results.txt"
PR_RESULTS_FILE="./mcdc_results.txt"

# Check if the files exist
if [[ ! -f "$MAIN_RESULTS_FILE" ]]; then
  echo "Error: $MAIN_RESULTS_FILE not found"
  exit 1
fi

if [[ ! -f "$PR_RESULTS_FILE" ]]; then
  echo "Error: $PR_RESULTS_FILE not found"
  exit 1
fi

# Extract numbers from both files
extract_numbers() {
  file=$1
  total_files_processed=$(grep -Po 'Total files processed: \K\d+' "$file")
  no_condition_data=$(grep -Po 'Number of files with no condition data: \K\d+' "$file")
  condition_outcomes_covered=$(grep -Po 'Overall condition outcomes covered: \K[\d.]+(?=%)' "$file")
  echo "$total_files_processed $no_condition_data $condition_outcomes_covered"
}

# Extract numbers from the main and PR result files
read main_total_files main_no_condition main_condition_covered <<< $(extract_numbers "$MAIN_RESULTS_FILE")
read pr_total_files pr_no_condition pr_condition_covered <<< $(extract_numbers "$PR_RESULTS_FILE")

# Calculate differences
total_files_diff=$((main_total_files - pr_total_files))
no_condition_data_diff=$((main_no_condition - pr_no_condition))
condition_outcomes_diff=$(echo "$main_condition_covered - $pr_condition_covered" | bc)

# Output the differences to a file
echo "Comparison of MCDC results between Main Branch and PR:" > comparison_results.txt
echo "Total files processed difference: $total_files_diff" >> comparison_results.txt
echo "Number of files with no condition data difference: $no_condition_data_diff" >> comparison_results.txt
echo "Overall condition outcomes covered difference: $(printf "%.2f" $condition_outcomes_diff)%" >> comparison_results.txt
