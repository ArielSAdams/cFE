#!/bin/bash

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
  total_files_processed=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Total files processed:\s*\K\d*')
  no_condition_data=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Number of files with no condition data:\s*\K\d+')

  # Extract the condition outcomes covered percentage and the "out of" value (if present)
  condition_outcomes_covered_percent=$(sed -n "/^Summary for ${module} module/:/,/^$/p" "$file" | head -n 4 | grep -Po 'Condition outcomes covered:\s*\K[0-9]+(\.[0-9]+)?')
  condition_outcomes_out_of=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Condition outcomes covered:.*of\s*\K\d*')

  # Return the extracted values, and check if any are missing
  if [ -z "$total_files_processed" ] || [ -z "$no_condition_data" ] || [ -z "$condition_outcomes_covered_percent" ] || [ -z "$condition_outcomes_out_of" ]; then
    return 1 # Indicating missing data for the module
  fi

  echo "$total_files_processed $no_condition_data $condition_outcomes_covered_percent $condition_outcomes_out_of"
}

# Function to get absolute value of a number (supports floating point)
abs() {
  value=$1
  if [[ "$value" =~ ^- ]]; then
    echo $(echo "$value" | sed 's/^-//')
  else
    echo "$value"
  fi
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

  # Initialize variables to store the output for modules with and without changes
  modules_with_changes=""
  modules_without_changes=""

  # Loop through all modules to compare each one
  for module in $modules; do
    # Extract numbers for the main results file and PR results file for the current module
    read main_total_files main_no_condition main_condition_covered_percent main_condition_out_of <<< $(extract_module_numbers "$main_results_file" "$module")
    if [ $? -eq 1 ]; then
      echo "Warning: Missing data in main branch for module '$module'."
      if [ -z "$main_total_files" ]; then
        echo "  - Missing Total files processed in main branch."
      fi
      if [ -z "$main_no_condition" ]; then
        echo "  - Missing Number of files with no condition data in main branch."
      fi
      if [ -z "$main_condition_covered_percent" ]; then
        echo "  - Missing Condition outcomes covered percentage in main branch."
      fi
      if [ -z "$main_condition_out_of" ]; then
        echo "  - Missing Out of value in main branch."
      fi
    fi

    read pr_total_files pr_no_condition pr_condition_covered_percent pr_condition_out_of <<< $(extract_module_numbers "$pr_results_file" "$module")

    if [ $? -eq 1 ]; then
      echo "Warning: Missing data in PR branch for module '$module'."
      if [ -z "$pr_total_files" ]; then
        echo "  - Missing Total files processed in PR branch."
      fi
      if [ -z "$pr_no_condition" ]; then
        echo "  - Missing Number of files with no condition data in PR branch."
      fi
      if [ -z "$pr_condition_covered_percent" ]; then
        echo "  - Missing Condition outcomes covered percentage in PR branch."
      fi
      if [ -z "$pr_condition_out_of" ]; then
        echo "  - Missing Out of value in PR branch."
      fi
    fi

    # If module is missing from either branch, skip comparison for this module
    if [ -z "$main_total_files" ] || [ -z "$pr_total_files" ]; then
      echo "Skipping module '$module' because it is missing from either the main branch or PR branch."
      continue
    fi

    # Initialize variables to store differences
    total_files_diff=""
    no_condition_data_diff=""
    condition_outcomes_covered_diff_percent=""
    condition_outcomes_out_of_diff=""

    # Calculate differences only for existing values
    if [ -n "$main_total_files" ] && [ -n "$pr_total_files" ]; then
      total_files_diff=$((main_total_files - pr_total_files))
    else
      echo "Skipping calculation for Total files processed for module '$module' because data is missing."
    fi
    if [ -n "$main_no_condition" ] && [ -n "$pr_no_condition" ]; then
      no_condition_data_diff=$((main_no_condition - pr_no_condition))
    else
      echo "Skipping calculation for Number of files with no condition data for module '$module' because data is missing."
    fi
    if [ -n "$main_condition_covered_percent" ] && [ -n "$pr_condition_covered_percent" ]; then
      condition_outcomes_covered_diff_percent=$(echo "$main_condition_covered_percent - $pr_condition_covered_percent" | bc)
    else
      echo "Skipping calculation for Condition outcomes covered percentage for module '$module' because data is missing."
    fi
    if [ -n "$main_condition_out_of" ] && [ -n "$pr_condition_out_of" ]; then
      condition_outcomes_out_of_diff=$((main_condition_out_of - pr_condition_out_of))
    else
      echo "Skipping calculation for Out of value for module '$module' because data is missing."
    fi

    # Echo results for each module
    echo -e "\nResults for module: $module"
    echo "Main Branch - Total files processed: $main_total_files, No condition data: $main_no_condition, Covered condition %: $main_condition_covered_percent%, Out of value: $main_condition_out_of"
    echo "PR Branch - Total files processed: $pr_total_files, No condition data: $pr_no_condition, Covered condition %: $pr_condition_covered_percent%, Out of value: $pr_condition_out_of"
    echo "Differences:"

    # Print differences for only the available data
    if [ -n "$total_files_diff" ]; then
      echo "  Total files processed difference: $total_files_diff"
    fi
    if [ -n "$no_condition_data_diff" ]; then
      echo "  No condition data difference: $no_condition_data_diff"
    fi
    if [ -n "$condition_outcomes_covered_diff_percent" ]; then
      echo "  Covered condition % difference: $condition_outcomes_covered_diff_percent%"
    fi
    if [ -n "$condition_outcomes_out_of_diff" ]; then
      echo "  Out of value difference: $condition_outcomes_out_of_diff"
    fi

    # Check for differences and print only the available data
    changes=""

    if [ -n "$total_files_diff" ]; then

      if [ "$total_files_diff" -gt 0 ]; then
        changes="${changes}    Number of processed files removed by PR: $total_files_diff\n"
      elif [ "$total_files_diff" -lt 0 ]; then
        changes="${changes}    Number of processed files added by PR: $(abs $total_files_diff)\n"
      fi

    fi

    if [ -n "$no_condition_data_diff" ]; then

      if [ "$no_condition_data_diff" -gt 0 ]; then
        changes="${changes}    Number of files with no condition data removed by PR: $no_condition_data_diff\n"
      elif [ "$no_condition_data_diff" -lt 0 ]; then
        changes="${changes}    Number of files with no condition data added by PR: $(abs $no_condition_data_diff)\n"
      fi

    fi

    if [ -n "$condition_outcomes_covered_diff_percent" ]; then

      if [ $(echo "$condition_outcomes_covered_diff_percent > 0" | bc) -eq 1 ]; then
        changes="${changes}    Percentage of covered conditions reduced by PR: $condition_outcomes_covered_diff_percent%\n"
      elif [ $(echo "$condition_outcomes_covered_diff_percent < 0" | bc) -eq 1 ]; then
        changes="${changes}    Percentage of covered conditions increased by PR: $(abs $condition_outcomes_covered_diff_percent)%\n"
      fi
    fi

    if [ -n "$condition_outcomes_out_of_diff" ]; then
      if [ "$condition_outcomes_out_of_diff" -gt 0 ]; then
        changes="${changes}    Number of conditions removed by PR: $condition_outcomes_out_of_diff\n"
      elif [ "$condition_outcomes_out_of_diff" -lt 0 ]; then
        changes="${changes}    Number of conditions added by PR: $(abs $condition_outcomes_out_of_diff)\n"
      fi
    fi


    if [ -n "$changes" ]; then

      modules_with_changes="${modules_with_changes}  $module\n$changes\n"
    else
      modules_without_changes="${modules_without_changes}  $module\n"
    fi
  done # End of the for loop

  # Write results to comparison_results.txt
  echo "Comparison of MCDC results between Main Branch and PR:" > comparison_results.txt
  echo "" >> comparison_results.txt
  echo "Modules with changes:" >> comparison_results.txt
  echo -e "$modules_with_changes" >> comparison_results.txt
  echo "Modules without changes:" >> comparison_results.txt
  echo -e "$modules_without_changes" >> comparison_results.txt
}

# Check the script arguments
if [ $# -ne 3 ]; then
  echo "Usage: $0 <main_results_file> <pr_results_file> <modules_file>"
  exit 1
fi

# Run the comparison function with the provided arguments
compare_mcdc_results "$1" "$2" "$3"
