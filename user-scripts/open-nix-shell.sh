#!/bin/bash

# Check if a shell name is provided
if [ $# -eq 0 ]; then
  echo "Please provide a shell name (e.g., Python, Rust, JavaScript)"
  exit 1
fi

# Convert the first argument to lowercase
shell_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Define the path to the shells directory
shells_dir="$HOME/NixOS/shells"

# Check if the corresponding .nix file exists
if [ -f "$shells_dir/${shell_name^}.nix" ]; then
  nix-shell "$shells_dir/${shell_name^}.nix" --command fish
else
  echo "Shell configuration for $1 not found in $shells_dir"
  exit 1
fi
