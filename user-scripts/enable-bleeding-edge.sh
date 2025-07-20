#!/usr/bin/env bash

#######################################
# Enable Bleeding Edge Mode
# Quick script to enable bleeding edge packages
#######################################

set -euo pipefail

FLAKE_DIR="$HOME/NixOS"
HOST_CONFIG="${1:-default}"

info() {
    echo "ℹ️  $1"
}

success() {
    echo "✅ $1"
}

error() {
    echo "❌ $1"
    exit 1
}

cd "$FLAKE_DIR" || error "Cannot access flake directory: $FLAKE_DIR"

# Check if host config exists
if [[ ! -d "hosts/$HOST_CONFIG" ]]; then
    error "Host configuration '$HOST_CONFIG' not found"
fi

CONFIG_FILE="hosts/$HOST_CONFIG/configuration.nix"

info "Enabling bleeding edge packages for $HOST_CONFIG..."

# Check if bleeding edge is already enabled
if grep -q "modules.core.bleedingEdge.enable = true" "$CONFIG_FILE"; then
    success "Bleeding edge packages already enabled for $HOST_CONFIG"
    exit 0
fi

# Add bleeding edge configuration
if grep -q "modules.core.bleedingEdge" "$CONFIG_FILE"; then
    # Update existing configuration
    sed -i 's/modules.core.bleedingEdge.enable = false/modules.core.bleedingEdge.enable = true/' "$CONFIG_FILE"
else
    # Add new configuration after the modules section
    sed -i '/modules\.packages\.gaming\.enable = true;/a\
\
  # Enable bleeding edge packages\
  modules.core.bleedingEdge = {\
    enable = true;\
    level = "master";\  # Use absolute latest packages\
    packages = ["vscode" "firefox" "nodejs" "git" "code-cursor"];\
    };' "$CONFIG_FILE"
fi

success "Bleeding edge packages enabled for $HOST_CONFIG"
info "Run 'nixswitch $HOST_CONFIG' or 'nixswitch-bleeding' to apply changes"
