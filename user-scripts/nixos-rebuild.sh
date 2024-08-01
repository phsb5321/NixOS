#!/usr/bin/env bash
set -euo pipefail

# Function to print usage
print_usage() {
    echo "Usage: $0 {laptop|default}"
    echo "  laptop  - Rebuild for laptop configuration"
    echo "  default - Rebuild for default configuration"
}

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Function to disable mupdf
disable_mupdf() {
    echo "Attempting to disable mupdf..."
    find . -name "*.nix" -type f -print0 | xargs -0 sed -i 's/\(.*mupdf.*\)/#\1/'
    echo "mupdf has been commented out in Nix files."
}

# Check if exactly one parameter is passed
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

# Set the flake name based on the parameter
FLAKE_NAME=$1
if [ "$FLAKE_NAME" != "laptop" ] && [ "$FLAKE_NAME" != "default" ]; then
    handle_error "Invalid parameter. Use 'laptop' or 'default'."
fi

# Configuration
FLAKE_PATH=~/NixOS
FLAKE_TARGET="#$FLAKE_NAME"
LOG_FILE="/tmp/nixos-rebuild-$(date +%Y%m%d-%H%M%S).log"

# Navigate to the directory containing the Flake
cd "$FLAKE_PATH" || handle_error "Failed to change directory to $FLAKE_PATH"

# Check for dirty Git tree
if [ -n "$(git status --porcelain)" ]; then
    echo "Warning: Git tree is dirty. Stashing changes..."
    git stash || handle_error "Failed to stash changes"
fi

# Update channels
echo "Updating Nix channels..."
sudo nix-channel --update || handle_error "Failed to update Nix channels"

# Clean Nix store
echo "Cleaning Nix store..."
sudo nix-store --gc || handle_error "Failed to clean Nix store"
sudo nix-collect-garbage -d || handle_error "Failed to collect garbage"

# Update flake inputs
echo "Updating flake inputs..."
nix flake update || handle_error "Failed to update flake inputs"

# Clean and format Nix files using "nixpkgs-fmt"
echo "Formatting Nix files..."
nixpkgs-fmt . || echo "Warning: nixpkgs-fmt failed, continuing anyway"

# Show diff for all Nix files
git diff -U0 *.nix

# Function to perform NixOS rebuild
perform_rebuild() {
    if sudo nixos-rebuild switch --flake "$FLAKE_TARGET" 2>&1 | tee "$LOG_FILE"; then
        echo "NixOS rebuild completed successfully."
        return 0
    else
        return 1
    fi
}

# Attempt initial rebuild
echo "Attempting initial NixOS rebuild..."
if ! perform_rebuild; then
    echo "Initial rebuild failed. Checking for mupdf-related errors..."
    if grep -q "mupdf" "$LOG_FILE"; then
        disable_mupdf
        echo "Retrying rebuild without mupdf..."
        if perform_rebuild; then
            echo "NixOS rebuild completed successfully after disabling mupdf."
        else
            handle_error "NixOS rebuild failed even after disabling mupdf. Check the log file: $LOG_FILE"
        fi
    else
        handle_error "NixOS rebuild failed. Check the log file: $LOG_FILE"
    fi
fi

# Get the current generation description
gen=$(nixos-rebuild list-generations | grep current)

# Get the hostname
hostname=$(hostname)

# Get the list of updated packages
updated_packages=$(nix store diff-closures /run/current-system /run/booted-system | grep '^[↑→]' | awk '{print $2}' | sort | uniq)

# Prepare commit message
commit_message="NixOS Rebuild: $hostname ($FLAKE_NAME)

Generation: $gen

Updated packages:
$updated_packages

This commit reflects changes made during a NixOS system rebuild."

# Commit changes with the detailed message
git add .
git commit -m "$commit_message" || handle_error "Failed to commit changes"

# Push changes to the remote repository
echo "Pushing changes to remote repository..."
git push || handle_error "Failed to push changes"

# Unstash changes if we stashed them earlier
if [ -n "$(git stash list)" ]; then
    echo "Unstashing changes..."
    git stash pop || handle_error "Failed to unstash changes"
fi

echo "NixOS rebuild and update completed successfully!"