# Zed Editor Configuration for NixOS

This directory contains a comprehensive Zed Editor configuration optimized for NixOS development with enhanced Nix integration, Copilot support, and productivity features.

## 📁 Configuration Files

### `settings.json`
Main configuration file with:
- **Enhanced Nix Integration**: Uses `nixd` and `alejandra` for superior Nix language support
- **Copilot Integration**: Optimized AI-powered code completion and suggestions
- **Language Server Protocol**: Configured for 15+ programming languages
- **UI/UX Optimizations**: Gruvbox Dark Hard theme, JetBrains Mono Nerd Font
- **Agent Configuration**: Custom AI agent profiles with comprehensive tooling
- **SSH Remote Development**: Pre-configured connections to your remote servers

### `keymap.json`
Enhanced keyboard shortcuts including:
- **VSCode-compatible bindings** with Zed-specific improvements
- **Productivity shortcuts**: Multi-cursor editing, quick navigation, panel management
- **Git integration**: Stage, commit, push/pull operations
- **Code actions**: Formatting, refactoring, Go-to-definition
- **Terminal management**: New terminals, split panes, navigation
- **AI features**: Copilot suggestions, assistant interactions

### `tasks.json`
NixOS-specific development tasks:
- **NixOS Operations**: `nixos-rebuild switch/test/build`
- **Nix Flake Management**: `nix flake check/update/show`
- **Code Formatting**: Alejandra formatting for current file or all Nix files
- **Linting**: Statix and deadnix checks
- **Git Operations**: Automated commit workflows
- **System Maintenance**: Garbage collection, store optimization
- **Monitoring**: System and GPU monitoring tools

### `snippets/nix.json`
Comprehensive Nix language snippets:
- **Module Templates**: NixOS modules, options, services
- **Package Definitions**: Derivations, overlays, shells
- **Flake Templates**: Complete flake structures
- **Configuration Patterns**: Users, networking, fonts, boot loaders
- **Development Helpers**: Let-in expressions, conditionals, imports

## 🚀 Key Features

### Nix Language Support
- **Primary LSP**: `nixd` with flake-aware configuration
- **Fallback LSP**: `nil` for compatibility
- **Formatter**: `alejandra` with quiet mode
- **Auto-formatting**: Format on save enabled
- **Flake Integration**: Automatic NixOS and Home Manager options completion

### AI-Powered Development
- **GitHub Copilot**: Enabled with security exclusions for sensitive files
- **Zed Assistant**: AI assistant with comprehensive tool access
- **Edit Predictions**: Eager mode for faster suggestions
- **Agent Profiles**: Custom "Write" profile with file system and development tools

### Language Servers Included
- **Nix**: nixd, nil
- **JavaScript/TypeScript**: typescript-language-server, eslint
- **Python**: pyright, ruff
- **Rust**: rust-analyzer
- **Go**: gopls
- **Bash/Shell**: bash-language-server
- **JSON**: json-language-server
- **YAML**: yaml-language-server
- **TOML**: taplo
- **HTML/CSS**: vscode-langservers-extracted
- **Markdown**: marksman
- **Elixir**: elixir-ls

### Productivity Features
- **Format on Save**: Automatic code formatting
- **Git Integration**: Inline blame, gutter indicators, status bar
- **Project Management**: Enhanced file explorer with Git status
- **Terminal Integration**: Built-in terminal with Zsh
- **Multi-cursor Editing**: Advanced selection and editing capabilities
- **Code Actions**: Quick fixes, refactoring, go-to-definition

## ⌨️ Essential Keyboard Shortcuts

### File Operations
- `Ctrl+P`: Quick file finder
- `Ctrl+Shift+P`: Command palette
- `Ctrl+N`: New file
- `Ctrl+Shift+N`: New window
- `Ctrl+Shift+W`: Close all items

### Panel Management
- `Ctrl+B`: Toggle right dock (project panel/outline)
- `Ctrl+Shift+E`: Toggle left dock
- `Ctrl+Shift+``: Toggle terminal
- `F11`: Zen mode

### Code Navigation
- `F12`: Go to definition
- `Shift+F12`: Go to references
- `F2`: Rename symbol
- `Ctrl+.`: Code actions
- `Ctrl+G`: Go to line

### Git Operations
- `Ctrl+Shift+G G`: Open Git panel
- `Ctrl+Shift+G C`: Git commit
- `Ctrl+Shift+G P`: Git push
- `Ctrl+Shift+G U`: Git pull

### AI Features
- `Ctrl+I`: Toggle assistant
- `Alt+\`: Toggle Copilot
- `Alt+]`: Next Copilot suggestion
- `Alt+[`: Previous Copilot suggestion

### Multi-cursor
- `Ctrl+D`: Select next occurrence
- `Ctrl+Alt+Down`: Add cursor below
- `Ctrl+Alt+Up`: Add cursor above
- `Ctrl+Shift+L`: Select all occurrences

## 🔧 NixOS Development Tasks

### Quick Tasks (via Command Palette)
1. **NixOS: Rebuild Switch** - Apply configuration changes
2. **NixOS: Rebuild Test** - Test configuration without activation
3. **Format: Alejandra (All Nix Files)** - Format entire project
4. **Lint: Statix Check** - Check for Nix code issues
5. **Nix: Update Flake** - Update flake inputs

### System Maintenance
- **System: Garbage Collect** - Clean up old generations
- **System: Optimize Store** - Optimize Nix store
- **Dotfiles: Apply Chezmoi** - Apply dotfiles changes

### Monitoring
- **GPU: Monitor with radeontop** - Monitor AMD GPU usage
- **System: Monitor with htop** - System resource monitoring
- **Logs: View System Journal** - System logs analysis

## 🎨 Customization

### Theme and Fonts
- **Theme**: Gruvbox Dark Hard (can be changed in settings)
- **Font**: JetBrainsMono Nerd Font Mono, 18px
- **Fallback**: FiraCode Nerd Font Mono
- **Terminal Font**: Same as editor for consistency

### Language-Specific Settings
Each language has optimized settings:
- **Tab sizes**: 2 spaces for Nix/JS/TS, 4 for Python/Rust/Go
- **Formatters**: Language-appropriate (alejandra, prettier, black, etc.)
- **Linters**: Integrated with LSPs (eslint, ruff, etc.)

### Project Structure Support
- **File Exclusions**: Automatically excludes build artifacts, node_modules, etc.
- **Git Integration**: Full Git status in file explorer and editor
- **Workspace Settings**: Optimized for NixOS flake development

## 🔒 Security Features

### Copilot Security
- **Disabled for sensitive files**: `.env*`, `*.key`, `*.pem`, `*.cert`, `secrets/**`
- **Configurable exclusions**: Add patterns to protect sensitive code

### Privacy Settings
- **Telemetry disabled**: No diagnostic or metric data sent
- **Local processing**: Most features work offline

## 📦 Installation

The configuration is managed via Chezmoi dotfiles. To apply:

```bash
# From your NixOS directory
cd dotfiles
chezmoi apply
```

Or manually copy the files:

```bash
cp -r dot_config/zed ~/.config/
```

## 🔄 Updating

To update language servers and tools, modify `modules/packages/default.nix` and rebuild your system:

```bash
sudo nixos-rebuild switch --flake .#default
```

## 🐛 Troubleshooting

### Language Server Issues
1. Check if language servers are installed: `which nixd nil typescript-language-server`
2. Restart Zed Editor after system rebuild
3. Use Command Palette → "Zed: Reload Language Servers"

### Copilot Issues
1. Ensure you're signed in to GitHub in Zed
2. Check Copilot subscription status
3. Restart Zed if suggestions stop working

### Performance Issues
1. Reduce `buffer_font_size` if rendering is slow
2. Disable `inlay_hints` for large files
3. Use `ctrl-k z` for Zen mode in resource-constrained situations

## 📚 Additional Resources

- [Zed Editor Documentation](https://zed.dev/docs)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Alejandra Formatter](https://github.com/kamadorueda/alejandra)
- [Nixd Language Server](https://github.com/nix-community/nixd)

## 🤝 Contributing

To improve this configuration:
1. Test changes in your local environment
2. Update this README with new features
3. Consider adding new snippets for common patterns
4. Submit improvements via your dotfiles repository