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
gum style --foreground 212 "🐚 Select your Nix Shell Environment"

# Prompt user to select a shell using gum
if [ -n "${last_shell}" ] && [[ " ${shell_options[*]} " == *" ${last_shell} "* ]]; then
  choice=$(gum choose --selected="${last_shell}" --item.foreground 2 --cursor.foreground 4 "${shell_options[@]}")
else
  choice=$(gum choose --item.foreground 2 --cursor.foreground 4 "${shell_options[@]}")
fi

# Check if the user made a valid choice
if [ -z "${choice}" ]; then
  gum style --foreground 9 "😔 No valid selection made. Exiting."
  exit 1
fi

# Save the chosen shell to the cache
echo "${choice}" >"${CACHE_FILE}"

# Map the choice to the corresponding nix-shell command
selected_shell="${SHELLS_DIR}/${choice}.nix"

# Ensure the file exists (should always exist, but checking for robustness)
if [ -f "${selected_shell}" ]; then
  display_message "Launching ${choice} shell... 🚀"
  loading_animation "🔧 Preparing your development environment"
  exec nix-shell "${selected_shell}" --command zsh
else
  gum style --foreground 9 "😱 The shell file '${selected_shell}' does not exist."
  exit 1
fi
