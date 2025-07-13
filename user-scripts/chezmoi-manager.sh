#!/usr/bin/env bash
# ~/NixOS/user-scripts/chezmoi-manager.sh
# Comprehensive chezmoi dotfiles management script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if chezmoi is installed
check_chezmoi() {
    if ! command -v chezmoi &> /dev/null; then
        log_error "chezmoi is not installed. Please rebuild your NixOS configuration first."
        exit 1
    fi
}

# Check if chezmoi is initialized
check_initialized() {
    if [[ ! -d "$(chezmoi source-path)" ]]; then
        log_error "Chezmoi not initialized. Run '$0 init' first."
        exit 1
    fi
}

# Initialize chezmoi
cmd_init() {
    check_chezmoi
    
    local repo_url=""
    local dotfiles_dir="$HOME/.local/share/chezmoi"
    
    echo -e "${CYAN}🧰 Chezmoi Dotfiles Setup${NC}"
    echo "========================="
    
    # Check if already initialized
    if [[ -d "$dotfiles_dir" ]]; then
        log_warning "Chezmoi already initialized at: $dotfiles_dir"
        read -p "Reinitialize? This will backup existing configuration (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$dotfiles_dir" "${dotfiles_dir}.backup.$(date +%Y%m%d_%H%M%S)"
            log_info "Backed up existing configuration"
        else
            log_info "Keeping existing configuration"
            return 0
        fi
    fi
    
    read -p "Enter your dotfiles repository URL (leave empty to start fresh): " repo_url
    
    if [[ -n "$repo_url" ]]; then
        log_info "Initializing chezmoi from repository: $repo_url"
        chezmoi init "$repo_url"
        log_success "Repository cloned to: $(chezmoi source-path)"
        
        read -p "Apply dotfiles now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chezmoi apply
            log_success "Dotfiles applied successfully!"
        fi
    else
        log_info "Initializing fresh chezmoi configuration"
        chezmoi init --prompt
        log_success "Chezmoi initialized at: $(chezmoi source-path)"
        
        echo ""
        echo "Next steps:"
        echo "1. Add your dotfiles: $0 add ~/.bashrc ~/.zshrc ~/.config/nvim"
        echo "2. Edit dotfiles: $0 edit"
        echo "3. Apply changes: $0 sync"
        echo "4. Set up git: $0 git-setup"
    fi
    
    echo ""
    log_info "Chezmoi source directory: $(chezmoi source-path)"
    log_info "Use '$0 edit' to open dotfiles in your editor"
    log_info "Use '$0 sync' to sync changes"
}

# Edit dotfiles in editor
cmd_edit() {
    check_chezmoi
    check_initialized
    
    local source_path
    source_path=$(chezmoi source-path)
    
    if command -v code &> /dev/null; then
        log_info "Opening dotfiles in VS Code: $source_path"
        code "$source_path"
    elif command -v cursor &> /dev/null; then
        log_info "Opening dotfiles in Cursor: $source_path"
        cursor "$source_path"
    else
        log_info "Dotfiles directory: $source_path"
        log_warning "No supported editor found. Install VS Code or Cursor."
        
        # Try to open with default file manager
        if command -v xdg-open &> /dev/null; then
            xdg-open "$source_path"
        fi
    fi
}

# Sync dotfiles
cmd_sync() {
    check_chezmoi
    check_initialized
    
    local source_path
    source_path=$(chezmoi source-path)
    
    log_info "Syncing dotfiles..."
    
    # Show what would change
    if chezmoi diff --no-pager 2>/dev/null | grep -q .; then
        echo -e "${CYAN}📋 Pending changes:${NC}"
        chezmoi diff --no-pager 2>/dev/null || true
        echo ""
        
        read -p "Apply these changes? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_warning "Sync cancelled"
            return 0
        fi
    else
        log_success "No changes to apply"
    fi
    
    # Apply changes
    chezmoi apply
    log_success "Dotfiles synced successfully!"
    
    # Auto-commit if in git repository
    cd "$source_path"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            echo ""
            read -p "Commit and push changes to git? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git add .
                read -p "Enter commit message (default: 'Update dotfiles'): " commit_msg
                commit_msg=${commit_msg:-"Update dotfiles"}
                git commit -m "$commit_msg"
                
                if git remote get-url origin > /dev/null 2>&1; then
                    git push
                    log_success "Changes pushed to remote repository"
                else
                    log_warning "No remote repository configured"
                fi
            fi
        fi
    fi
}

# Add files to chezmoi
cmd_add() {
    check_chezmoi
    check_initialized
    
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 add <file1> [file2] ..."
        echo "Examples:"
        echo "  $0 add ~/.bashrc"
        echo "  $0 add ~/.config/nvim"
        echo "  $0 add ~/.ssh/config"
        return 1
    fi
    
    for file in "$@"; do
        if [[ -e "$file" ]]; then
            log_info "Adding $file to chezmoi..."
            chezmoi add "$file"
            log_success "Added $file"
        else
            log_error "File not found: $file"
        fi
    done
    
    echo ""
    log_info "Use '$0 edit' to modify your dotfiles"
    log_info "Use '$0 sync' to apply changes"
}

# Show status
cmd_status() {
    check_chezmoi
    check_initialized
    
    echo -e "${CYAN}🧰 Chezmoi Status${NC}"
    echo "================"
    echo "📁 Source directory: $(chezmoi source-path)"
    echo ""
    
    echo -e "${CYAN}📋 Managed files:${NC}"
    chezmoi managed 2>/dev/null || log_warning "No files managed yet"
    echo ""
    
    echo -e "${CYAN}🔄 Status:${NC}"
    chezmoi status 2>/dev/null || true
    echo ""
    
    # Check if there are differences
    if chezmoi diff --no-pager 2>/dev/null | grep -q .; then
        log_warning "There are pending changes. Run '$0 sync' to apply them."
    else
        log_success "All dotfiles are up to date"
    fi
}

# Set up git repository
cmd_git_setup() {
    check_chezmoi
    check_initialized
    
    local source_path
    source_path=$(chezmoi source-path)
    cd "$source_path"
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        log_info "Git repository already initialized"
        git remote -v
        return 0
    fi
    
    log_info "Initializing git repository in chezmoi source directory"
    git init
    
    read -p "Enter remote repository URL (optional): " remote_url
    if [[ -n "$remote_url" ]]; then
        git remote add origin "$remote_url"
        log_success "Added remote: $remote_url"
    fi
    
    # Create initial commit
    git add .
    git commit -m "Initial dotfiles commit"
    log_success "Created initial commit"
    
    if [[ -n "$remote_url" ]]; then
        read -p "Push to remote repository? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push -u origin main
            log_success "Pushed to remote repository"
        fi
    fi
}

# Quick setup for common dotfiles
cmd_quick_setup() {
    check_chezmoi
    check_initialized
    
    log_info "Quick setup: Adding common dotfiles"
    
    local common_files=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.gitconfig"
        "$HOME/.config/nvim"
        "$HOME/.config/kitty"
        "$HOME/.config/starship.toml"
    )
    
    for file in "${common_files[@]}"; do
        if [[ -e "$file" ]]; then
            log_info "Adding $file..."
            chezmoi add "$file" 2>/dev/null && log_success "Added $file" || log_warning "Failed to add $file"
        fi
    done
    
    log_success "Quick setup complete!"
    log_info "Use '$0 edit' to customize your dotfiles"
}

# Help function
cmd_help() {
    echo -e "${CYAN}🧰 Chezmoi Dotfiles Manager${NC}"
    echo "==========================="
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  init            Initialize chezmoi (from repo or fresh)"
    echo "  status          Show managed files and status"
    echo "  edit            Edit dotfiles in VS Code/Cursor"
    echo "  add <files>     Add files to chezmoi management"
    echo "  sync            Apply changes and sync with system"
    echo "  git-setup       Initialize git repository"
    echo "  quick-setup     Add common dotfiles automatically"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 add ~/.bashrc ~/.config/nvim"
    echo "  $0 sync"
    echo "  $0 edit"
    echo ""
    echo "For more information, visit: https://www.chezmoi.io/"
}

# Main command dispatcher
main() {
    case "${1:-help}" in
        "init")
            shift
            cmd_init "$@"
            ;;
        "edit")
            shift
            cmd_edit "$@"
            ;;
        "sync")
            shift
            cmd_sync "$@"
            ;;
        "add")
            shift
            cmd_add "$@"
            ;;
        "status")
            shift
            cmd_status "$@"
            ;;
        "git-setup")
            shift
            cmd_git_setup "$@"
            ;;
        "quick-setup")
            shift
            cmd_quick_setup "$@"
            ;;
        "help"|"-h"|"--help")
            cmd_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
