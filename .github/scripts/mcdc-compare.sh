#!/bin/bash

echo "Script started"

# Function to extract the relevant numbers from a module's "Summary for module" section
extract_module_numbers() {
  file=$1
  module=$2

  # Extract the values for the specific module summary
  total_files_processed=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Total files processed: \K\d+')
  no_condition_data=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Number of files with no condition data: \K\d+')

  # Extract the condition outcomes covered percentage and the "out of" value (if present)
  condition_outcomes_covered_percent=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered: \K[\d.]+(?=%)')
  condition_outcomes_out_of=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered: [\d.]+% of \K\d+')

  # Handle cases where condition outcomes covered may be '0% of 0' (or similar edge cases)
  if [ -z "$condition_outcomes_covered_percent" ]; then
    condition_outcomes_covered_percent=0
  fi

  if [ -z "$condition_outcomes_out_of" ]; then
    condition_outcomes_out_of=0
  fi

  # Handle empty values and set to 0 if missing
  total_files_processed=${total_files_processed:-0}
  no_condition_data=${no_condition_data:-0}
  condition_outcomes_covered_percent=${condition_outcomes_covered_percent:-0}
  condition_outcomes_out_of=${condition_outcomes_out_of:-0}

  # Output the results
  echo "$total_files_processed $no_condition_data $condition_outcomes_covered_percent $condition_outcomes_out_of"
}

# Compare results for each module between two files
compare_mcdc_results() {
  main_results_file=$1
  pr_results_file=$2
  modules_file=$3

  # Read modules from modules.txt (passed as argument)
  modules=$(cat "$modules_file")

  # Check if modules are empty or not
  if [ -z "$modules" ]; then
    echo "Error: No modules found in $modules_file"
    exit 1
  fi

  # Debug: Show the modules being processed
  echo "Modules to be processed: $modules"

  echo "Comparison of MCDC results between Main Branch and PR:" > comparison_results.txt
  echo "" >> comparison_results.txt
  echo "Modules with changes:" >> comparison_results.txt
  echo "" >> comparison_results.txt
  echo "Modules without changes:" >> comparison_results.txt
  echo "" >> comparison_results.txt
  
  # Loop through all modules to compare each one
  for module in $modules; do
    # Extract numbers for the main results file and PR results file for the current module
    echo "Processing module: $module"
    echo "Main results: Extracting numbers for module: $module from file: $main_results_file"
    echo "PR results: Extracting numbers for module: $module from file: $pr_results_file"
    
    # Read main results
    read main_total_files main_no_condition main_condition_covered_percent main_condition_out_of <<< $(extract_module_numbers "$main_results_file" "$module")
    # Read PR results
    read pr_total_files pr_no_condition pr_condition_covered_percent pr_condition_out_of <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Debug: Show extracted values
    echo "Main results - Total files processed: $main_total_files, No condition data: $main_no_condition, Condition outcomes covered: $main_condition_covered_percent% of $main_condition_out_of"
    echo "PR results - Total files processed: $pr_total_files, No condition data: $pr_no_condition, Condition outcomes covered: $pr_condition_covered_percent% of $pr_condition_out_of"

    # Calculate differences for each module
    total_files_diff=$((main_total_files - pr_total_files))
    no_condition_data_diff=$((main_no_condition - pr_no_condition))

    # Calculate difference in condition outcomes
    condition_outcomes_covered_diff_percent=$(echo "$main_condition_covered_percent - $pr_condition_covered_percent" | bc)
    condition_outcomes_out_of_diff=$((main_condition_out_of - pr_condition_out_of))

    # Determine if there are differences and print the appropriate output
    if [ "$total_files_diff" -ne 0 ] || [ "$no_condition_data_diff" -ne 0 ] || [ "$(echo "$condition_outcomes_covered_diff_percent != 0" | bc)" -eq 1 ] || [ "$condition_outcomes_out_of_diff" -ne 0 ]; then
      echo "Module: $module" >> comparison_results.txt
      echo "Calculated differences for $module:" >> comparison_results.txt
      echo "  Total files processed difference: $total_files_diff" >> comparison_results.txt
      echo "  Number of files with no condition data difference: $no_condition_data_diff" >> comparison_results.txt
      echo "  Condition outcomes covered difference: $condition_outcomes_covered_diff_percent%" >> comparison_results.txt
      echo "  Number of conditions difference: $condition_outcomes_out_of_diff" >> comparison_results.txt
      echo "" >> comparison_results.txt
    else
      echo "  Module: $module - No change" >> comparison_results.txt
      echo "" >> comparison_results.txt
    fi
  done
}

# Check the script arguments
if [ $# -ne 3 ]; then
  echo "Usage: $0 <main_results_file> <pr_results_file> <modules_file>"
  exit 1
fi

# Run the comparison function with the provided arguments
compare_mcdc_results "$1" "$2" "$3"
