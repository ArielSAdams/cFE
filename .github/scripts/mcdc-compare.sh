#!/bin/bash

# Function to extract the relevant numbers from a module's "Summary for module" section
extract_module_numbers() {
  file=$1
  module=$2

  # Extract the values for the specific module summary
  total_files_processed=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Total files processed: \K\d+')
  no_condition_data=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Number of files with no condition data: \K\d+')
  condition_outcomes_covered=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered: \K[\d.]+(?=%)')

  # Return values as a space-separated string
  echo "$total_files_processed $no_condition_data $condition_outcomes_covered"
}

# Compare results for each module between two files
compare_mcdc_results() {
  main_results_file=$1
  pr_results_file=$2

  # Read the MODULES variable from GitHub Actions environment
  modules="$MODULES"

  # Loop through all modules to compare each one
  for module in $modules; do
    # Extract numbers for the main results file and PR results file for the current module
    read main_total_files main_no_condition main_condition_covered <<< $(extract_module_numbers "$main_results_file" "$module")
    read pr_total_files pr_no_condition pr_condition_covered <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Ensure condition outcomes are valid numbers
    if [[ -z "$main_condition_covered" || -z "$pr_condition_covered" ]]; then
      echo "Error: Condition outcome data for $module is missing or invalid."
      continue
    fi

    # Calculate differences for each module
    total_files_diff=$((main_total_files - pr_total_files))
    no_condition_data_diff=$((main_no_condition - pr_no_condition))

    # Calculate difference in condition outcomes
    condition_outcomes_diff=$(echo "$main_condition_covered - $pr_condition_covered" | bc)

    # Output the comparison results for the module
    echo "Comparison of MCDC results for module: $module"
    echo "Total files processed difference: $total_files_diff"
    echo "Number of files with no condition data difference: $no_condition_data_diff"
    echo "Overall condition outcomes covered difference: $(printf "%.2f" $condition_outcomes_diff)%"
    echo " "
  done
}

# Compare the main branch results and PR results for all modules
compare_mcdc_results "$1" "$2"
