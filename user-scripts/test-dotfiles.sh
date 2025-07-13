#!/usr/bin/env bash
# Test script for dotfiles setup

set -euo pipefail

echo "🧪 Testing Chezmoi Dotfiles Setup"
echo "================================="

DOTFILES_DIR="/home/notroot/NixOS/dotfiles"

# Test 1: Check if dotfiles directory exists
echo "1. Checking dotfiles directory..."
if [[ -d "$DOTFILES_DIR" ]]; then
    echo "✅ Dotfiles directory exists: $DOTFILES_DIR"
else
    echo "❌ Dotfiles directory not found"
    exit 1
fi

# Test 2: Check if chezmoi config exists
echo "2. Checking chezmoi configuration..."
if [[ -f "$DOTFILES_DIR/.chezmoi.toml" ]]; then
    echo "✅ Chezmoi configuration found"
else
    echo "❌ Chezmoi configuration not found"
    exit 1
fi

# Test 3: Check for essential dotfiles
echo "3. Checking essential dotfiles..."
essential_files=("dot_zshrc" "dot_bashrc" "dot_gitconfig")
for file in "${essential_files[@]}"; do
    if [[ -f "$DOTFILES_DIR/$file" ]]; then
        echo "✅ Found $file"
    else
        echo "❌ Missing $file"
        exit 1
    fi
done

# Test 4: Check if git repository is initialized
echo "4. Checking git repository..."
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "✅ Git repository initialized"
    cd "$DOTFILES_DIR"
    echo "   Latest commit: $(git log --oneline -1 2>/dev/null || echo 'No commits')"
else
    echo "❌ Git repository not found"
    exit 1
fi

# Test 5: Test chezmoi application (dry run)
echo "5. Testing chezmoi application (dry run)..."
if command -v chezmoi &> /dev/null; then
    if chezmoi apply --source "$DOTFILES_DIR" --dry-run &> /dev/null; then
        echo "✅ Chezmoi can apply dotfiles successfully"
    else
        echo "❌ Chezmoi apply test failed"
        exit 1
    fi
else
    echo "⚠️  Chezmoi not installed yet (normal before NixOS rebuild)"
fi

echo ""
echo "🎉 All tests passed!"
echo ""
echo "Next steps after NixOS rebuild:"
echo "1. Run: dotfiles-init"
echo "2. Run: dotfiles-status"
echo "3. Edit dotfiles: dotfiles-edit"
echo "4. Apply changes: dotfiles-apply"
