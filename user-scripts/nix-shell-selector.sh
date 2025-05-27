#!/usr/bin/env bash

set -euo pipefail

# Configuration
CACHE_FILE="${HOME}/.nix-shell-cache"
SHELLS_DIR="${HOME}/NixOS/shells"

# Function to display styled messages
display_message() {
  local message="$1"
  gum style --foreground 212 "🚀 ${message}"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Animated loading function
loading_animation() {
  local message="$1"
  gum spin --spinner dot --title "${message}" -- sleep 0.5
}

# Ensure required commands are available
for cmd in gum find nix-shell zsh; do
  if ! command_exists "${cmd}"; then
    gum style --foreground 9 "⚠️  ${cmd} is required but not installed. Please install it first."
    exit 1
  fi
done

# Find all *.nix files in the SHELLS_DIR
loading_animation "🔍 Searching for Nix shells"
mapfile -t shell_files < <(find "${SHELLS_DIR}" -type f -name "*.nix" | sort)

# If no shells found, exit
if [ ${#shell_files[@]} -eq 0 ]; then
  gum style --foreground 9 "😕 No Nix shells found in ${SHELLS_DIR}"
  exit 1
fi

# Create a list of shell names without the directory path and file extension
shell_options=()
for shell_file in "${shell_files[@]}"; do
  shell_name=$(basename "${shell_file}" .nix)
  shell_options+=("${shell_name}")
done

# Check if a last-used shell is stored in the cache
last_shell=""
if [ -f "${CACHE_FILE}" ]; then
  last_shell=$(<"${CACHE_FILE}")
fi

# Display a header using gum
gum style --foreground 212 "🐚 Select your Nix Shell Environment(s) - Use Space to select, Enter to confirm"

# Prompt user to select shells using gum with multi-select
if [ -n "${last_shell}" ] && [[ " ${shell_options[*]} " == *" ${last_shell} "* ]]; then
  choices=$(gum choose --no-limit --selected="${last_shell}" --item.foreground 2 --cursor.foreground 4 "${shell_options[@]}")
else
  choices=$(gum choose --no-limit --item.foreground 2 --cursor.foreground 4 "${shell_options[@]}")
fi

# Check if the user made any valid choices
if [ -z "${choices}" ]; then
  gum style --foreground 9 "😔 No valid selection made. Exiting."
  exit 1
fi

# Convert choices to array
mapfile -t selected_shells <<<"${choices}"

# Save the first chosen shell to the cache for future default selection
echo "${selected_shells[0]}" >"${CACHE_FILE}"

# Build the combined shell paths and display selected shells
shell_paths=()
display_message "Selected shells:"
for shell_name in "${selected_shells[@]}"; do
  shell_path="${SHELLS_DIR}/${shell_name}.nix"
  if [ -f "${shell_path}" ]; then
    shell_paths+=("${shell_path}")
    gum style --foreground 2 "  ✓ ${shell_name}"
  else
    gum style --foreground 9 "😱 The shell file '${shell_path}' does not exist."
    exit 1
  fi
done

# Launch the combined shell environment
if [ ${#shell_paths[@]} -eq 1 ]; then
  # Single shell - use direct exec
  display_message "Launching ${selected_shells[0]} shell... 🚀"
  loading_animation "🔧 Preparing your development environment"
  exec nix-shell "${shell_paths[0]}" --command zsh
else
  # Multiple shells - create a temporary combined shell
  display_message "Launching combined shell environment... 🚀"
  loading_animation "🔧 Preparing your combined development environment"

  # Create temporary combined shell file
  temp_shell=$(mktemp --suffix=.nix)
  trap "rm -f ${temp_shell}" EXIT

  # Generate the combined shell content
  cat >"${temp_shell}" <<EOF
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  # Import all selected shells and combine their inputs
  inputsFrom = [
EOF

  # Add each shell as an input
  for shell_path in "${shell_paths[@]}"; do
    echo "    (import ${shell_path} { inherit pkgs; })" >>"${temp_shell}"
  done

  cat >>"${temp_shell}" <<EOF
  ];

  # Combined shell hook that shows which environments are active
  shellHook = ''
    echo "🚀 Combined Nix Shell Environment Active!"
    echo "📦 Loaded environments: ${selected_shells[*]}"
    echo "🎯 All tools from selected shells are now available"
    echo ""
  '';
}
EOF

  # Launch the temporary combined shell
  exec nix-shell "${temp_shell}" --command zsh
fi
