#!/usr/bin/env bash

# Test script for zoxide integration
echo "🧪 Testing zoxide integration..."

# Test basic zoxide commands
echo "📍 Testing zoxide commands:"

# Test if z command exists
if command -v z &>/dev/null; then
  echo "✅ z command is available"
else
  echo "❌ z command is NOT available"
  exit 1
fi

# Test if zi command exists
if command -v zi &>/dev/null; then
  echo "✅ zi command is available"
else
  echo "❌ zi command is NOT available"
fi

# Test if cd is aliased to z
if alias cd 2>/dev/null | grep -q "z"; then
  echo "✅ cd is aliased to z"
else
  echo "❌ cd is NOT aliased to z"
fi

# Test if fzf is available for interactive mode
if command -v fzf &>/dev/null; then
  echo "✅ fzf is available for interactive selection"
else
  echo "⚠️  fzf is not available (zi will still work but without interactive mode)"
fi

# Test basic zoxide functionality
echo ""
echo "🔍 Testing zoxide functionality:"

# Add current directory to zoxide database
zoxide add "$(pwd)"
echo "✅ Added current directory to zoxide database"

# Query zoxide database
if zoxide query . &>/dev/null; then
  echo "✅ Zoxide can query directories"
else
  echo "❌ Zoxide query failed"
fi

# Test directory jumping
original_dir="$(pwd)"
if cd /tmp && cd - &>/dev/null; then
  echo "✅ Directory navigation works"
else
  echo "❌ Directory navigation failed"
fi

echo ""
echo "📋 Zoxide configuration summary:"
echo "• z <dir>     - Jump to directory"
echo "• zi          - Interactive directory selection"
echo "• cd          - Aliased to z for smart navigation"
echo "• zoxide add  - Manually add directory"
echo "• zoxide query - Query database"

echo ""
echo "🎉 Zoxide integration test complete!"
