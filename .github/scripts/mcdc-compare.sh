#!/bin/bash

# Navigate to the root of the repository
cd $GITHUB_WORKSPACE

# Function to extract the relevant numbers from the "Overall summary" section
extract_numbers() {
  file=$1

  # Extract the values from the "Overall summary" section ONLY
  total_files_processed=$(sed -n '/^Overall summary:/,/^$/p' "$file" | grep -Po 'Total files processed: \K\d+')
  no_condition_data=$(sed -n '/^Overall summary:/,/^$/p' "$file" | grep -Po 'Number of files with no condition data: \K\d+')
  condition_outcomes_covered=$(sed -n '/^Overall summary:/,/^$/p' "$file" | grep -Po 'Overall condition outcomes covered: \K[\d.]+(?=%)')

  # Return values as a space-separated string
  echo "$total_files_processed $no_condition_data $condition_outcomes_covered"
}


# Compare files and calculate the differences
compare_mcdc_results() {
  main_results_file=$1
  pr_results_file=$2

  # Extract numbers from both files
  read main_total_files main_no_condition main_condition_covered <<< $(extract_numbers "$main_results_file")
  read pr_total_files pr_no_condition pr_condition_covered <<< $(extract_numbers "$pr_results_file")

  # Ensure both condition outcomes are valid numbers
  if [[ -z "$main_condition_covered" || -z "$pr_condition_covered" ]]; then
    echo "Error: Condition outcome data is missing or invalid."
    exit 1
  fi

  # Calculate differences
  total_files_diff=$((main_total_files - pr_total_files))
  no_condition_data_diff=$((main_no_condition - pr_no_condition))
  
  # Ensure that both condition outcome variables are valid numbers before doing the calculation
  condition_outcomes_diff=$(echo "$main_condition_covered - $pr_condition_covered" | bc)

  # Check if the condition outcomes difference calculation worked
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to calculate condition outcomes difference."
    exit 1
  fi

  # Output the differences to a file
  echo "Comparison of MCDC results between Main Branch and PR:" > comparison_results.txt
  echo "Total files processed difference: $total_files_diff" >> comparison_results.txt
  echo "Number of files with no condition data difference: $no_condition_data_diff" >> comparison_results.txt
  echo "Overall condition outcomes covered difference: $(printf "%.2f" $condition_outcomes_diff)%" >> comparison_results.txt
}

# Compare the main branch results and PR results
compare_mcdc_results "$1" "$2"
