# NixOS Configuration Handoff Guide

**Last Updated:** 2026-01-10  
**Repository:** https://github.com/phsb5321/NixOS  
**Active PR:** https://github.com/phsb5321/NixOS/pull/7

---

## CRITICAL: Branch Workflow

**Before starting any work, check your branch:**
```bash
git branch --show-current
```

**If on a feature branch:** Plan to merge back to `host/desktop` before session ends.

**Standard workflow:**
```bash
# 1. Start from host branch
git checkout host/desktop

# 2. For significant work, create feature branch
git checkout -b NNN-feature-name

# 3. Before ending session, ALWAYS merge back
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --dry-run
git checkout host/desktop
git merge feature-branch-name
```

See `AGENTS.md` for full branch workflow documentation.

---

## Quick Reference for Claude Code Instances

This document provides instructions for Claude Code (or OpenCode) instances running on each NixOS host. Each host has specific requirements and constraints.

---

## Host-Specific Instructions

### Desktop Host (nixos-desktop)

**Hardware:** AMD RX 5700 XT GPU, high-performance desktop  
**Use Case:** Gaming, development, Waydroid (Android)

```bash
# CORRECT rebuild command
sudo nixos-rebuild switch --flake .#desktop

# Or use the TUI script
./user-scripts/nixswitch
```

**Key Features:**
- Wayland-only (GNOME on Wayland)
- AMD GPU with hardware acceleration
- Gaming packages enabled (Steam, Lutris, Wine)
- Waydroid for Android apps
- Full development environment

**Testing After Changes:**
```bash
# Enter any dev shell and verify testing toolchain
nix-shell shells/JavaScript.nix
test-toolchain-diagnose

# Check Waydroid
waydroid status
```

---

### Laptop Host (nixos-laptop)

**Hardware:** Intel GPU, battery-powered  
**Use Case:** Mobile development, power efficiency

```bash
# CORRECT rebuild command
sudo nixos-rebuild switch --flake .#laptop

# Or use the TUI script
./user-scripts/nixswitch
```

**Key Features:**
- X11 (for Intel GPU compatibility)
- Power management optimizations
- WiFi with sops-nix secrets
- Tailscale VPN enabled
- Minimal package set (no gaming)

**First-Time Setup (if secrets not configured):**
```bash
# Generate age key from SSH host key
sudo mkdir -p /var/lib/sops-nix
sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -o /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
```

**Testing After Changes:**
```bash
# Verify WiFi connects with sops secret
nmcli connection show

# Check power management
cat /sys/class/power_supply/BAT0/status

# Test development shells
nix-shell shells/Python.nix
test-toolchain-diagnose
```

---

### Server Host (nixos-server) - THIS HOST

**Hardware:** Proxmox VM with VirtIO-GPU  
**Use Case:** Media services, downloads, always-on

```bash
# CORRECT rebuild command (USE THIS ONE)
sudo nixos-rebuild switch --flake .#server

# Or use the TUI script
./user-scripts/nixswitch
```

**CRITICAL WARNING:**
- NEVER use `.#desktop` on this host
- NEVER use `.#laptop` on this host
- Server uses stable nixpkgs for reliability
- Sudo password: `123`

**Key Features:**
- X11 for Proxmox VM compatibility
- Always-on power settings (no idle, no suspend)
- Services: Plex, qBittorrent, Audiobookshelf
- Cloudflare tunnel for external access
- Minimal GNOME extensions

**Testing After Changes:**
```bash
# Check services are running
systemctl status plex
systemctl status qbittorrent
systemctl status audiobookshelf

# Test development shells
nix-shell shells/JavaScript.nix
test-toolchain-diagnose
```

---

## Current Branch Status

### Active Feature Branch: `001-nixos-test-toolchain`

**PR:** https://github.com/phsb5321/NixOS/pull/7

This branch includes:
1. **Testing Toolchain** - Playwright, Selenium, browser automation across all shells
2. **Multi-Host Architecture** - Unified profiles, reduced duplication
3. **Colmena Deployment** - Remote deployment capability

**To apply this branch on any host:**
```bash
cd ~/NixOS
git fetch origin
git checkout 001-nixos-test-toolchain
git pull origin 001-nixos-test-toolchain

# Build and test first
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Apply (replace <hostname> with desktop/laptop/server)
sudo nixos-rebuild switch --flake .#<hostname>
```

---

## Testing Toolchain Usage

All development shells now include a unified testing toolchain.

### Quick Start

```bash
# Enter any shell
nix-shell shells/JavaScript.nix

# Run diagnostics
test-toolchain-diagnose

# Run Playwright tests
npm install @playwright/test@1.57.0
npx playwright test --project=chromium
```

### Available Shells

| Shell | Command |
|-------|---------|
| JavaScript | `nix-shell shells/JavaScript.nix` |
| Python | `nix-shell shells/Python.nix` |
| Golang | `nix-shell shells/Golang.nix` |
| Rust | `nix-shell shells/Rust.nix` |
| Elixir | `nix-shell shells/Elixir.nix` |
| ESP32 | `nix-shell shells/ESP.nix` |
| Data Science | `nix-shell shells/DataScience.nix` |

### Docker Fallback (for Firefox/WebKit)

```bash
# Run tests in Docker
./scripts/playwright-docker.sh test

# Start Playwright Server
./scripts/playwright-server-docker.sh start

# Connect tests to server
PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:3000/ npx playwright test
```

### MCP Integration (for AI Assistants)

```bash
# Add to Claude Code
claude mcp add playwright npx @playwright/mcp@latest
```

See `docs/mcp-playwright.md` for OpenCode configuration.

---

## Common Tasks for Claude Code Instances

### 1. Pull Latest Changes

```bash
cd ~/NixOS
git fetch origin
git pull origin <branch-name>
```

### 2. Check Current Configuration

```bash
# Show current branch
git branch -v

# Show recent commits
git log --oneline -10

# Check for uncommitted changes
git status
```

### 3. Safe Rebuild (Test First)

```bash
# Build without switching (safe)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# If build succeeds, switch
sudo nixos-rebuild switch --flake .#<hostname>
```

### 4. Rollback If Something Breaks

```bash
# List generations
sudo nixos-rebuild list-generations

# Rollback to previous
sudo nixos-rebuild switch --rollback

# Or specific generation
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <NUMBER>
```

### 5. Format Nix Code

```bash
# Format all Nix files
alejandra .

# Check for issues
nix flake check
```

---

## Documentation Index

| Document | Purpose |
|----------|---------|
| `docs/testing-nixos.md` | Nix-native Playwright testing |
| `docs/testing-docker.md` | Docker fallback for browsers |
| `docs/mcp-playwright.md` | MCP integration for AI assistants |
| `docs/selenium.md` | Selenium WebDriver usage |
| `docs/architecture.md` | System architecture overview |
| `docs/DEPLOYMENT.md` | Deployment procedures |
| `CLAUDE.md` | Instructions for Claude Code |

---

## Git Workflow

### Branch Naming

- `main` - Stable, tested configuration
- `###-feature-name` - Feature branches (e.g., `001-nixos-test-toolchain`)
- `host/<hostname>` - Host-specific branches (legacy)

### Commit Message Format

```
type(scope): brief description

Types: feat, fix, refactor, docs, chore, test
Scopes: shells, gnome, packages, services, etc.
```

### Creating a PR

```bash
# Push branch
git push -u origin <branch-name>

# Create PR
gh pr create --title "type(scope): description" --body "Summary of changes"
```

---

## Troubleshooting

### Build Fails

```bash
# Check flake validity
nix flake check

# Show detailed error
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --show-trace
```

### Service Not Starting

```bash
# Check service status
systemctl status <service-name>

# View logs
journalctl -u <service-name> -f
```

### GNOME Issues

```bash
# Reset dconf to defaults
dconf reset -f /org/gnome/

# Restart GNOME Shell (X11)
killall -3 gnome-shell

# Restart GDM
sudo systemctl restart gdm
```

### Testing Toolchain Issues

```bash
# Run full diagnostics
test-toolchain-diagnose

# Check with JSON output
test-toolchain-diagnose --json | jq .

# Verify browser paths
echo $PLAYWRIGHT_BROWSERS_PATH
ls -la $PLAYWRIGHT_BROWSERS_PATH
```

---

## Contact & Resources

- **Repository:** https://github.com/phsb5321/NixOS
- **Active PR:** https://github.com/phsb5321/NixOS/pull/7
- **NixOS Wiki:** https://wiki.nixos.org
- **Playwright Docs:** https://playwright.dev/docs
