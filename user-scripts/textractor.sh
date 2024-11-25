#!/usr/bin/env bash

set -euo pipefail

# Check if gum is installed
if command -v gum >/dev/null 2>&1; then
   use_gum=true
else
   use_gum=false
fi

# Check if parallel is installed
if command -v parallel >/dev/null 2>&1; then
   use_parallel=true
else
   use_parallel=false
fi

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
 echo -e "  ${CYAN}-d, --dir DIR${NC}         Directory to include (can be used multiple times)"
 echo -e "  ${CYAN}-I, --ignore-dir DIR${NC}  Directory to ignore (can be used multiple times)"
 echo -e "  ${CYAN}-a, --all${NC}             Include all directories (default)"
 echo -e "  ${CYAN}-t, --tui${NC}             Use TUI mode (interactive)"
 echo -e "  ${CYAN}-h, --help${NC}            Display this help message"
}

# Initialize arrays and variables
extensions=()
ignore_extensions=()
include_dirs=()
ignore_dirs=()
tui=false
include_all=true

# Parse command-line arguments
TEMP=$(getopt -o e:i:d:I:ath --long extension:,ignore:,dir:,ignore-dir:,all,tui,help -n 'myscript' -- "$@")
if [ $? != 0 ]; then
   echo -e "${RED}Error parsing options${NC}"
   print_usage
   exit 1
fi

eval set -- "$TEMP"

while true; do
 case "$1" in
   -e|--extension)
     extensions+=("$2")
     shift 2
     ;;
   -i|--ignore)
     ignore_extensions+=("$2")
     shift 2
     ;;
   -d|--dir)
     include_dirs+=("$(realpath "$2")")
     include_all=false
     shift 2
     ;;
   -I|--ignore-dir)
     ignore_dirs+=("$(realpath "$2")")
     shift 2
     ;;
   -a|--all)
     include_all=true
     shift
     ;;
   -t|--tui)
     tui=true
     shift
     ;;
   -h|--help)
     print_usage
     exit 0
     ;;
   --)
     shift
     break
     ;;
   *)
     echo -e "${RED}Error: Unexpected option $1${NC}"
     print_usage
     exit 1
     ;;
 esac
done

# Check for required positional arguments
if [ $# -ne 2 ]; then
 echo -e "${RED}Error: Missing required arguments${NC}"
 print_usage
 exit 1
fi

source_dir="$(realpath "$1")"
output_file="$2"

# Verify source_dir exists
if [ ! -d "$source_dir" ]; then
 echo -e "${RED}Error: Source directory '$source_dir' does not exist${NC}"
 exit 1
fi

# If TUI mode is enabled
if $tui; then
 if ! $use_gum; then
   echo -e "${RED}Error: gum is not installed but TUI mode is requested.${NC}"
   echo "Please install gum or run the script without --tui option."
   exit 1
 fi

 run_tui() {
   # Select directories to include
   echo "Scanning directories..."
   mapfile -t dir_array < <(find "$source_dir" -type d | sort)

   echo "Select directories to include (press Enter to include all):"
   selected_dirs=$(gum choose --no-limit --cursor.foreground 212 -- "${dir_array[@]}" || true)

   if [ -n "$selected_dirs" ]; then
     include_dirs=($selected_dirs)
     include_all=false
   else
     include_all=true
   fi

   # Select directories to ignore
   echo "Select directories to ignore (optional):"
   ignored_dirs=$(gum choose --no-limit --cursor.foreground 212 -- "${dir_array[@]}" || true)
   if [ -n "$ignored_dirs" ]; then
     ignore_dirs=($ignored_dirs)
   fi

   # Select file extensions to include
   echo "Scanning file extensions..."
   mapfile -t ext_array < <(find "$source_dir" -type f -name "*.*" -exec basename {} \; | sed -n 's/.*\.\([^.]*\)$/\1/p' | sort -u)

   if [ ${#ext_array[@]} -gt 0 ]; then
     echo "Select file extensions to include (press Enter to include all):"
     selected_exts=$(gum choose --no-limit --cursor.foreground 212 -- "${ext_array[@]}" || true)
     if [ -n "$selected_exts" ]; then
       extensions=($selected_exts)
     fi
   fi

   # Select file extensions to ignore
   echo "Select file extensions to ignore (optional):"
   ignored_exts=$(gum choose --no-limit --cursor.foreground 212 -- "${ext_array[@]}" || true)
   if [ -n "$ignored_exts" ]; then
     ignore_extensions=($ignored_exts)
   fi
 }

 run_tui
fi

# Build the find command
find_cmd=(find)

if ! $include_all && [ ${#include_dirs[@]} -gt 0 ]; then
 # Include specified directories
 for dir in "${include_dirs[@]}"; do
   find_cmd+=("$dir")
 done
else
 find_cmd+=("$source_dir")
fi

# Add prune expressions for ignored directories
if [ ${#ignore_dirs[@]} -gt 0 ]; then
 prune_expr=( \( )
 for dir in "${ignore_dirs[@]}"; do
   prune_expr+=(-path "$dir" -o )
 done
 unset 'prune_expr[-1]'  # Remove the last '-o'
 prune_expr+=( \) -prune -o )
 find_cmd+=("${prune_expr[@]}")
fi

# Add -type f to find files
find_cmd+=(-type f)

# Add inclusion of extensions
if [ ${#extensions[@]} -gt 0 ]; then
 ext_expr=( \( )
 for ext in "${extensions[@]}"; do
   ext_expr+=(-name "*.${ext}" -o )
 done
 unset 'ext_expr[-1]'
 ext_expr+=( \) )
 find_cmd+=("${ext_expr[@]}")
fi

# Add exclusion of ignore_extensions
if [ ${#ignore_extensions[@]} -gt 0 ]; then
 ignore_ext_expr=( ! \( )
 for ext in "${ignore_extensions[@]}"; do
   ignore_ext_expr+=(-name "*.${ext}" -o )
 done
 unset 'ignore_ext_expr[-1]'
 ignore_ext_expr+=( \) )
 find_cmd+=("${ignore_ext_expr[@]}")
fi

# Add -print0 to handle file names with spaces
find_cmd+=(-print0)

# Clear the output file if it exists
> "$output_file"

# Print start message
echo -e "${BOLD}${GREEN}Starting file processing...${NC}"
echo -e "${MAGENTA}Source directory:${NC} $source_dir"
echo -e "${MAGENTA}Output file:${NC} $output_file"
echo -e "${MAGENTA}Directories to include:${NC} ${include_dirs[*]:-$source_dir (all)}"
echo -e "${MAGENTA}Directories to ignore:${NC} ${ignore_dirs[*]:-none}"
echo -e "${MAGENTA}Extensions to process:${NC} ${extensions[*]:-all}"
echo -e "${MAGENTA}Extensions to ignore:${NC} ${ignore_extensions[*]:-none}"
echo

# Initialize total_files
total_files=0

# Process files based on available tools
if $use_parallel; then
    echo -e "${GREEN}Using parallel processing for faster extraction...${NC}"
    "${find_cmd[@]}" | parallel -0 --will-cite '
        {
            echo "========================================"
            echo "File: {}"
            echo "========================================"
            echo
            cat "{}"
            echo -e "\n\n"
        } >> '"$output_file"
    total_files=$("${find_cmd[@]}" | tr '\0' '\n' | wc -l)
else
   # Process files sequentially if parallel is not available
   while IFS= read -r -d '' file; do
       total_files=$((total_files + 1))
       if $use_gum; then
           gum spin --spinner dot --title "Processing: $file" -- sleep 0
       else
           echo -e "${CYAN}Processing:${NC} ${YELLOW}$file${NC}"
       fi
       {
           echo "========================================"
           echo "File: $file"
           echo "========================================"
           echo
           cat "$file"
           echo -e "\n\n"
       } >> "$output_file"
   done < <("${find_cmd[@]}")
fi

# Print completion message
echo
echo -e "${BOLD}${GREEN}Processing complete!${NC}"
echo -e "${BLUE}Output saved to:${NC} $output_file"

# Print summary
echo -e "${YELLOW}Total files processed:${NC} $total_files"

# Print a sample of the output file
echo
echo -e "${BOLD}${MAGENTA}Sample of the output file:${NC}"
head -n 10 "$output_file"
echo -e "${CYAN}...${NC}"
