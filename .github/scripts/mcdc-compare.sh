#!/bin/bash

# Function to extract the relevant numbers from a module's "Summary for module" section
extract_module_numbers() {
  file=$1
  module=$2

  # Debug log: Display the module being processed
  echo "Extracting data for module: $module from file: $file"

  # Extract the values for the specific module summary
  total_files_processed=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Total files processed: \K\d+')
  no_condition_data=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Number of files with no condition data: \K\d+')
  condition_outcomes_covered=$(sed -n "/^Summary for ${module}/,/^$/p" "$file" | grep -Po 'Condition outcomes covered: \K[\d.]+(?=%)')

  # Debug log: Show the extracted numbers for verification
  echo "Extracted for module $module:"
  echo "  Total files processed: $total_files_processed"
  echo "  Number of files with no condition data: $no_condition_data"
  echo "  Condition outcomes covered: $condition_outcomes_covered"

  # Return values as a space-separated string
  echo "$total_files_processed $no_condition_data $condition_outcomes_covered"
}

# Compare results for each module between two files
compare_mcdc_results() {
  main_results_file=$1
  pr_results_file=$2

  # Read the MODULES from the modules.txt file generated in the previous job
  if [[ ! -f "modules.txt" ]]; then
    echo "Error: modules.txt file not found. Ensure the file is downloaded correctly from Job 1."
    exit 1
  fi

  # Read modules from modules.txt
  modules=$(cat modules.txt)

  # Check if MODULES variable is empty
  if [[ -z "$modules" ]]; then
    echo "Error: MODULES variable is empty. No modules provided for comparison."
    exit 1
  fi

  # Debug log: Show which modules are being processed
  echo "Processing modules: $modules"

  # Loop through all modules to compare each one
  for module in $modules; do
    # Debug log: Indicate module start
    echo "Comparing results for module: $module"

    # Extract numbers for the main results file and PR results file for the current module
    read main_total_files main_no_condition main_condition_covered <<< $(extract_module_numbers "$main_results_file" "$module")
    read pr_total_files pr_no_condition pr_condition_covered <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Debug log: Show the values for both main and PR results
    echo "Main results for $module:"
    echo "  Total files processed: $main_total_files"
    echo "  Number of files with no condition data: $main_no_condition"
    echo "  Condition outcomes covered: $main_condition_covered"
    
    echo "PR results for $module:"
    echo "  Total files processed: $pr_total_files"
    echo "  Number of files with no condition data: $pr_no_condition"
    echo "  Condition outcomes covered: $pr_condition_covered"

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

    # Debug log: Show the calculated differences
    echo "Calculated differences for $module:"
    echo "  Total files processed difference: $total_files_diff"
    echo "  Number of files with no condition data difference: $no_condition_data_diff"
    echo "  Condition outcomes covered difference: $(printf "%.2f" $condition_outcomes_diff)%"
    echo " "
  done
}

# Debug log: Indicate the start of the comparison
echo "Starting comparison of MCDC results..."

# Compare the main branch results and PR results for all modules
compare_mcdc_results "$1" "$2"

# Debug log: Indicate the end of the comparison
echo "Comparison complete."
