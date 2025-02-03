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

  # Initialize arrays for modules with and without changes
  modules_with_changes=()
  modules_without_changes=()

  # Loop through all modules to compare each one
  for module in $modules; do
    # Extract numbers for the main results file and PR results file for the current module
    echo "Processing module: $module"
    
    # Read main results
    read main_total_files main_no_condition main_condition_covered_percent main_condition_out_of <<< $(extract_module_numbers "$main_results_file" "$module")
    
    # Read PR results
    read pr_total_files pr_no_condition pr_condition_covered_percent pr_condition_out_of <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Calculate differences for each module
    total_files_diff=$((main_total_files - pr_total_files))
    no_condition_data_diff=$((main_no_condition - pr_no_condition))

    # Calculate difference in condition outcomes
    condition_outcomes_covered_diff_percent=$(echo "$main_condition_covered_percent - $pr_condition_covered_percent" | bc)
    condition_outcomes_out_of_diff=$((main_condition_out_of - pr_condition_out_of))

    # Initialize the changes string for the current module
    changes=""

    # Handle the differences for the current module
    if [ "$total_files_diff" -ne 0 ]; then
      if [ "$total_files_diff" -lt 0 ]; then
        changes="    Number of added files: $total_files_diff"
      else
        changes="    Number of removed files: ${total_files_diff#-}"
      fi
    fi

    if [ "$no_condition_data_diff" -ne 0 ]; then
      if [ "$no_condition_data_diff" -lt 0 ]; then
        changes="$changes\n    Number of added files with no condition data: $no_condition_data_diff"
      else
        changes="$changes\n    Number of removed files with no condition data: ${no_condition_data_diff#-}"
      fi
    fi

    if [ "$(echo "$condition_outcomes_covered_diff_percent != 0" | bc)" -eq 1 ]; then
      if [ "$(echo "$condition_outcomes_covered_diff_percent > 0" | bc)" -eq 1 ]; then
        changes="$changes\n    Percentage decrease in condition coverage: $condition_outcomes_covered_diff_percent%"
      else
        changes="$changes\n    Percentage increase in condition coverage: ${condition_outcomes_covered_diff_percent#-}%"
      fi
    fi

    if [ "$condition_outcomes_out_of_diff" -ne 0 ]; then
      if [ "$condition_outcomes_out_of_diff" -lt 0 ]; then
        changes="$changes\n    Number of added conditions 'out of': $condition_outcomes_out_of_diff"
      else
        changes="$changes\n    Number of removed conditions 'out of': ${condition_outcomes_out_of_diff#-}"
      fi
    fi

    # If there are changes, add to the modules_with_changes array and print the changes
    if [ -n "$changes" ]; then
      modules_with_changes+=("$module")
      echo -e "  Module: $module" >> comparison_results.txt
      echo -e "$changes" >> comparison_results.txt
    else
      # If no changes, add to the modules_without_changes array
      modules_without_changes+=("$module")
    fi
  done

  # Output final results
  echo "MC/DC results compared against latest main branch results:" > comparison_results.txt
  echo "" >> comparison_results.txt

  # Output Modules with changes
  echo "Modules with changes:" >> comparison_results.txt
  echo "" >> comparison_results.txt
  for module in "${modules_with_changes[@]}"; do
    echo "  Module: $module" >> comparison_results.txt
    echo -e "$changes" >> comparison_results.txt
  done

  # Output Modules without changes
  echo "Modules without changes:" >> comparison_results.txt
  echo "" >> comparison_results.txt
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
