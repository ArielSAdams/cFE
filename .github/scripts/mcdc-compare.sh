#!/bin/bash

exec > >(tee -a mcdc_compare.txt) 2>&1

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

 # NEED TO FIX
 # if first data is missing, grabs second next number as first data 
 
  total_files_processed=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Total files processed:\s*\K\d*')
  no_condition_data=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Number of files with no condition data:\s*\K\d+')
  condition_outcomes_covered_percent=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Condition outcomes covered:\s*\K[0-9]+(\.[0-9]+)?')
  condition_outcomes_out_of=$(sed -n "/^Summary for ${module} module:/,/^$/p" "$file" | head -n 4 | grep -Po 'Condition outcomes covered:.*of\s*\K\d*')


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
    read pr_total_files pr_no_condition pr_condition_covered_percent pr_condition_out_of <<< $(extract_module_numbers "$pr_results_file" "$module")

    # Echo results for each module
    echo -e "\nResults for module: $module"
    echo "Main Branch - Total files processed: $main_total_files, No condition data: $main_no_condition, Covered condition %: $main_condition_covered_percent%, Out of value: $main_condition_out_of"
    echo "PR Branch - Total files processed: $pr_total_files, No condition data: $pr_no_condition, Covered condition %: $pr_condition_covered_percent%, Out of value: $pr_condition_out_of"
   
    # Initialize variables to store differences
    total_files_diff=""
    no_condition_data_diff=""
    condition_outcomes_covered_diff_percent=""
    condition_outcomes_out_of_diff=""

    total_files_diff=$((main_total_files - pr_total_files))
    no_condition_data_diff=$((main_no_condition - pr_no_condition))
    condition_outcomes_covered_diff_percent=$(echo "$main_condition_covered_percent - $pr_condition_covered_percent" | bc)
    condition_outcomes_out_of_diff=$((main_condition_out_of - pr_condition_out_of))

    echo "Differences:"
    echo "  Total files processed difference: $total_files_diff"
    echo "  No condition data difference: $no_condition_data_diff"
    echo "  Covered condition % difference: $condition_outcomes_covered_diff_percent"
    echo "  Out of value difference: $condition_outcomes_out_of_diff"
    echo ""

    # Check for differences and print only the available data
    changes=""

    if [ "$total_files_diff" != "N/A" ]; then
    
      if [ "$total_files_diff" -gt 0 ]; then
        changes="${changes}    Number of processed files removed by PR: $total_files_diff\n"
      elif [ "$total_files_diff" -lt 0 ]; then
        changes="${changes}    Number of processed files added by PR: $(abs $total_files_diff)\n"
      fi

    fi

    if [ "$no_condition_data_diff" != "N/A" ]; then

      if [ "$no_condition_data_diff" -gt 0 ]; then
        changes="${changes}    Number of files with no condition data removed by PR: $no_condition_data_diff\n"
      elif [ "$no_condition_data_diff" -lt 0 ]; then
        changes="${changes}    Number of files with no condition data added by PR: $(abs $no_condition_data_diff)\n"
      fi

    fi

    if [ "$condition_outcomes_covered_diff_percent" != "N/A" ]; then

      if [ $(echo "$condition_outcomes_covered_diff_percent > 0" | bc) -eq 1 ]; then
        changes="${changes}    Percentage of covered conditions reduced by PR: $condition_outcomes_covered_diff_percent%\n"
      elif [ $(echo "$condition_outcomes_covered_diff_percent < 0" | bc) -eq 1 ]; then
        changes="${changes}    Percentage of covered conditions increased by PR: $(abs $condition_outcomes_covered_diff_percent)%\n"
      fi
    fi

    if [ "$condition_outcomes_out_of_diff" != "N/A" ]; then
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

  # Echo results 
  echo "\nComparison of MCDC results between Main Branch and PR:"
  echo ""
  echo "Modules with changes:" 
  echo -e "$modules_with_changes" 
  echo "Modules without changes:" 
  echo -e "$modules_without_changes" 
  
  # Write results to mcdc_comment.txt / pull request if changes exists 
  if [ -n "$modules_with_changes" ]; then
    echo "Comparison of MCDC results between Main Branch and PR:" > mcdc_comment.txt
    echo "" >> mcdc_comment.txt
    echo "Modules with changes:" >> mcdc_comment.txt
    echo -e "$modules_with_changes" >> mcdc_comment.txt
  fi
  
}

# Check the script arguments
if [ $# -ne 3 ]; then
  echo "Usage: $0 <main_results_file> <pr_results_file> <modules_file>"
  exit 1
fi

# Run the comparison function with the provided arguments
compare_mcdc_results "$1" "$2" "$3"
