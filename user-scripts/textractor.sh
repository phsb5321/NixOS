#!/usr/bin/env bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_usage() {
  echo -e "${BOLD}Usage:${NC} $0 [OPTIONS] <source_directory> <output_file>"
  echo -e "${BOLD}Options:${NC}"
  echo -e "  ${CYAN}-e, --extension EXT${NC}   File extension to process (can be used multiple times)"
  echo -e "  ${CYAN}-i, --ignore EXT${NC}      File extension to ignore (can be used multiple times)"
  echo -e "  ${CYAN}-h, --help${NC}            Display this help message"
}

# Initialize arrays for extensions and ignored extensions
extensions=()
ignore_extensions=()

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -e | --extension)
    extensions+=("$2")
    shift 2
    ;;
  -i | --ignore)
    ignore_extensions+=("$2")
    shift 2
    ;;
  -h | --help)
    print_usage
    exit 0
    ;;
  *)
    if [[ -z $source_dir ]]; then
      source_dir="$1"
    elif [[ -z $output_file ]]; then
      output_file="$1"
    else
      echo -e "${RED}Error: Unexpected argument '$1'${NC}"
      print_usage
      exit 1
    fi
    shift
    ;;
  esac
done

# Check if required arguments are provided
if [[ -z $source_dir || -z $output_file ]]; then
  echo -e "${RED}Error: Missing required arguments${NC}"
  print_usage
  exit 1
fi

# Function to check if a file should be ignored
should_ignore() {
  local file="$1"
  for ext in "${ignore_extensions[@]}"; do
    if [[ $file == *.$ext ]]; then
      return 0
    fi
  done
  return 1
}

# Process files
process_files() {
  local dir="$1"
  for file in "$dir"/*; do
    if [[ -d $file ]]; then
      process_files "$file"
    elif [[ -f $file ]]; then
      local ext="${file##*.}"
      if ((${#extensions[@]} == 0)) || [[ " ${extensions[*]} " == *" $ext "* ]]; then
        if ! should_ignore "$file"; then
          echo -e "${CYAN}Processing:${NC} ${YELLOW}$file${NC}"
          {
            echo "========================================"
            echo "File: $file"
            echo "========================================"
            echo
            cat "$file"
            echo -e "\n\n"
          } >>"$output_file"
        fi
      fi
    fi
  done
}

# Clear the output file if it exists
>"$output_file"

# Print start message
echo -e "${BOLD}${GREEN}Starting file processing...${NC}"
echo -e "${MAGENTA}Source directory:${NC} $source_dir"
echo -e "${MAGENTA}Output file:${NC} $output_file"
echo -e "${MAGENTA}Extensions to process:${NC} ${extensions[*]:-all}"
echo -e "${MAGENTA}Extensions to ignore:${NC} ${ignore_extensions[*]:-none}"
echo

# Process files
process_files "$source_dir"

# Print completion message
echo
echo -e "${BOLD}${GREEN}Processing complete!${NC}"
echo -e "${BLUE}Output saved to:${NC} $output_file"

# Print summary
total_files=$(grep -c "^File:" "$output_file")
echo -e "${YELLOW}Total files processed:${NC} $total_files"

# Print a sample of the output file
echo
echo -e "${BOLD}${MAGENTA}Sample of the output file:${NC}"
head -n 10 "$output_file"
echo -e "${CYAN}...${NC}"
