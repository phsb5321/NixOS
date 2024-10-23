#!/usr/bin/env bash
set -e

# Check if exactly one parameter is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {laptop|default}"
    exit 1
fi

# Set the flake name based on the parameter
FLAKE_NAME=$1
if [ "$FLAKE_NAME" != "laptop" ] && [ "$FLAKE_NAME" != "default" ]; then
    echo "Invalid parameter. Use 'laptop' or 'default'."
    exit 1
fi

# Configuration
FLAKE_PATH=~/NixOS/#"$FLAKE_NAME" # Path to the Nix Flake
LOG_FILE=nixos-switch.log         # Log file name for NixOS rebuild output

# Navigate to the directory containing the Flake
cd "$(dirname "$FLAKE_PATH")"

# Update channels
echo "Updating Nix channels..."
sudo nix-channel --update

# Update Flake inputs
echo "Updating Flake inputs..."
nix flake update

# Clean up old generations
echo "Cleaning up old generations..."
sudo nix-collect-garbage -d

# Optimize Nix store
echo "Optimizing Nix store..."
sudo nix-store --optimize

# Clean and format Nix files using "alejandra", suppressing output
echo "Formatting Nix files..."
alejandra . &>/dev/null

# Show diff for all Nix files
git diff -U0 *.nix

# Rebuild NixOS using flakes and log the output
echo "Rebuilding NixOS..."
sudo nixos-rebuild switch --flake "$FLAKE_PATH" &>"$LOG_FILE" || (
    cat "$LOG_FILE" | grep --color error && false
)

# Clean up old boot entries
echo "Cleaning up old boot entries..."
sudo /run/current-system/bin/switch-to-configuration boot

# Get the current generation description
gen=$(nixos-rebuild --flake "$FLAKE_PATH" list-generations | grep current)

# Commit changes with the generation as a message
git add .
git commit -m "$gen"

# Push changes to the remote repository
git push

echo "NixOS update and clean-up completed successfully!"
