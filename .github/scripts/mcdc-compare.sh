#!/bin/bash

echo "Script started"

# Function to extract the relevant numbers from a module's "Summary for module" section
extract_module_numbers() {
  file=$1
  module=$2

  # Extract the values for the specific module summary
  total_files_processed=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Total files processed: \K\d+')
  no_condition_data=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Number of files with no condition data: \K\d+')

  # Extract the condition outcomes covered (before the '%' sign) and ignore extra text like 'of 292'
  condition_outcomes_covered=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered: \K[\d.]+(?=%)')

  # Handle empty values and set to 0 if missing
  total_files_processed=${total_files_processed:-0}
  no_condition_data=${no_condition_data:-0}
  condition_outcomes_covered=${condition_outcomes_covered:-0}

  echo "$total_files_processed $no_condition_data $condition_outcomes_covered"
}

# Compare results for each module between two files
compare_mcdc_results() {
  main_results_file=$1
  pr_results_file=$2
  modules_file=$3

  # Read modules from modules.txt (passed as argument)
  modules=$(cat "$modules_file")

  # Check if modules is empty or not
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
    read main_total_files main_no_condition main_condition_covered <<< $(extract_module_numbers "$main_results_file" "$module")
    # Read PR results
    read pr_total_files pr_no_condition pr_condition_covered <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Debug: Show extracted values
    echo "Main results - Total files processed: $main_total_files, No condition data: $main_no_condition, Condition outcomes covered: $main_condition_covered"
    echo "PR results - Total files processed: $pr_total_files, No condition data: $pr_no_condition, Condition outcomes covered: $pr_condition_covered"

    # Calculate differences for each module
    total_files_diff=$((main_total_files - pr_total_files))
    no_condition_data_diff=$((main_no_condition - pr_no_condition))

    # Calculate difference in condition outcomes
    condition_outcomes_diff=$(echo "$main_condition_covered - $pr_condition_covered" | bc)

    # Convert 0.00% to 0 for easier comparison
    if [ "$(echo "$condition_outcomes_diff == 0.00" | bc)" -eq 1 ]; then
      condition_outcomes_diff=0
    fi

    # Check if there are any differences (if all differences are zero, skip from changes section)
    if [ "$total_files_diff" -eq 0 ] && [ "$no_condition_data_diff" -eq 0 ] && [ "$condition_outcomes_diff" -eq 0 ]; then
      # No differences, output to "Modules without changes"
      echo -e "\tModule: $module - No change" >> comparison_results.txt
    else
      # There are differences, output the changes under "Modules with changes"
      echo -e "\tModule: $module" >> comparison_results.txt
      echo "Calculated differences for $module:" >> comparison_results.txt
      echo "  Total files processed difference: $total_files_diff" >> comparison_results.txt
      echo "  Number of files with no condition data difference: $no_condition_data_diff" >> comparison_results.txt
      echo "  Condition outcomes covered difference: $(printf "%.2f" $condition_outcomes_diff)%" >> comparison_results.txt
      echo "" >> comparison_results.txt
    fi
  done
}

# Main script starts here
echo "Starting comparison for files: $1, $2, modules from $3"

# Ensure the required files exist
if [ ! -f "$1" ]; then
  echo "Error: Main results file $1 not found!"
  exit 1
fi

if [ ! -f "$2" ]; then
  echo "Error: PR results file $2 not found!"
  exit 1
fi

if [ ! -f "$3" ]; then
  echo "Error: Modules file $3 not found!"
  exit 1
fi

# Call the function to compare MCDC results
compare_mcdc_results "$1" "$2" "$3"
