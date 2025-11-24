# Dotfiles Management Analysis & Improvement Plan

**Date:** October 5, 2025
**Current System:** Chezmoi-based dotfiles in NixOS project
**Objective:** Analyze and improve dotfiles management strategy

---

## Current State Analysis

### ✅ Strengths

1. **Project-Local Storage**
   - Dotfiles stored in `/home/notroot/NixOS/dotfiles/`
   - Part of main NixOS git repository
   - Easy to track and version control
   - No separate repo needed

2. **Helper Scripts**
   - Comprehensive shell scripts for common operations
   - `dotfiles-init`, `dotfiles-apply`, `dotfiles-edit`, `dotfiles-add`, `dotfiles-status`, `dotfiles-sync`
   - Shell aliases for convenience (`dotfiles`, `dotfiles-diff`)

3. **Chezmoi Integration**
   - Modern dotfiles manager with templating
   - Auto-commit capability
   - VS Code integration for editing
   - Custom source directory configuration

4. **Current Coverage**
   - Shell: `.zshrc`, `.bashrc`, `.zshenv`, `.profile`, `.p10k.zsh` (100KB total!)
   - Git: `.gitconfig`
   - Node: `.npmrc`
   - SSH: `.ssh/config` (131 lines, well-organized)
   - Editors: Zed (`.config/zed/`), Neovim (`.config/nvim/`)
   - Terminal: Starship (`.config/starship.toml`), Ghostty, Zellij
   - Total: 33 files, 312KB

5. **Multi-Host Support**
   - Chezmoi templating variables: hostname, username, os, arch
   - Ready for host-specific configurations

### ❌ Issues & Pain Points

#### 1. **Chezmoi Not Properly Initialized**
```bash
# Evidence:
$ cat ~/.config/chezmoi/chezmoi.toml
User chezmoi config not found
```
- User hasn't run `dotfiles-init`
- Configuration exists in repo but not deployed
- Scripts may not work as expected

#### 2. **Hardcoded Paths in Module**
```nix
dotfilesPath = "${config.users.users.${cfg.username}.home}/NixOS/dotfiles";
sourceDir = "/home/notroot/NixOS/dotfiles"  # In .chezmoi.toml
```
- Not portable across hosts
- Assumes specific directory structure
- Won't work if NixOS dir is elsewhere

#### 3. **No Template Usage**
```bash
$ find /home/notroot/NixOS/dotfiles -type f -name "*.tmpl"
# No output - no templates!
```
- All config files are static
- No per-host customization
- Missing opportunity for:
  - Different SSH configs per host
  - Host-specific Git configs
  - Laptop vs Desktop specific settings

#### 4. **Security Concerns**
- SSH config contains internal IP addresses (public in git)
- No encryption for sensitive dotfiles
- Private keys referenced but not managed
- Git config potentially has email/tokens

#### 5. **No Secrets Management Integration**
- SSH private keys not managed
- GPG keys not managed
- API tokens in dotfiles exposed
- No integration with sops-nix or age

#### 6. **Large Monolithic Files**
- `.p10k.zsh` is 90KB (huge!)
- `.zshrc` is 19KB
- `.zshenv` is 10KB
- Hard to maintain and understand
- Should be split into modular files

#### 7. **Missing Dotfiles**
- No `.gitignore` global config
- No `.editorconfig`
- No `.gdbinit`, `.pdbrc` (debuggers)
- No `.curlrc`, `.wgetrc`
- No `.tmux.conf` (if used)
- No workspace-specific configs (VS Code/Cursor workspaces)

#### 8. **No Automatic Sync**
- Changes require manual `dotfiles-apply`
- No systemd service for auto-sync
- Can easily get out of sync between source and home

#### 9. **Dotfiles in Main NixOS Repo**
- 372 commits in NixOS repo include dotfiles changes
- Pollutes NixOS configuration history
- Hard to track pure NixOS vs dotfiles changes
- No independent dotfiles CI/CD

#### 10. **No Testing**
- No validation that dotfiles apply correctly
- No syntax checking for configs
- No tests for shell scripts in dotfiles

---

## Improvement Proposals

### Option 1: Enhanced Chezmoi with Templates (Recommended)

**Keep current structure, add advanced features**

#### Changes:
1. **Template-based Configuration**
2. **Secrets Integration**
3. **Modular Shell Configs**
4. **Automatic Sync**
5. **Testing Infrastructure**

#### Pros:
- Minimal disruption
- Leverages existing setup
- Adds powerful features
- Better security

#### Cons:
- Still in NixOS repo (history pollution)
- Chezmoi learning curve

---

### Option 2: Separate Dotfiles Repository

**Move dotfiles to dedicated repo, use as git submodule**

#### Changes:
1. Create separate dotfiles repo
2. Add as submodule to NixOS
3. Independent version control
4. Dedicated CI/CD

#### Pros:
- Clean separation of concerns
- Independent history
- Can share dotfiles across non-NixOS systems
- Better for portfolio/public sharing

#### Cons:
- More complex setup
- Submodule management overhead
- Two repos to maintain

---

### Option 3: NixOS-Native Dotfiles

**Use NixOS modules to generate dotfiles**

#### Changes:
1. Remove chezmoi
2. Use NixOS `environment.etc` or user activation scripts
3. Generate dotfiles from Nix expressions

#### Pros:
- Pure Nix approach
- Type-safe configuration
- Atomic updates
- No external tools

#### Cons:
- Requires NixOS rebuild for changes
- Less flexible than chezmoi
- Harder to test configs locally
- You already said dotfiles solution is "much better" than home-manager

---

## Recommended Approach: Enhanced Chezmoi (Option 1)

### Phase 1: Fix Current Setup

#### Task 1.1: Proper Initialization ✓
```bash
# Run the init script
dotfiles-init

# Verify
chezmoi status
chezmoi managed
```

#### Task 1.2: Make Paths Portable ✓
```nix
# modules/dotfiles/default.nix
dotfilesPath = "${config.users.users.${cfg.username}.home}/${cfg.projectDir}/dotfiles";

# Add option
projectDir = mkOption {
  type = types.str;
  default = "NixOS";
  description = "Name of NixOS project directory";
};
```

#### Task 1.3: Fix .chezmoi.toml ✓
```toml
# Use template instead of hardcoded path
sourceDir = "{{ .chezmoi.homeDir }}/NixOS/dotfiles"

[data]
    # Add custom variables
    nixosHost = "{{ .chezmoi.hostname }}"
    isLaptop = {{ if eq .chezmoi.hostname "nixos-laptop" }}true{{ else }}false{{ end }}
    isDesktop = {{ if eq .chezmoi.hostname "nixos-desktop" }}true{{ else }}false{{ end }}
```

---

### Phase 2: Add Template Support

#### Task 2.1: Convert SSH Config to Template ✓

**Create:** `dotfiles/dot_ssh/config.tmpl`

```ssh-config
# Global SSH configuration
# Generated for: {{ .nixosHost }}

# GitHub
Host github.com
  User git
  IdentityFile ~/.ssh/github_key
  IdentitiesOnly yes

# Azure DevOps
Host ssh.dev.azure.com
  User git
  IdentityFile ~/.ssh/azure_key
  IdentitiesOnly yes

{{- if .isDesktop }}
# Desktop-only: Local infrastructure
Host ProxMox.Home301Server
  HostName 192.168.1.10
  User root
  IdentityFile ~/.ssh/proxmox_key
  SetEnv TERM=xterm-256color

Host ProxMox.PlexVM
  HostName 192.168.1.144
  User notroot
  IdentityFile ~/.ssh/proxmox_vm_105
  ServerAliveInterval 60
{{- end }}

{{- if .isLaptop }}
# Laptop-only: Mobile hosts
Host work-server
  HostName work.example.com
  User username
  IdentityFile ~/.ssh/work_key
{{- end }}

# Common development hosts (all machines)
Host pi
  HostName 192.168.1.124
  User pi
  IdentityFile ~/.ssh/delicasa_pi_key
  SetEnv TERM=xterm-256color
```

**Benefits:**
- Separate configs per host type
- Cleaner, more maintainable
- No unnecessary entries on wrong hosts

#### Task 2.2: Convert Git Config to Template ✓

**Create:** `dotfiles/dot_gitconfig.tmpl`

```gitconfig
[user]
{{- if .isDesktop }}
    name = Pedro Balbino
    email = personal@example.com
{{- else if .isLaptop }}
    name = Pedro Balbino
    email = work@example.com
{{- end }}
    signingkey = ~/.ssh/github_key.pub

[core]
    editor = {{ if lookPath "code" }}code --wait{{ else }}nvim{{ end }}
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = true

[push]
    autoSetupRemote = true

[commit]
    gpgsign = true

[gpg]
    format = ssh

[gpg "ssh"]
    allowedSignersFile = ~/.ssh/allowed_signers
```

#### Task 2.3: Modularize Shell Config ✓

**Problem:** `.zshrc` is 19KB monolithic

**Solution:** Split into modules

**Create:** `dotfiles/dot_zshrc.tmpl`

```bash
# Main .zshrc - Generated by chezmoi
# Host: {{ .nixosHost }}

# Source modular configurations
source ~/.config/zsh/env.zsh           # Environment variables
source ~/.config/zsh/aliases.zsh       # Aliases
source ~/.config/zsh/functions.zsh     # Custom functions
source ~/.config/zsh/completions.zsh   # Completion settings
source ~/.config/zsh/history.zsh       # History configuration
source ~/.config/zsh/plugins.zsh       # Plugin management

{{- if .isDesktop }}
source ~/.config/zsh/desktop.zsh       # Desktop-specific
{{- end }}

{{- if .isLaptop }}
source ~/.config/zsh/laptop.zsh        # Laptop-specific (battery, etc)
{{- end }}

# Initialize starship prompt
eval "$(starship init zsh)"

# Initialize zoxide (smarter cd)
eval "$(zoxide init zsh)"
```

**Create modular files:**
```
dotfiles/dot_config/zsh/
├── env.zsh              # PATH, exports
├── aliases.zsh          # All aliases
├── functions.zsh        # Custom functions
├── completions.zsh      # Completion config
├── history.zsh          # History settings
├── plugins.zsh          # oh-my-zsh, etc
├── desktop.zsh.tmpl     # Desktop-only (if isDesktop)
└── laptop.zsh.tmpl      # Laptop-only (if isLaptop)
```

**Benefits:**
- Easy to find and edit specific configs
- Can disable sections by commenting one line
- Host-specific sections isolated
- Much more maintainable

---

### Phase 3: Secrets Management Integration

#### Task 3.1: Use Chezmoi's Built-in Encryption ✓

Chezmoi supports multiple secret managers:
- 1Password
- Bitwarden
- pass
- LastPass
- Keepass
- Custom commands

**Recommended:** Use age encryption (compatible with sops-nix)

**Setup:**
```bash
# Generate age key (reuse from sops-nix)
age-keygen -o ~/.config/chezmoi/key.txt

# Configure chezmoi to use age
cat >> ~/.config/chezmoi/chezmoi.toml <<EOF
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..." # Your public key
EOF
```

**Encrypt sensitive files:**
```bash
# Add encrypted SSH key
chezmoi add --encrypt ~/.ssh/github_key

# Creates: dotfiles/encrypted_private_dot_ssh/encrypted_github_key.age
```

**Template with secrets:**
```bash
# dotfiles/dot_npmrc.tmpl
//registry.npmjs.org/:_authToken={{ (index (lastpass "npm-token") 0).password }}
```

#### Task 3.2: Integrate with sops-nix ✓

**Better approach:** Use sops-nix secrets in templates

**Update:** `modules/dotfiles/default.nix`

```nix
{
  config = mkIf cfg.enable {
    # Expose sops secrets to chezmoi
    environment.variables = {
      CHEZMOI_GITHUB_TOKEN = "$(cat ${config.sops.secrets.github-token.path})";
      CHEZMOI_NPM_TOKEN = "$(cat ${config.sops.secrets.npm-token.path})";
    };
  };
}
```

**Use in templates:**
```bash
# dotfiles/dot_npmrc.tmpl
//registry.npmjs.org/:_authToken={{ env "CHEZMOI_NPM_TOKEN" }}

# dotfiles/dot_gitconfig.tmpl
[github]
    token = {{ env "CHEZMOI_GITHUB_TOKEN" }}
```

**Benefits:**
- Centralized secret management (sops-nix)
- Secrets not in git
- Easy rotation
- Works with existing infrastructure

---

### Phase 4: Automatic Synchronization

#### Task 4.1: Add Systemd User Service ✓

**Create:** `modules/dotfiles/sync-service.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Systemd user service for automatic dotfiles sync
  systemd.user.services.dotfiles-sync = {
    description = "Sync dotfiles with chezmoi";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.chezmoi}/bin/chezmoi apply --source ${cfg.dotfilesPath}";
    };
  };

  # Timer to run every 5 minutes
  systemd.user.timers.dotfiles-sync = {
    description = "Timer for dotfiles sync";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Unit = "dotfiles-sync.service";
    };
  };

  # Path watcher - apply immediately on dotfiles directory change
  systemd.user.paths.dotfiles-watch = {
    description = "Watch dotfiles directory for changes";
    wantedBy = [ "default.target" ];

    pathConfig = {
      PathChanged = cfg.dotfilesPath;
      Unit = "dotfiles-sync.service";
    };
  };
}
```

**Benefits:**
- Auto-apply on boot
- Auto-apply on dotfiles change
- Periodic sync (safety net)
- No manual intervention needed

#### Task 4.2: Add Git Auto-Commit ✓

**Create:** `modules/dotfiles/auto-commit.nix`

```nix
{
  # Git auto-commit service
  systemd.user.services.dotfiles-commit = {
    description = "Auto-commit dotfiles changes";

    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = cfg.dotfilesPath;
      ExecStart = pkgs.writeShellScript "dotfiles-auto-commit" ''
        #!/usr/bin/env bash
        cd "${cfg.dotfilesPath}"

        if [[ -n $(git status --porcelain) ]]; then
          git add .
          git commit -m "chore(dotfiles): auto-commit changes from $(hostname) at $(date)"
          echo "✅ Dotfiles changes committed"
        else
          echo "✅ No dotfiles changes to commit"
        fi
      '';
    };
  };

  # Timer - commit changes every hour
  systemd.user.timers.dotfiles-commit = {
    description = "Timer for dotfiles auto-commit";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "1h";
      Unit = "dotfiles-commit.service";
    };
  };
}
```

---

### Phase 5: Testing Infrastructure

#### Task 5.1: Add Dotfiles Validation ✓

**Create:** `dotfiles/.chezmoitests/`

```bash
# dotfiles/.chezmoitests/test_shell.sh
#!/usr/bin/env bash

# Test zsh configuration
echo "Testing zsh configuration..."
zsh -n ~/.zshrc || exit 1

# Test aliases work
source ~/.zshrc
type ls &>/dev/null || exit 1

echo "✅ Shell tests passed"
```

```bash
# dotfiles/.chezmoitests/test_git.sh
#!/usr/bin/env bash

# Test git config is valid
git config --list &>/dev/null || exit 1

# Test signing is configured
git config user.signingkey &>/dev/null || exit 1

echo "✅ Git tests passed"
```

#### Task 5.2: Add Pre-Apply Checks ✓

**Update:** `modules/dotfiles/default.nix`

```nix
checkScript = pkgs.writeShellScriptBin "dotfiles-check" ''
  #!/usr/bin/env bash
  set -euo pipefail

  echo "🔍 Validating dotfiles..."

  # Check zsh syntax
  if [[ -f ~/.zshrc ]]; then
    zsh -n ~/.zshrc || { echo "❌ Invalid zsh config"; exit 1; }
  fi

  # Check SSH config syntax
  if [[ -f ~/.ssh/config ]]; then
    ssh -G localhost &>/dev/null || { echo "❌ Invalid SSH config"; exit 1; }
  fi

  # Check git config
  git config --list &>/dev/null || { echo "❌ Invalid git config"; exit 1; }

  echo "✅ All dotfiles valid"
'';
```

**Modify apply script:**
```nix
applyScript = pkgs.writeShellScriptBin "dotfiles-apply" ''
  # Run checks first
  ${checkScript}/bin/dotfiles-check || exit 1

  # Apply if checks pass
  chezmoi apply
'';
```

---

### Phase 6: Additional Improvements

#### Task 6.1: Add Missing Dotfiles ✓

**Global Git Ignore:**
```bash
# dotfiles/dot_gitignore_global
# OS-specific
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*.swo
*~

# Build artifacts
node_modules/
target/
dist/
build/
*.pyc
__pycache__/

# Secrets
.env
.env.local
*.pem
*.key
```

**EditorConfig:**
```bash
# dotfiles/dot_editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,ts,jsx,tsx,json,yml,yaml}]
indent_style = space
indent_size = 2

[*.{py,rs,go}]
indent_style = space
indent_size = 4

[*.nix]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
```

**GDB Init:**
```bash
# dotfiles/dot_gdbinit
set history save on
set history filename ~/.gdb_history
set print pretty on
set pagination off
```

#### Task 6.2: Add Backup/Restore ✓

**Create:** `dotfiles-backup` script

```nix
backupScript = pkgs.writeShellScriptBin "dotfiles-backup" ''
  #!/usr/bin/env bash
  BACKUP_DIR=~/dotfiles-backup-$(date +%Y%m%d-%H%M%S)

  echo "📦 Creating dotfiles backup..."
  mkdir -p "$BACKUP_DIR"

  # Backup all managed files
  chezmoi managed | while read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp -a "$HOME/$file" "$BACKUP_DIR/$file" 2>/dev/null || true
  done

  echo "✅ Backup created: $BACKUP_DIR"
  ls -lh "$BACKUP_DIR"
'';
```

#### Task 6.3: Add Documentation Generator ✓

**Create:** Script to document managed dotfiles

```nix
docScript = pkgs.writeShellScriptBin "dotfiles-doc" ''
  #!/usr/bin/env bash

  echo "# Managed Dotfiles" > /tmp/dotfiles-manifest.md
  echo "" >> /tmp/dotfiles-manifest.md
  echo "**Generated:** $(date)" >> /tmp/dotfiles-manifest.md
  echo "**Host:** $(hostname)" >> /tmp/dotfiles-manifest.md
  echo "" >> /tmp/dotfiles-manifest.md

  echo "## Files" >> /tmp/dotfiles-manifest.md
  chezmoi managed | while read -r file; do
    echo "- \`$file\`" >> /tmp/dotfiles-manifest.md
  done

  cat /tmp/dotfiles-manifest.md
  echo ""
  echo "💾 Saved to: /tmp/dotfiles-manifest.md"
'';
```

---

## Migration Plan

### Step-by-Step Implementation

#### Week 1: Foundation
1. **Day 1:** Run `dotfiles-init`, verify current setup
2. **Day 2:** Make paths portable, update module
3. **Day 3:** Convert SSH config to template
4. **Day 4:** Convert Git config to template
5. **Day 5:** Test templates on both hosts

#### Week 2: Modularization
1. **Day 1:** Split `.zshrc` into modules
2. **Day 2:** Create host-specific shell configs
3. **Day 3:** Add missing dotfiles (.gitignore, .editorconfig)
4. **Day 4:** Test all configs
5. **Day 5:** Documentation

#### Week 3: Advanced Features
1. **Day 1:** Set up secrets integration (age/sops)
2. **Day 2:** Add systemd sync services
3. **Day 3:** Add validation/testing
4. **Day 4:** Add backup/restore scripts
5. **Day 5:** Full system test

---

## Expected Outcomes

### Before
- ❌ Chezmoi not initialized
- ❌ Hardcoded paths
- ❌ No templates (static configs)
- ❌ Secrets in git
- ❌ Manual sync required
- ❌ No validation
- ❌ Monolithic config files

### After
- ✅ Properly initialized chezmoi
- ✅ Portable configuration
- ✅ Template-based per-host configs
- ✅ Encrypted secrets (age/sops)
- ✅ Automatic sync (systemd)
- ✅ Pre-apply validation
- ✅ Modular, maintainable configs
- ✅ Comprehensive testing
- ✅ Backup/restore capability
- ✅ Full documentation

---

## Alternative: Separate Dotfiles Repo (Future)

If you decide to separate dotfiles later:

```bash
# Create dotfiles repo
cd ~
git clone git@github.com:username/dotfiles.git
cd ~/NixOS
git submodule add git@github.com:username/dotfiles.git dotfiles

# Update module to use submodule
dotfilesPath = "${config.users.users.${cfg.username}.home}/NixOS/dotfiles";
```

**Benefits:**
- Independent version control
- Shareable across systems
- Cleaner NixOS history
- Can be public without exposing NixOS config

**When to do this:**
- After completing template migration
- When dotfiles are stable
- If you want to share dotfiles publicly
- When NixOS repo history is too polluted

---

## Conclusion

**Recommended Immediate Actions:**

1. ✅ Run `dotfiles-init` to properly initialize
2. ✅ Convert SSH and Git configs to templates
3. ✅ Set up secrets management with age
4. ✅ Add automatic sync with systemd

**Long-term Goals:**

1. Fully templated, host-aware configs
2. All secrets encrypted
3. Automatic sync and backup
4. Comprehensive testing
5. Consider separate repo if needed

Your current chezmoi setup is solid, it just needs proper initialization and template usage to reach its full potential!
