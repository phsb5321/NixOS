# Dotfiles Directory

The `dotfiles/` directory is a separate git repository containing user dotfiles managed by chezmoi.

## Location
- Path: `~/NixOS/dotfiles/`
- Git repository: Independent from the main NixOS repository
- Contains: User configuration files in chezmoi format

## Contents
- Shell configurations (.zshrc, .bashrc, .profile)
- Git configuration (.gitconfig)
- Terminal configurations (kitty, starship, powerlevel10k)
- Editor configurations (neovim)
- Development tool configurations

## Usage
After rebuilding NixOS with the new dotfiles module:

```bash
# Initialize and apply dotfiles
dotfiles-init

# Check status
dotfiles-status

# Edit dotfiles
dotfiles-edit

# Apply changes
dotfiles-apply

# Sync with git
dotfiles-sync
```

## Integration
The dotfiles are integrated with NixOS through the `modules.dotfiles` module, which provides:
- System-wide chezmoi installation
- Helper scripts for dotfiles management
- Configuration for using the project-local dotfiles directory

The dotfiles work independently of NixOS Home Manager and provide instantaneous configuration changes without requiring system rebuilds.
