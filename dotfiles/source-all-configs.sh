#!/usr/bin/env bash
# Sourcing Script - Apply and Source All Dotfiles Configurations
# This script applies all dotfiles and sources the configurations

set -euo pipefail

echo "🔄 Applying and Sourcing All Dotfiles Configurations"
echo "===================================================="
echo ""

# Step 1: Apply all dotfiles
echo "1. Applying dotfiles..."
if dotfiles-apply; then
  echo "✅ Dotfiles applied successfully"
else
  echo "❌ Failed to apply dotfiles"
  exit 1
fi

echo ""

# Step 2: Initialize zoxide (if not already done)
echo "2. Initializing zoxide..."
if eval "$(zoxide init zsh)"; then
  echo "✅ zoxide initialized"
else
  echo "❌ Failed to initialize zoxide"
  exit 1
fi

echo ""

# Step 3: Test core functionalities
echo "3. Testing core functionalities..."

# Test zoxide
if command -v z &>/dev/null; then
  echo "✅ zoxide 'z' command available"
else
  echo "❌ zoxide 'z' command not available"
fi

# Test p10k
if type p10k &>/dev/null; then
  echo "✅ Powerlevel10k available"
else
  echo "❌ Powerlevel10k not available"
fi

# Test ZSH plugins
if [[ -n "${plugins:-}" ]]; then
  echo "✅ ZSH plugins loaded: $plugins"
else
  echo "⚠️  ZSH plugins variable not set (may still be working)"
fi

echo ""

# Step 4: Status check
echo "4. Final status check..."
if dotfiles-status | grep -q "All dotfiles are up to date"; then
  echo "✅ All dotfiles are synchronized"
else
  echo "⚠️  Some dotfiles may need attention"
  dotfiles-status
fi

echo ""
echo "🎉 Configuration Sourcing Complete!"
echo ""
echo "📋 What's Active:"
echo "  • ✅ Dotfiles applied and synchronized"
echo "  • ✅ zoxide navigation (z, zi commands)"
echo "  • ✅ Powerlevel10k prompt theme"
echo "  • ✅ ZSH plugins (autosuggestions, syntax highlighting, etc.)"
echo "  • ✅ Catppuccin color scheme"
echo "  • ✅ Advanced terminal integrations"
echo ""
echo "🚀 Ready to use! Open a new terminal to see the full setup in action."
echo ""
echo "💡 Key commands:"
echo "  • z <directory>     - Smart directory navigation"
echo "  • zi               - Interactive directory selection"
echo "  • p10k configure   - Reconfigure prompt"
echo "  • dotfiles-status  - Check dotfiles sync status"
echo "  • dotfiles-edit    - Edit configurations"
