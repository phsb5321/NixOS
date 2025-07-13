# Chezmoi Dotfiles Management Setup

This NixOS configuration includes a comprehensive chezmoi setup for managing dotfiles. The dotfiles are stored directly within the NixOS project directory, making them part of your configuration repository.

## What's Included

### 1. Project-Local Dotfiles Directory
- Dotfiles stored in `~/NixOS/dotfiles/` within the project
- Integrated with the NixOS git repository
- No separate chezmoi source directory needed

### 2. Imported Dotfiles
The following dotfiles have been imported and are ready to use:
- **Shell Configuration**: `.zshrc`, `.bashrc`, `.profile`
- **Git Configuration**: `.gitconfig`
- **Node/NPM Configuration**: `.npmrc`
- **Terminal Configuration**: 
  - Powerlevel10k: `.p10k.zsh`
  - Kitty terminal: `.config/kitty/`
  - Starship prompt: `.config/starship.toml`
- **Editor Configuration**: Neovim (`.config/nvim/`)

### 3. Dotfiles Module (`modules/dotfiles/default.nix`)
- Project-local chezmoi configuration
- Helper scripts for dotfiles management
- Custom source directory pointing to `~/NixOS/dotfiles`

### 4. Helper Scripts
The following scripts are installed system-wide:
- `dotfiles-init` - Initialize and apply dotfiles
- `dotfiles-edit` - Open dotfiles in VS Code/Cursor
- `dotfiles-apply` - Apply dotfile changes
- `dotfiles-add` - Add new files to dotfiles
- `dotfiles-status` - Show managed files and status
- `dotfiles-sync` - Sync changes with git

### 5. Shell Aliases
Convenient aliases are available:
- `dotfiles` → `dotfiles-status`
- `dotfiles-diff` → `dotfiles-apply --diff`

## Quick Start

### 1. Rebuild NixOS Configuration

```bash
sudo nixos-rebuild switch
```

### 2. Initialize Dotfiles

```bash
dotfiles-init
```

This will apply all the imported dotfiles to your home directory.

### 3. Check Status

```bash
dotfiles-status
```

### 4. Edit Dotfiles

```bash
dotfiles-edit
```

This opens the `~/NixOS/dotfiles` directory in VS Code/Cursor.

### 5. Apply Changes

```bash
dotfiles-apply
```

This applies any changes you made to the dotfiles.

## Workflow

### Daily Usage

1. **Edit dotfiles**: `dotfiles-edit`
2. **Apply changes**: `dotfiles-apply`
3. **Check status**: `dotfiles-status` or `dotfiles`
4. **Add new files**: `dotfiles-add ~/.new-config`

### Git Integration

The dotfiles directory is a git repository within your NixOS project:
- Sync with git: `dotfiles-sync`
- Commit and push changes automatically
- Full version history of your dotfiles

## Features

### ✅ Project Integration
- Dotfiles are part of your NixOS configuration repository
- Single git repository for both system config and dotfiles
- No separate chezmoi repository needed

### ✅ Instantaneous Sync
- Changes apply immediately with `dotfiles-apply`
- No need to rebuild NixOS configuration
- Real-time dotfiles management

### ✅ Pre-Imported Configuration
- Common dotfiles already imported and ready to use
- Shell configurations (zsh, bash)
- Terminal configurations (kitty, starship, powerlevel10k)
- Editor configurations (neovim)
- Git and development tool configurations

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
