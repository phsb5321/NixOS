#!/usr/bin/env bash

# Script to install ZSH plugins for Catppuccin setup
# This script should be run after setting up the dotfiles

set -e

echo "🐱 Setting up Catppuccin ZSH environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create Oh My Zsh custom plugins directory if it doesn't exist
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS_DIR="$ZSH_CUSTOM/plugins"

mkdir -p "$PLUGINS_DIR"

echo -e "${BLUE}📁 Using plugins directory: $PLUGINS_DIR${NC}"

# Function to install a plugin
install_plugin() {
  local plugin_name="$1"
  local repo_url="$2"
  local plugin_dir="$PLUGINS_DIR/$plugin_name"

  if [ -d "$plugin_dir" ]; then
    echo -e "${YELLOW}⚠️  $plugin_name already exists, updating...${NC}"
    cd "$plugin_dir"
    git pull
  else
    echo -e "${BLUE}📦 Installing $plugin_name...${NC}"
    git clone "$repo_url" "$plugin_dir"
  fi
}

# Install zsh-autosuggestions
install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"

# Install zsh-syntax-highlighting
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Install zsh-completions
install_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions.git"

# Install Powerlevel10k if not already present
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  echo -e "${YELLOW}⚠️  Powerlevel10k already exists, updating...${NC}"
  cd "$P10K_DIR"
  git pull
else
  echo -e "${BLUE}📦 Installing Powerlevel10k theme...${NC}"
  git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "$P10K_DIR"
fi

# Check if zoxide is installed
if ! command -v zoxide &>/dev/null; then
  echo -e "${YELLOW}⚠️  zoxide not found. Installing via cargo...${NC}"
  if command -v cargo &>/dev/null; then
    cargo install zoxide
  else
    echo -e "${RED}❌ Cargo not found. Please install zoxide manually:${NC}"
    echo -e "${BLUE}   curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh${NC}"
  fi
else
  echo -e "${GREEN}✅ zoxide is already installed${NC}"
fi

# Check if fzf is installed (optional for zoxide)
if ! command -v fzf &>/dev/null; then
  echo -e "${YELLOW}⚠️  fzf not found (optional for zoxide interactive selection)${NC}"
  echo -e "${BLUE}   You can install it with: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install${NC}"
else
  echo -e "${GREEN}✅ fzf is already installed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete! ${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Run 'p10k configure' to set up your Powerlevel10k prompt"
echo "3. Enjoy your new Catppuccin-themed terminal!"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "• Use 'z <directory>' for smart directory jumping"
echo "• Use 'zi' for interactive directory selection (if fzf is installed)"
echo "• Tab completion is enhanced with better suggestions"
echo "• Syntax highlighting will show commands in Catppuccin colors"
