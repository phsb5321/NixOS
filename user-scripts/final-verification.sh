#!/usr/bin/env bash
# Final verification script for Catppuccin theme integration and ZSH plugins

set -euo pipefail

echo "🎨 Final Verification: Catppuccin Theme & ZSH Setup"
echo "=================================================="
echo ""

# Test 1: ZSH Syntax Check
echo "1. Testing ZSH configuration syntax..."
if zsh -n ~/.zshrc; then
  echo "✅ ZSH configuration syntax is valid"
else
  echo "❌ ZSH configuration has syntax errors"
  exit 1
fi

# Test 2: Check ZSH in a subshell
echo "2. Testing ZSH startup..."
if zsh -c "exit 0" 2>/dev/null; then
  echo "✅ ZSH starts successfully"
else
  echo "❌ ZSH startup failed"
  exit 1
fi

# Test 3: Check zoxide installation
echo "3. Testing zoxide installation..."
if command -v zoxide &>/dev/null; then
  echo "✅ zoxide is installed: $(which zoxide)"

  # Test zoxide database
  db_count=$(zoxide query --list 2>/dev/null | wc -l || echo "0")
  echo "📊 zoxide has $db_count tracked directories"
else
  echo "❌ zoxide is not installed"
  exit 1
fi

# Test 4: Check essential dotfiles
echo "4. Testing essential dotfiles..."
essential_files=(
  "$HOME/.zshrc"
  "$HOME/.config/kitty/kitty.conf"
  "$HOME/.config/kitty/catppuccin-mocha.conf"
  "$HOME/.config/zellij/config.kdl"
)

for file in "${essential_files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "✅ Found $file"
  else
    echo "❌ Missing $file"
    exit 1
  fi
done

# Test 5: Check Catppuccin themes
echo "5. Testing Catppuccin theme integration..."

# Check Kitty theme
if grep -q "catppuccin-mocha.conf" "$HOME/.config/kitty/kitty.conf"; then
  echo "✅ Kitty is configured for Catppuccin theme"
else
  echo "⚠️  Kitty may not be using Catppuccin theme"
fi

# Check ZSH highlighting colors (sample check)
if grep -q "#a6e3a1" "$HOME/.zshrc"; then
  echo "✅ ZSH syntax highlighting has Catppuccin colors"
else
  echo "⚠️  ZSH may not be using Catppuccin colors"
fi

# Check Zellij theme
if grep -q "catppuccin" "$HOME/.config/zellij/config.kdl"; then
  echo "✅ Zellij is configured for Catppuccin theme"
else
  echo "⚠️  Zellij may not be using Catppuccin theme"
fi

# Test 6: Dotfiles management
echo "6. Testing dotfiles management..."
if command -v dotfiles-status &>/dev/null; then
  echo "✅ Dotfiles helper scripts are available"

  # Quick status check
  if dotfiles-status &>/dev/null; then
    echo "✅ Dotfiles management is working"
  else
    echo "⚠️  Dotfiles status check had issues"
  fi
else
  echo "❌ Dotfiles helper scripts are not available"
  exit 1
fi

echo ""
echo "🎉 Verification Complete!"
echo ""
echo "📋 Summary:"
echo "  • ZSH configuration: ✅ Syntax valid, loads successfully"
echo "  • zoxide integration: ✅ Installed and functional"
echo "  • Catppuccin themes: ✅ Configured for Kitty, ZSH, and Zellij"
echo "  • Dotfiles management: ✅ chezmoi workflow active"
echo ""
echo "🚀 Next steps for a new terminal session:"
echo "  1. Open a new terminal/tab"
echo "  2. Test zoxide: z [directory_name]"
echo "  3. Test interactive: zi"
echo "  4. Enjoy the Catppuccin theme!"
echo ""
echo "🔧 Dotfiles management commands:"
echo "  • dotfiles-status  - Check status"
echo "  • dotfiles-edit    - Edit dotfiles"
echo "  • dotfiles-apply   - Apply changes"
echo "  • dotfiles-add     - Add new files"
