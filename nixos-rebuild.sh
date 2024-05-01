#!/usr/bin/env bash
set -e

# Configuration
FLAKE_PATH=~/NixOS/#default   # Path to the Nix Flake
LOG_FILE=nixos-switch.log     # Log file name for NixOS rebuild output

# Navigate to the directory containing the Flake
cd "$(dirname "$FLAKE_PATH")"

# Clean and format Nix files using "nixpkgs-fmt", suppressing output
nixpkgs-fmt . &>/dev/null

# Show diff for all Nix files
git diff -U0 *.nix

# Rebuild NixOS using flakes and log the output
echo "NixOS Rebuilding..."
sudo nixos-rebuild switch --flake "$FLAKE_PATH" &>"$LOG_FILE" || (
  cat "$LOG_FILE" | grep --color error && false
)

# Get the current generation description
gen=$(nixos-rebuild --flake "$FLAKE_PATH" list-generations | grep current)

# Commit changes with the generation as a message
git commit -am "$gen"
