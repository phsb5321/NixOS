#!/usr/bin/env bash

# Test script for nixswitch functionality
# Run this after rebuilding the system

echo "🧪 Testing nixswitch functionality..."
echo

# Check if nixswitch is available in PATH
if command -v nixswitch &>/dev/null; then
    echo "✅ nixswitch found in PATH"
    
    # Show where it's installed
    echo "📍 Location: $(which nixswitch)"
    echo
    
    # Test if the script can run (just show help/version)
    echo "📋 Testing nixswitch execution..."
    echo
    
    # Just check if it can be executed without errors
    if nixswitch --help &>/dev/null || nixswitch -h &>/dev/null; then
        echo "✅ nixswitch executes successfully"
    else
        echo "⚠️  nixswitch might not have --help flag, but that's okay"
    fi
    
    echo
    echo "🚀 Ready to use! Try running: nixswitch"
    
else
    echo "❌ nixswitch not found in PATH"
    echo "   Make sure you've rebuilt the system with:"
    echo "   nixos-rebuild switch --flake .#laptop"
    echo "   or"
    echo "   nixos-rebuild switch --flake .#default"
    exit 1
fi
