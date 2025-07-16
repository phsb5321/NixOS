# Dotfiles

This directory contains my dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Structure

- `dot_*` - Files that will be placed in the home directory (e.g., `dot_zshrc` → `~/.zshrc`)
- `dot_config/` - Files that will be placed in `~/.config/`
- `.chezmoi.toml` - Chezmoi configuration file

## Usage

The NixOS configuration includes helper scripts for managing these dotfiles:

### Initialize and Apply Dotfiles
```bash
dotfiles-init
```

### Edit Dotfiles
```bash
dotfiles-edit  # Opens this directory in VS Code/Cursor
```

### Apply Changes
```bash
dotfiles-apply
```

### Check Status
```bash
dotfiles-status
```

### Add New Files
```bash
dotfiles-add ~/.new-config-file
```

### Show Info and Managed Files
```bash
dotfiles-sync  # Shows info about dotfiles management
```

## Version Control

Dotfiles are version controlled as part of the main NixOS project repository. To commit changes:

```bash
cd /home/notroot/NixOS
git add dotfiles/
git commit -m "Update dotfiles: <description>"
```

## Files Managed

- **Shell Configuration**: `.zshrc`, `.bashrc`, `.profile`
- **Git Configuration**: `.gitconfig`
- **Node/NPM Configuration**: `.npmrc`
- **Terminal Configuration**: 
  - Powerlevel10k: `.p10k.zsh`
  - Kitty terminal: `.config/kitty/`
  - Starship prompt: `.config/starship.toml`
- **Editor Configuration**: Neovim (`.config/nvim/`)

## Chezmoi Configuration

The `.chezmoi.toml` file configures:
- Custom source directory within the NixOS project
- Auto-commit changes
- VS Code as default editor
- Template variables for hostname, username, OS, architecture

## Integration with NixOS

These dotfiles are integrated with the NixOS configuration through the `modules.dotfiles` module, which provides:
- System-wide chezmoi installation
- Helper scripts for dotfiles management
- Shell aliases for convenience

The dotfiles work independently of NixOS Home Manager and provide instantaneous configuration changes without requiring system rebuilds.
