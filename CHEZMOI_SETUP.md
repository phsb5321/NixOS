# Chezmoi Dotfiles Management Setup

This NixOS configuration now includes a comprehensive chezmoi setup for managing dotfiles across multiple machines. Chezmoi is completely independent of Nix and Home Manager, providing a single source of truth for all your dotfiles.

## What's Included

### 1. Chezmoi Package
- Added `chezmoi` to the development tools in `modules/packages/default.nix`
- Available system-wide on all hosts

### 2. Dotfiles Module (`modules/dotfiles/default.nix`)
- Comprehensive dotfiles management configuration
- Helper scripts for common operations
- Shell aliases for convenience
- Helpful MOTD messages

### 3. Helper Scripts
The following scripts are installed system-wide:
- `init-chezmoi` - Initialize chezmoi setup
- `dotfiles-edit` - Open dotfiles in VS Code/Cursor
- `dotfiles-sync` - Apply changes and sync
- `dotfiles-add` - Add files to chezmoi
- `dotfiles-status` - Show managed files and status

### 4. Shell Aliases
Convenient aliases are available:
- `dotfiles` → `dotfiles-status`
- `chezcd` → `cd $(chezmoi source-path)`
- `chezcode` → `dotfiles-edit`
- `chezsync` → `dotfiles-sync`
- `chezadd` → `dotfiles-add`

### 5. Comprehensive Manager Script
- `user-scripts/chezmoi-manager.sh` - Full-featured dotfiles manager
- `user-scripts/dotfiles` - Simple wrapper script

## Quick Start

### 1. Rebuild NixOS Configuration
```bash
sudo nixos-rebuild switch
```

### 2. Initialize Chezmoi
Choose one of these options:

**Option A: Start from existing repository**
```bash
init-chezmoi
# Enter your repository URL when prompted
```

**Option B: Start fresh**
```bash
init-chezmoi
# Leave repository URL empty when prompted
```

**Option C: Use the comprehensive manager**
```bash
./user-scripts/dotfiles init
```

### 3. Add Your Dotfiles
```bash
# Add individual files
dotfiles-add ~/.bashrc ~/.zshrc ~/.config/nvim

# Or use the quick setup for common files
./user-scripts/dotfiles quick-setup
```

### 4. Edit Your Dotfiles
```bash
# Open in VS Code/Cursor
dotfiles-edit

# Or use the manager
./user-scripts/dotfiles edit
```

### 5. Apply Changes
```bash
# Sync changes to your system
dotfiles-sync

# Or use the manager
./user-scripts/dotfiles sync
```

## Workflow

### Daily Usage
1. **Edit dotfiles**: `dotfiles-edit` or `chezcode`
2. **Apply changes**: `dotfiles-sync` or `chezsync`
3. **Check status**: `dotfiles-status` or `dotfiles`
4. **Add new files**: `dotfiles-add ~/.new-config` or `chezadd ~/.new-config`

### Git Integration
The setup includes automatic git integration:
- Initialize git repository: `./user-scripts/dotfiles git-setup`
- Auto-commit and push during sync operations
- Maintains version history of your dotfiles

## Features

### ✅ Independent of Nix
- Chezmoi operates completely independently of NixOS and Home Manager
- No Nix dependencies for chezmoi operations
- Portable across different systems

### ✅ Instantaneous Sync
- Changes to dotfiles in chezmoi source are applied immediately when you run sync
- No need to rebuild NixOS configuration
- Real-time dotfiles management

### ✅ Single Source of Truth
- All dotfiles are managed in one central location
- Version controlled with git
- Easy to share across multiple machines

### ✅ Cross-Platform
- Works on Linux, macOS, Windows, WSL
- Same workflow everywhere
- Host-specific templating available

### ✅ Secure
- Optional encryption for secrets
- GPG or age encryption support
- Safe storage of sensitive configuration

## Advanced Features

### Templates
Chezmoi supports templating for host-specific configurations:
```bash
{{ if eq .hostname "work-laptop" }}
# work-specific config
{{ else }}
# home config
{{ end }}
```

### Secrets Management
Store encrypted secrets:
```bash
chezmoi secret add github_token
```

Use in templates:
```bash
export GITHUB_TOKEN="{{ secret "github_token" }}"
```

### Multiple Machines
Same repository, different configurations:
```bash
# On first machine
chezmoi init --apply https://github.com/username/dotfiles.git

# On additional machines
chezmoi init --apply username
```

## Troubleshooting

### Chezmoi Not Found
If chezmoi is not available after rebuilding:
```bash
# Check if it's installed
which chezmoi

# If not, ensure the dotfiles module is enabled and rebuild
sudo nixos-rebuild switch
```

### Permission Issues
If you encounter permission issues:
```bash
# Check chezmoi source permissions
ls -la $(chezmoi source-path)

# Fix if needed
chmod -R u+rw $(chezmoi source-path)
```

### Git Issues
If git operations fail:
```bash
# Navigate to chezmoi source
chezcd

# Check git status
git status

# Set up git if needed
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

## File Locations

- **Chezmoi source**: `~/.local/share/chezmoi` (default)
- **Configuration**: `~/.config/chezmoi/chezmoi.toml`
- **Scripts**: Available in PATH as system packages
- **NixOS module**: `modules/dotfiles/default.nix`

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Chezmoi GitHub](https://github.com/twpayne/chezmoi)
- [Template Examples](https://www.chezmoi.io/user-guide/templates/)
- [Secrets Management](https://www.chezmoi.io/user-guide/secrets/)

## Migration from Home Manager

If you were previously using Home Manager for dotfiles:

1. **Backup current dotfiles**:
   ```bash
   cp -r ~/.config ~/.config.backup
   ```

2. **Initialize chezmoi and add current files**:
   ```bash
   init-chezmoi
   ./user-scripts/dotfiles quick-setup
   ```

3. **Disable Home Manager dotfiles** (if you were using it)

4. **Test the new setup**:
   ```bash
   dotfiles-sync
   ```

The chezmoi setup is now fully independent and ready to use!
