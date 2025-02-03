#!/bin/bash

echo "Script started"

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

  # Extract the values for the specific module summary
  total_files_processed=$(sed -n "/^Summary for ${module} module/,/^$/p" "$file" | grep -Po 'Total files processed:\s*\K\d*' | head -n 1)
  no_condition_data=$(sed -n "/^Summary for ${module} module/,/^$/p" "$file" | grep -Po 'Number of files with no condition data:\s*\K\d+' | head -n 1)

  # Extract the condition outcomes covered percentage and the "out of" value (if present)
  condition_outcomes_covered_percent=$(sed -n "/^Summary for ${module} module/,/^$/p" "$file" | grep -Po 'Condition outcomes covered:\s*\K[0-9]+(\.[0-9]+)?' | head -n 1)
  condition_outcomes_out_of=$(sed -n "/^Summary for ${module} module/,/^$/p" "$file" | grep -Po 'Condition outcomes covered:.*of\s*\K\d*' | head -n 1)

  echo "$total_files_processed $no_condition_data $condition_outcomes_covered_percent $condition_outcomes_out_of"
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

  echo "MC/DC results compared against latest main branch results:" > comparison_results.txt
  echo "" >> comparison_results.txt
  echo "Modules with changes:" >> comparison_results.txt
  echo "" >> comparison_results.txt
  echo "Modules without changes:" >> comparison_results.txt
  echo "" >> comparison_results.txt

  # Arrays to keep track of modules with and without changes
  modules_with_changes=()
  modules_without_changes=()

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
      # Add module to "modules with changes" list
      modules_with_changes+=("$module")
      echo "  Module: $module" >> comparison_results.txt

      # Handle the differences and print appropriate messages for positive and negative values
      if [ "$total_files_diff" -lt 0 ]; then
        echo "    Number of added files: $total_files_diff" >> comparison_results.txt
      elif [ "$total_files_diff" -gt 0 ]; then
        echo "    Number of removed files: ${total_files_diff#-}" >> comparison_results.txt
      fi

      if [ "$no_condition_data_diff" -lt 0 ]; then
        echo "    Number of added files with no condition data: $no_condition_data_diff" >> comparison_results.txt
      elif [ "$no_condition_data_diff" -gt 0 ]; then
        echo "    Number of removed files with no condition data: ${no_condition_data_diff#-}" >> comparison_results.txt
      fi

      if [ "$(echo "$condition_outcomes_covered_diff_percent != 0" | bc)" -eq 1 ]; then
        if [ "$(echo "$condition_outcomes_covered_diff_percent > 0" | bc)" -eq 1 ]; then
          echo "    Percentage decrease in condition coverage: $condition_outcomes_covered_diff_percent%" >> comparison_results.txt
        else
          echo "    Percentage increase in condition coverage: ${condition_outcomes_covered_diff_percent#-}%" >> comparison_results.txt
        fi
      fi

      if [ "$condition_outcomes_out_of_diff" -lt 0 ]; then
        echo "    Number of added conditions 'out of': $condition_outcomes_out_of_diff" >> comparison_results.txt
      elif [ "$condition_outcomes_out_of_diff" -gt 0 ]; then
        echo "    Number of removed conditions 'out of': ${condition_outcomes_out_of_diff#-}" >> comparison_results.txt
      fi

      echo "" >> comparison_results.txt
    else
      # Add module to "modules without changes" list
      modules_without_changes+=("$module")
    fi
  done

  # Add modules without changes to the output
  for module in "${modules_without_changes[@]}"; do
    echo "  Module: $module - No change" >> comparison_results.txt
  done
}

# Check the script arguments
if [ $# -ne 3 ]; then
  echo "Usage: $0 <main_results_file> <pr_results_file> <modules_file>"
  exit 1
fi

# Run the comparison function with the provided arguments
compare_mcdc_results "$1" "$2" "$3"
