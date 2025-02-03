#!/bin/bash

echo "Main Branch Script started"

# Function to check if a file exists and return an error message for missing files
check_file_exists() {
  file=$1
  if [ ! -f "$file" ]; then
    echo "Error: File '$file' does not exist."
    missing_files=true
  fi
}

# Function to extract the relevant numbers from a module's "Summary for module" section
extract_module_numbers() {
  file=$1
  module=$2

  # Extract total files processed (including 0 case)
  total_files_processed=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Total files processed:\s*\K\d*')

  # Extract number of files with no condition data (should be an integer)
  no_condition_data=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Number of files with no condition data:\s*\K\d+')

  # Extract condition outcomes covered percentage (with 0% included)
  condition_outcomes_covered=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered:\s*\K[\d.]+(?=%)')

  # Extract condition outcomes covered "of" value (including 0)
  condition_outcomes_out_of=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered:.*of\s*\K\d*')

  # Return extracted values
  echo "$total_files_processed $no_condition_data $condition_outcomes_covered $condition_outcomes_out_of"

}



# Compare results for each module between two files
compare_mcdc_results() {
  main_results_file=$1
  pr_results_file=$2
  modules_file=$3

  # Initialize a flag to track if any files are missing
  missing_files=false

  # Check if the files exist before proceeding
  check_file_exists "$main_results_file"
  check_file_exists "$pr_results_file"
  check_file_exists "$modules_file"

  # If any files are missing, exit early
  if [ "$missing_files" = true ]; then
    echo "Error: One or more input files are missing. Exiting."
    exit 1
  fi

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
    read main_total_files main_no_condition main_condition_covered main_condition_out_of <<< $(extract_module_numbers "$main_results_file" "$module")
    # Read PR results
    read pr_total_files pr_no_condition pr_condition_covered pr_condition_out_of <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Debug: Show extracted values
    echo "Main results - Total files processed: $main_total_files, No condition data: $main_no_condition, Condition outcomes covered: $main_condition_covered% of $main_condition_out_of"
    echo "PR results - Total files processed: $pr_total_files, No condition data: $pr_no_condition, Condition outcomes covered: $pr_condition_covered% of $pr_condition_out_of"

    # Handle differences (skip calculation for non-numeric values or "N/A")
    if [[ "$main_total_files" =~ ^[0-9]+$ ]] && [[ "$pr_total_files" =~ ^[0-9]+$ ]]; then
      total_files_diff=$((main_total_files - pr_total_files))
    else
      total_files_diff="N/A"
    fi

    if [[ "$main_no_condition" =~ ^[0-9]+$ ]] && [[ "$pr_no_condition" =~ ^[0-9]+$ ]]; then
      no_condition_data_diff=$((main_no_condition - pr_no_condition))
    else
      no_condition_data_diff="N/A"
    fi

    # Calculate difference in condition outcomes if numeric values are available
    if [ "$main_condition_covered" != "N/A" ] && [ "$pr_condition_covered" != "N/A" ]; then
      condition_outcomes_covered_diff_percent=$(echo "$main_condition_covered - $pr_condition_covered" | bc)
    else
      condition_outcomes_covered_diff_percent="N/A"
    fi

    if [[ "$main_condition_out_of" =~ ^[0-9]+$ ]] && [[ "$pr_condition_out_of" =~ ^[0-9]+$ ]]; then
      condition_outcomes_out_of_diff=$((main_condition_out_of - pr_condition_out_of))
    else
      condition_outcomes_out_of_diff="N/A"
    fi

    # Determine if there are differences and print the appropriate output
    if [ "$total_files_diff" != "N/A" ] || [ "$no_condition_data_diff" != "N/A" ] || [ "$condition_outcomes_covered_diff_percent" != "N/A" ] || [ "$condition_outcomes_out_of_diff" != "N/A" ]; then
      echo "Module: $module" >> comparison_results.txt
      echo "Calculated differences for $module:" >> comparison_results.txt
      echo "  Total files processed difference: $total_files_diff" >> comparison_results.txt
      echo "  Number of files with no condition data difference: $no_condition_data_diff" >> comparison_results.txt
      echo "  Condition outcomes covered difference: $condition_outcomes_covered_diff_percent%" >> comparison_results.txt
      echo "  'Out of' value difference: $condition_outcomes_out_of_diff" >> comparison_results.txt
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
