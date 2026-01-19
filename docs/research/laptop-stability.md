# NixOS Laptop Stability Guardrails - Research Document

## Overview

This document captures research findings and decisions for implementing stability guardrails on the NixOS laptop configuration. The goal is to maintain a **boringly reliable boot** while allowing **selectively bleeding-edge** packages and dev shells.

---

## 1. nixos-rebuild Modes: test vs switch vs boot

### Primary Sources
- [NixOS Manual - Upgrading NixOS](https://nixos.org/manual/nixos/stable/#sec-upgrading)
- [NixOS Wiki - Nixos-rebuild](https://wiki.nixos.org/wiki/Nixos-rebuild)

### Mode Reference Table

| Mode     | Activates Immediately | Adds to Bootloader | Use Case |
|----------|----------------------|-------------------|----------|
| **switch** | Yes | Yes | Immediate activation, becomes default boot |
| **boot**   | No (next reboot) | Yes | Changes take effect after reboot only |
| **test**   | Yes | No | Safe testing - reverts on reboot/crash |
| **build**  | No | No | Build only, no activation; leaves `result/` symlink |
| **dry-build** | No | No | Check what would be built without building |

### Safe Testing Workflow

```bash
# Step 1: Test without risking boot
sudo nixos-rebuild test --flake .#laptop

# Step 2: If issues occur, reboot to restore previous generation
# No bootloader entry was added, so automatic rollback happens

# Step 3: Once verified safe:
sudo nixos-rebuild switch --flake .#laptop
```

### Recovery Patterns

**Quick Rollback**:
```bash
sudo nixos-rebuild --rollback switch
```

**Manual Generation Selection**:
```bash
# List available generations
nixos-rebuild list-generations

# Switch to specific generation N
sudo /nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
```

### Decision: D4.1 - Safe Update Workflow
- **Always use `test` first** for configuration changes
- **Use `boot`** after test passes for production commit
- **Never use `switch` directly** for untested changes
- Provides atomic rollback: reboot = automatic recovery

---

## 2. systemd-boot Generation Retention + configurationLimit

### Primary Sources
- [NixOS Manual - Boot Loader](https://nixos.org/manual/nixos/stable/#sec-boot)
- [MyNixOS - boot.loader.systemd-boot.configurationLimit](https://mynixos.com/nixpkgs/option/boot.loader.systemd-boot.configurationLimit)

### Current State Analysis

The laptop configuration does NOT currently set `configurationLimit`:
```nix
boot.loader.systemd-boot = {
  enable = true;
  configurationLimit = 10;  # MISSING - defaults to null (unlimited)
};
```

### /boot Full Failure Mode

**Problem**: When /boot fills up (typically 500MB-1GB partition):
1. `nixos-rebuild` fails with "No space left on device"
2. Cannot add new boot entries
3. May leave orphaned .efi files

**Recovery Playbook**:
```bash
# Step 1: Check current disk usage
df -h /boot

# Step 2: Delete old generations (doesn't immediately free /boot)
sudo nix-collect-garbage -d

# Step 3: Examine current bootloader entries
ls /boot/loader/entries/

# Step 4: Manually remove orphaned .efi files (CAREFULLY)
# Only remove files NOT referenced in any *.conf entry
cat /boot/loader/entries/*.conf | grep linux | sort -u

# Step 5: Force rebuild to clean up /boot
sudo nixos-rebuild switch --flake .#laptop
```

### Decision: D2.1 - Boot Safety Defaults
- Set `configurationLimit = 15` for laptop
- Provides ~2 weeks of daily rebuilds as rollback targets
- Prevents /boot exhaustion on typical 512MB EFI partition
- Add /boot capacity monitoring to preflight script

---

## 3. GNOME/GDM: Wayland vs X11 and Black-Screen Mitigations

### Primary Sources
- [NixOS Wiki - GNOME](https://wiki.nixos.org/wiki/GNOME)
- [NixOS Wiki - NVIDIA](https://wiki.nixos.org/wiki/Nvidia)
- [NixOS Discourse - GNOME Wayland Issues](https://discourse.nixos.org/t/gnome-wayland-not-working-on-24-11-or-25-05-unstable/56836)

### Current Laptop Configuration

```nix
# hosts/laptop/configuration.nix
modules.desktop.gnome.wayland = {
  enable = lib.mkForce false;  # Force X11 for NVIDIA
  electronSupport = false;
  screenSharing = false;
  variant = "software";
};
```

### Black Screen Failure Tree

**Symptom 1: Black screen on GNOME Wayland login (NVIDIA)**
- Root cause: NVIDIA driver incompatibility
- Mitigation: Force X11 with `gdm.wayland = false`

**Symptom 2: Black screen after suspend/resume (NVIDIA)**
- Root cause: Power management conflicts
- Mitigation: Careful nvidia.powerManagement settings

**Symptom 3: Hybrid GPU (Intel + NVIDIA) black screen**
- Root cause: Kernel modules interfering
- Current solution: Disable hybrid graphics entirely

### GDM Fallback Toggle

Add to laptop configuration:
```nix
# modules/laptop/gdm-fallback.nix
{ config, lib, ... }: {
  options.modules.laptop.gdmFallback = {
    forceX11 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Force GDM to use X11 instead of Wayland";
    };
  };

  config = lib.mkIf config.modules.laptop.gdmFallback.forceX11 {
    services.xserver.displayManager.gdm.wayland = false;
  };
}
```

### Decision: D3.1 - GDM Safety Defaults
- Default to X11 on laptop (NVIDIA compatibility)
- Provide documented toggle for Wayland testing
- Include GDM health check in post-rebuild verification
- Document fallback procedure in failure playbook

---

## 4. Safe Mixing of Stable + Unstable Inputs

### Primary Sources
- [NixOS Discourse - Mixing Stable and Unstable](https://discourse.nixos.org/t/mixing-stable-and-unstable-packages-on-flake-based-nixos-system/50351)
- [Nixcademy - Mastering Overlays](https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/)

### Current Flake Architecture

```nix
# flake-modules/hosts.nix
hosts = {
  laptop = {
    system = "x86_64-linux";
    hostname = "nixos-laptop";
    configPath = "laptop";
    # Uses stable nixpkgs by default (GOOD!)
  };
};
```

The laptop already uses stable nixpkgs as base. Unstable packages are available via `pkgs-unstable` special arg.

### Correct Pattern: Overlay for Unstable Access

```nix
# Already in flake-modules/hosts.nix
pkgs-unstable = import inputs.nixpkgs-unstable {
  inherit system;
  config = pkgsConfig;
  inherit overlays;
};

# In configuration:
environment.systemPackages = [
  pkgs.firefox           # from stable
  pkgs-unstable.ghostty  # from unstable (explicit)
];
```

### Anti-Patterns to Avoid

**BAD**: Global nixpkgs substitution
```nix
# WRONG - forces full rebuild, loses cache
nixpkgs.pkgs = nixpkgs-unstable.legacyPackages.x86_64-linux;
```

**BAD**: Multiple nixpkgs imports in modules
```nix
# WRONG - creates thousands of instances
modules = [
  ({ pkgs, ... }: {
    environment.systemPackages = [
      (import nixpkgs-unstable { ... }).package
    ];
  })
];
```

### Decision: D1.1 - Stable Base, Unstable Opt-in
- Laptop already uses stable as base (verified)
- Create explicit allowlist module for unstable packages
- Document which packages are unstable and why
- No global pkgs swapping permitted

---

## 5. permittedInsecurePackages Scope and Minimization

### Primary Sources
- [Nixpkgs Reference Manual](https://nixos.org/manual/nixpkgs/stable/)
- [NixOS Discourse - permittedInsecurePackages](https://discourse.nixos.org/t/permittedinsecurepackages-not-taking-effect/44449)

### Current Insecure Packages

```nix
# flake-modules/hosts.nix
permittedInsecurePackages = [
  "gradle-7.6.6"      # Android development
  "electron-36.9.5"   # EOL Electron (required by installed packages)
];
```

### Correct Syntax (MUST include version)

```nix
# CORRECT - version required
permittedInsecurePackages = [
  "python-2.7.18.6"  # ✓ includes version
];

# WRONG - will not work
permittedInsecurePackages = [
  "python"  # ✗ missing version
];
```

### Scope Rules

**System-wide** (NixOS modules):
```nix
nixpkgs.config.permittedInsecurePackages = [ "pkg-1.2.3" ];
```

**User-level** (~/.config/nixpkgs/config.nix):
```nix
{ permittedInsecurePackages = [ "pkg-1.2.3" ]; }
```

**Dev Shell only** (preferred for development dependencies):
```nix
# shells/ESP.nix
{ pkgs ? import <nixpkgs> {
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "python-ecdsa-0.19.0" ];  # Scoped!
  };
}}:
```

### ESP Shell ecdsa Issue

**Problem**: The ESP shell pulls `python-ecdsa` which is marked insecure.

**Investigation needed**:
1. Check if newer non-insecure version exists
2. Check if the package can be overridden to use secure version
3. If not available, scope the allowlist to ESP shell only

### Decision: D4.1 - Insecure Package Policy
1. **Prefer upgrade/override** - always check for newer secure version first
2. **Scope narrowly** - use shell-specific config, not system-wide
3. **Document everything** - CVE reference, reason, removal plan
4. **Set expiry dates** - review quarterly

---

## Failure Playbooks

### Playbook 1: Boot Failure (No Previous Generations)

**Symptoms**: System won't boot, no generations in boot menu

**Recovery**:
1. Boot from NixOS live USB
2. Mount system partition: `sudo mount /dev/nvme0n1p2 /mnt`
3. Mount boot partition: `sudo mount /dev/nvme0n1p1 /mnt/boot`
4. Enter chroot: `sudo nixos-enter --root /mnt`
5. Rebuild: `nixos-rebuild boot --flake /home/notroot/NixOS#laptop`
6. Reboot

**Prevention**:
- Set `configurationLimit = 15`
- Run preflight checks before rebuild
- Always test with `nixos-rebuild test` first

### Playbook 2: GDM Failure (Black Screen)

**Symptoms**: GDM starts but screen stays black, can't log in

**Recovery**:
1. Switch to TTY: `Ctrl+Alt+F3`
2. Log in via terminal
3. Check GDM status: `systemctl status gdm`
4. Force X11: Edit `/etc/nixos/configuration.nix` temporarily
   ```nix
   services.xserver.displayManager.gdm.wayland = false;
   ```
5. Rebuild: `sudo nixos-rebuild switch --flake .#laptop`
6. Reboot

**Prevention**:
- Keep `gdm.wayland = false` on NVIDIA laptops
- Run healthcheck after rebuild
- Document known-good configuration

### Playbook 3: /boot Full

**Symptoms**: `nixos-rebuild` fails with "No space left on device"

**Recovery**:
1. Check usage: `df -h /boot`
2. List entries: `ls -la /boot/loader/entries/`
3. Find orphans: Compare entries to `nixos-rebuild list-generations`
4. Manual cleanup:
   ```bash
   # Remove generations first
   sudo nix-collect-garbage -d
   # Rebuild to sync /boot
   sudo nixos-rebuild boot --flake .#laptop
   ```
5. If still full, manually remove old .efi files (carefully!)

**Prevention**:
- Set `configurationLimit = 15`
- Monitor /boot in preflight script
- Run garbage collection weekly

### Playbook 4: Insecure Package Blocking Evaluation

**Symptoms**: `nix-shell` or build fails with "is marked as insecure"

**Recovery**:
1. Identify the package: Read error message for package name + version
2. Check if it's a direct or transitive dependency:
   ```bash
   nix why-depends .#devShells.x86_64-linux.esp pkgs.python-ecdsa
   ```
3. Try to upgrade:
   ```bash
   nix search nixpkgs python-ecdsa
   ```
4. If no secure version, add scoped allowlist:
   ```nix
   # In the specific shell only
   { pkgs ? import <nixpkgs> {
     config.permittedInsecurePackages = [ "python-ecdsa-0.19.0" ];
   }}:
   ```
5. Document with CVE and removal plan

**Prevention**:
- Keep insecure packages scoped to dev shells
- Review allowlist quarterly
- Prefer upgrading over allowlisting

---

## Implementation Checklist

- [ ] T000: This document (docs/research/laptop-stability.md)
- [ ] T001: scripts/laptop/preflight.sh
- [ ] T010: scripts/laptop/update-safe.sh
- [ ] T020: Configure boot.loader.systemd-boot.configurationLimit
- [ ] T021: Add /boot capacity guard to healthcheck
- [ ] T022: Document known-good generation pinning
- [ ] T030: scripts/laptop/healthcheck.sh
- [ ] T031: Add GDM Wayland fallback toggle
- [ ] T040: Refactor flake for pkgsStable/pkgsUnstable pattern
- [ ] T041: modules/laptop/unstable-allowlist.nix
- [ ] T050: docs/security/insecure-packages.md
- [ ] T051: Fix ESP shell ecdsa issue

---

## References

### Primary Sources
1. NixOS Manual - https://nixos.org/manual/nixos/stable/
2. NixOS Wiki - https://wiki.nixos.org/
3. Nixpkgs Reference - https://nixos.org/manual/nixpkgs/stable/

### Community Discussions
1. [Mixing Stable and Unstable](https://discourse.nixos.org/t/mixing-stable-and-unstable-packages-on-flake-based-nixos-system/50351)
2. [GNOME Wayland Issues](https://discourse.nixos.org/t/gnome-wayland-not-working-on-24-11-or-25-05-unstable/56836)
3. [permittedInsecurePackages Not Working](https://discourse.nixos.org/t/permittedinsecurepackages-not-taking-effect/44449)
4. [Full /boot Partition Recovery](https://discourse.nixos.org/t/what-to-do-with-a-full-boot-partition/2049)
