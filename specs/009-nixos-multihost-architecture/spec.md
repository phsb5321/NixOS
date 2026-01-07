# NixOS Multi-Host Architecture Improvement Specification

**Feature ID:** 009-nixos-multihost-architecture
**Status:** Draft
**Created:** 2026-01-07
**Hard Constraint:** NO Home Manager - NixOS modules/system-level configuration only

---

## 1. Problem Statement

This NixOS configuration manages multiple hosts (desktop, laptop, server) using a flake-based architecture. While the current setup is functional, several architectural issues impact maintainability, consistency, and scalability:

### Pain Points

1. **User Configuration Duplication**: The `users.users.notroot` block is defined in 6+ locations:
   - `modules/roles/desktop.nix:35`
   - `modules/roles/laptop.nix:39`
   - `modules/roles/server.nix:26`
   - `modules/roles/minimal.nix:26`
   - `hosts/laptop/configuration.nix:374`
   - `hosts/desktop/configuration.nix:398`

2. **Package Configuration Sprawl**: The `modules.packages` block is repeated across all 3 host configurations with slight variations, leading to:
   - 100+ lines of near-identical configuration per host
   - Drift risk when adding new packages
   - Unclear which differences are intentional vs accidental

3. **GNOME Configuration Duplication**: `hosts/desktop/gnome.nix` and `hosts/laptop/gnome.nix` share ~80% identical dconf settings with subtle differences buried in the noise.

4. **Excessive `lib.mkForce` Usage**: Found in 14 files, indicating:
   - Option conflicts between modules
   - Unclear precedence/hierarchy
   - Fragile configuration that breaks when refactored

5. **Incomplete Secrets Integration**: sops-nix is imported and configured but not actively used:
   - `modules/secrets/default.nix` defines infrastructure
   - No actual secrets are encrypted/managed
   - WiFi password in `hosts/laptop/configuration.nix:236` is plaintext

6. **Roles vs Profiles Confusion**: Two separate systems exist:
   - `modules/roles/` (desktop.nix, laptop.nix, server.nix, minimal.nix)
   - `modules/profiles/` (only laptop.nix exists)
   - Unclear when to use which, leading to inconsistent patterns

7. **No Remote Deployment**: Current workflow requires SSH + manual `nixos-rebuild`:
   - No colmena, deploy-rs, or similar tooling
   - `flake-modules/outputs.nix` has a deploy script but it's not integrated

8. **Host-Specific Overrides Scattered**: Some host config belongs in modules but lives in host files:
   - Desktop's AMD GPU optimization in `hosts/desktop/configuration.nix:450-462`
   - Server's Proxmox VM config in `hosts/server/configuration.nix:76-94`

---

## 2. Current State Snapshot (Evidence Map)

### Repository Structure

```
~/NixOS/
├── flake.nix                    # Main entry point (flake-parts)
├── flake.lock                   # Pinned inputs
├── flake-modules/
│   ├── hosts.nix                # mkNixosSystem helper, host definitions
│   └── outputs.nix              # perSystem outputs (checks, formatter, devShells)
├── hosts/
│   ├── desktop/
│   │   ├── configuration.nix    # 489 lines - desktop config
│   │   ├── gnome.nix            # 157 lines - GNOME dconf settings
│   │   └── hardware-configuration.nix
│   ├── laptop/
│   │   ├── configuration.nix    # 406 lines - laptop config
│   │   ├── gnome.nix            # 140 lines - GNOME dconf settings
│   │   └── hardware-configuration.nix
│   └── server/
│       ├── configuration.nix    # 282 lines - server config
│       ├── gnome.nix            # GNOME for VM
│       └── hardware-configuration.nix
├── modules/
│   ├── default.nix              # Imports all module categories
│   ├── core/                    # Base system (fonts, pipewire, java, etc.)
│   ├── desktop/gnome/           # GNOME module with extensions
│   ├── dotfiles/                # Chezmoi integration
│   ├── gaming/                  # Steam, gamemode, shader cache
│   ├── gpu/                     # AMD, NVIDIA, Intel, hybrid
│   ├── hardware/                # Hardware-specific modules
│   ├── networking/              # Tailscale, firewall, DNS, WiFi
│   ├── packages/                # Categorical package definitions
│   ├── profiles/                # Only laptop.nix exists
│   ├── roles/                   # desktop, laptop, server, minimal
│   ├── secrets/                 # sops-nix integration (unused)
│   └── services/                # qbittorrent, plex, audiobookshelf, etc.
├── lib/                         # Helper functions (module-helpers, builders)
├── secrets/                     # sops configuration and encrypted files
├── shells/                      # Development environment shells
├── tests/                       # CI checks (formatting, boot-test)
└── user-scripts/                # nixswitch, nix-shell-selector
```

### Host Comparison

| Host    | nixpkgs Input  | GPU        | Role       | Key Features                          |
|---------|----------------|------------|------------|---------------------------------------|
| desktop | unstable       | AMD RX5700 | desktop    | Gaming, Waydroid, full packages       |
| laptop  | stable         | Intel+NVIDIA | laptop   | Battery optimization, X11             |
| server  | stable         | VirtIO-GPU | server     | Plex, qBittorrent, Audiobookshelf     |

### Module Import Graph

```
hosts/<hostname>/configuration.nix
    └── ../../modules (default.nix)
            ├── ./core
            ├── ./packages
            ├── ./networking
            ├── ./desktop
            ├── ./dotfiles
            ├── ./hardware
            ├── ./profiles
            ├── ./services
            ├── ./roles
            ├── ./gpu
            ├── ./secrets
            └── ./gaming
```

### Files with Most `lib.mkForce` Usage

1. `hosts/server/configuration.nix` - 7 occurrences
2. `hosts/desktop/configuration.nix` - 3 occurrences
3. `hosts/laptop/configuration.nix` - 2 occurrences
4. `modules/profiles/laptop.nix` - 2 occurrences

---

## Clarifications

### Session 2026-01-07

- Q: What is the migration blocking threshold for multi-host builds? → A: Test builds (`nix build`) allowed cross-host; `nixos-rebuild switch` only on target machine (never switch one host config while on another - may cause irreversible damage)
- Q: What is the phase migration order across hosts? → A: Complete each phase on desktop (canary) first, then laptop, then server before moving to next phase

---

## 3. Goals / Non-Goals

### Goals

1. **Maximize module reuse**: Shared configuration defined once, host-specific overrides minimized
2. **Clear module hierarchy**: Eliminate roles/profiles confusion, establish single pattern
3. **Safe secrets management**: Implement sops-nix properly, no plaintext secrets
4. **Predictable deployment**: Add remote deploy capability with validation
5. **Reduced `mkForce` usage**: Fix option conflicts at source, not with overrides
6. **Host facts separation**: Hardware-specific values in one place per host
7. **Incremental migration**: Strangler pattern, one subsystem at a time

### Non-Goals

1. **Home Manager adoption**: Explicitly excluded by constraint
2. **Complete rewrite**: Preserve working configuration, migrate incrementally
3. **New hosts**: Focus on existing 3 hosts, not adding new ones
4. **CI/CD infrastructure**: Out of scope (local development focus)
5. **Custom overlays/packages**: Existing overlay approach is sufficient

---

## 4. Target Architecture (Recommended)

### Directory Layout

```
~/NixOS/
├── flake.nix                    # Minimal, delegates to flake-modules/
├── flake.lock
├── flake-modules/
│   ├── hosts.nix                # Host definitions with mkHost helper
│   └── outputs.nix              # perSystem outputs
├── hosts/
│   ├── desktop/
│   │   ├── default.nix          # Host entry: imports hardware + selects profiles
│   │   ├── hardware.nix         # Generated hardware-configuration + host facts
│   │   └── overrides.nix        # Minimal host-specific overrides (if any)
│   ├── laptop/
│   │   └── (same structure)
│   └── server/
│       └── (same structure)
├── profiles/                    # Role-based bundles (NEW - replaces modules/roles + profiles)
│   ├── desktop.nix              # Desktop profile: GNOME, gaming, full packages
│   ├── laptop.nix               # Laptop profile: power management, minimal
│   ├── server.nix               # Server profile: headless services
│   └── common.nix               # Shared across all profiles (user, shell, base tools)
├── modules/                     # Reusable modules (no profile logic)
│   ├── core/                    # Base system modules
│   ├── desktop/                 # Desktop environment modules
│   ├── gaming/                  # Gaming modules
│   ├── gpu/                     # GPU modules
│   ├── hardware/                # Hardware abstraction modules
│   ├── networking/              # Network modules
│   ├── packages/                # Package categories (options-based)
│   ├── secrets/                 # sops-nix integration
│   ├── services/                # Service modules
│   └── shell/                   # Shell configuration
├── lib/                         # Helper functions
│   ├── default.nix
│   ├── mkHost.nix               # Host builder function
│   └── options.nix              # Common option patterns
├── secrets/                     # Encrypted secrets (sops)
│   ├── .sops.yaml               # Key configuration
│   ├── common.yaml              # Shared secrets
│   ├── desktop.yaml             # Desktop-specific secrets
│   ├── laptop.yaml              # Laptop-specific secrets
│   └── server.yaml              # Server-specific secrets
└── (shells/, tests/, user-scripts/ - unchanged)
```

### Module Hierarchy Rules

```
                    ┌─────────────────┐
                    │   hosts/<name>  │
                    │   (entry point) │
                    └────────┬────────┘
                             │ imports
                    ┌────────▼────────┐
                    │    profiles/    │
                    │ (role bundles)  │
                    └────────┬────────┘
                             │ imports
                    ┌────────▼────────┐
                    │    modules/     │
                    │  (reusable)     │
                    └─────────────────┘
```

**Rules:**
- Hosts import profiles + hardware
- Profiles import modules and set defaults
- Modules are stateless, reusable, option-driven
- Modules NEVER import other module categories (no cycles)

### Host Entry Pattern

```nix
# hosts/desktop/default.nix
{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware.nix
    ../../profiles/desktop.nix
  ];

  # Host-specific facts (minimal)
  networking.hostName = "nixos-desktop";

  # Only truly host-specific overrides go here
  boot.kernelPackages = pkgs.linuxPackages_6_6;
}
```

### Profile Pattern

```nix
# profiles/desktop.nix
{ config, lib, pkgs, ... }: {
  imports = [
    ./common.nix
    ../modules/desktop/gnome
    ../modules/gaming
    ../modules/gpu/amd.nix
  ];

  # Profile-level defaults (can be overridden by host)
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = lib.mkDefault true;
    # ... default extensions ...
  };

  modules.packages = {
    browsers.enable = lib.mkDefault true;
    development.enable = lib.mkDefault true;
    gaming.enable = lib.mkDefault true;
    # ...
  };
}
```

### Common Profile Pattern

```nix
# profiles/common.nix
{ config, lib, pkgs, ... }: {
  imports = [
    ../modules/core
    ../modules/networking
    ../modules/shell
    ../modules/secrets
  ];

  # User configuration - SINGLE SOURCE OF TRUTH
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    # Additional groups added by modules via lib.mkAfter
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
```

---

## 5. Conventions & Enforcement

### Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Host directories | lowercase, hyphenated | `hosts/desktop/`, `hosts/my-server/` |
| Profile files | role-based names | `profiles/desktop.nix`, `profiles/server.nix` |
| Module options | `modules.<category>.<subcategory>` | `modules.gaming.steam.enable` |
| Secret files | hostname or `common` | `secrets/desktop.yaml` |

### Module Option Namespaces

```
modules.
├── core.                    # Base system options
├── desktop.gnome.           # GNOME desktop options
├── gaming.                  # Gaming subsystem
│   ├── steam.
│   ├── gamemode.
│   └── mangohud.
├── gpu.                     # GPU configuration
│   ├── amd.
│   ├── nvidia.
│   └── intel.
├── hardware.                # Hardware abstraction
├── networking.              # Network configuration
├── packages.                # Package categories
├── secrets.                 # sops-nix integration
└── services.                # Service modules
```

### Avoiding Copy/Paste Patterns

1. **Use `lib.mkDefault` in profiles**, override in hosts only if needed
2. **Use `lib.mkAfter` for extending lists** (e.g., extraGroups)
3. **Extract common dconf settings** to modules, only host-specific in gnome.nix
4. **Use `lib.optionalAttrs`** instead of duplicating conditional blocks
5. **Never use `lib.mkForce`** unless documenting why (tech debt)

### Formatting & Linting

- **Formatter**: alejandra (already configured)
- **Linter**: statix (already in devShell)
- **Dead code**: deadnix (already in devShell)
- **Pre-commit**: Run `nix flake check` before commits

### Critical Safety Rules

1. **NEVER run `nixos-rebuild switch` for a different host** - Running `switch --flake .#desktop` while on the laptop/server can cause irreversible damage
2. **Test builds are safe cross-host** - `nix build .#nixosConfigurations.<any-host>...` can run anywhere
3. **Validation command**: `nix flake check` validates all hosts safely

### Architecture Review Checklist

Before merging changes:
- [ ] No new `lib.mkForce` without documented reason
- [ ] User config changes go in `profiles/common.nix`, not hosts
- [ ] New modules have options, not hardcoded values
- [ ] Host files < 100 lines (excluding hardware.nix)
- [ ] `nix flake check` passes
- [ ] Secrets are in sops, not plaintext
- [ ] Switch commands only run on matching target host

---

## 6. Secrets Strategy

### Recommendation: sops-nix (Already in Flake)

sops-nix is already imported in `flake.nix` and configured in `modules/secrets/default.nix`. The recommendation is to **complete the implementation**.

### Why sops-nix over agenix

| Feature | sops-nix | agenix |
|---------|----------|--------|
| Already in flake | Yes | No |
| Secret format | YAML (structured) | Plain files |
| Partial encryption | Yes (encrypt only sensitive fields) | No |
| Editor support | Native sops | Requires wrapper |
| Multi-key support | Yes | Yes |
| Home Manager required | No | No |

### Implementation Pattern

```nix
# modules/secrets/default.nix (enhanced)
{ config, lib, inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/${config.networking.hostName}.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # WiFi password (for laptop)
      wifi_password = lib.mkIf (config.networking.hostName == "nixos-laptop") {
        mode = "0400";
      };

      # API tokens (per-host or common)
      tailscale_auth_key = {
        owner = "root";
        mode = "0400";
      };
    };
  };
}
```

### Secret File Structure

```
secrets/
├── .sops.yaml               # Key configuration
│   keys:
│     - &admin age1...       # Admin key (for editing)
│     - &desktop age1...     # Desktop host key
│     - &laptop age1...      # Laptop host key
│     - &server age1...      # Server host key
│   creation_rules:
│     - path_regex: common\.yaml$
│       key_groups:
│         - age: [*admin, *desktop, *laptop, *server]
│     - path_regex: desktop\.yaml$
│       key_groups:
│         - age: [*admin, *desktop]
│     # ... per host rules
├── common.yaml              # Shared secrets (Tailscale key, etc.)
├── desktop.yaml             # Desktop-specific
├── laptop.yaml              # Laptop-specific (WiFi password)
└── server.yaml              # Server-specific (API keys)
```

### Security Guarantees

1. **Secrets never in Nix store**: Decrypted to `/run/secrets/` (tmpfs)
2. **Host isolation**: Each host can only decrypt its own secrets
3. **Rotation**: Update secret file, rebuild, secrets auto-update
4. **Bootstrap**: Use `ssh-to-age` to derive host key from SSH key

---

## 7. Deployment & Ops Workflow

### Current Workflow (Preserved)

```bash
# Local rebuild (existing nixswitch script)
./user-scripts/nixswitch [desktop|laptop|server]

# Manual remote (current pattern)
ssh host "cd ~/NixOS && git pull && sudo nixos-rebuild switch --flake .#hostname"
```

### Recommended Enhancement: colmena (Optional)

colmena provides typed remote deployment without requiring Home Manager:

```nix
# flake.nix addition
outputs = { ... }: {
  colmena = {
    meta = {
      nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      specialArgs = { inherit inputs; };
    };

    defaults = { ... }: {
      imports = [ ./profiles/common.nix ];
    };

    desktop = { ... }: {
      deployment.targetHost = "nixos-desktop";
      imports = [ ./hosts/desktop ];
    };

    # ... other hosts
  };
};
```

```bash
# Deploy single host
colmena apply --on desktop

# Deploy all hosts
colmena apply

# Build without deploying (validation)
colmena build
```

### Upgrade Cadence

1. **Weekly**: Update flake inputs on desktop (canary)
2. **After validation**: Propagate to laptop
3. **Monthly**: Update server (stability-first)

### Rollback Procedure

```bash
# List generations
sudo nixos-rebuild list-generations

# Rollback to previous
sudo nixos-rebuild switch --rollback

# Rollback to specific generation
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation 42
```

---

## 8. Migration Plan (Incremental)

### Migration Order

Each phase must be completed in this order before proceeding to the next phase:

1. **Desktop (canary)** - Primary development machine, issues caught early
2. **Laptop** - Secondary machine, validates portability
3. **Server** - Stability-critical, migrated last

**Important:** Test builds (`nix build`) can validate all hosts from any machine, but `nixos-rebuild switch` must only run on the target machine.

### Phase 0: Baseline (1 commit)

**Goal:** Establish formatting baseline and test infrastructure

**Tasks:**
- Run `alejandra .` to format all files
- Run `statix check .` and fix warnings
- Run `deadnix .` and remove dead code
- Verify `nix flake check` passes
- Commit as "chore: establish formatting baseline"

**Files:** All `.nix` files
**Risk:** Low
**Verification:** `nix flake check`, then `nix build .#nixosConfigurations.<host>...` for all hosts (test builds only - switch only on target machine)
**Rollback:** `git revert`

### Phase 1: Consolidate User Configuration (2-3 commits)

**Goal:** Single source of truth for `users.users.notroot`

**Tasks:**
1. Create `profiles/common.nix` with canonical user definition
2. Remove duplicate user blocks from roles/*.nix
3. Update hosts to use `lib.mkAfter` for extra groups
4. Remove redundant `users.users.notroot` from host configs

**Files:**
- New: `profiles/common.nix`
- Modified: `modules/roles/*.nix`, `hosts/*/configuration.nix`

**Risk:** Medium (user config is critical)
**Verification:** Login works, all groups present, sudo works
**Rollback:** Revert commits, user config is self-contained

### Phase 2: Unify Profiles and Roles (3-4 commits)

**Goal:** Eliminate roles/profiles confusion

**Tasks:**
1. Move `modules/profiles/laptop.nix` to `profiles/laptop.nix`
2. Convert `modules/roles/desktop.nix` to `profiles/desktop.nix`
3. Convert `modules/roles/server.nix` to `profiles/server.nix`
4. Update all host imports to use `profiles/`
5. Delete `modules/roles/` and `modules/profiles/`

**Files:**
- New: `profiles/{desktop,laptop,server}.nix`
- Deleted: `modules/roles/`, `modules/profiles/`
- Modified: `hosts/*/configuration.nix`, `modules/default.nix`

**Risk:** Medium
**Verification:** Each host builds and boots correctly
**Rollback:** Profiles are isolated; revert and restore old structure

### Phase 3: Extract Common Package Defaults (2 commits)

**Goal:** Reduce package configuration duplication

**Tasks:**
1. Define sensible defaults in `profiles/common.nix`
2. Define profile-specific overrides in each profile
3. Reduce host-level package config to only true overrides

**Files:**
- Modified: `profiles/*.nix`, `hosts/*/configuration.nix`

**Risk:** Low (packages are additive)
**Verification:** Expected packages installed on each host
**Rollback:** Restore explicit package lists in hosts

### Phase 4: Consolidate GNOME Configuration (2-3 commits)

**Goal:** Reduce GNOME dconf duplication

**Tasks:**
1. Extract common dconf settings to `modules/desktop/gnome/settings.nix`
2. Keep only GPU/power-specific settings in host gnome.nix
3. Reduce each host's gnome.nix to < 50 lines

**Files:**
- New/Modified: `modules/desktop/gnome/settings.nix`
- Modified: `hosts/*/gnome.nix`

**Risk:** Medium (dconf merging can be tricky)
**Verification:** GNOME boots, extensions work, settings applied
**Rollback:** Restore full gnome.nix files

### Phase 5: Implement Secrets (3-4 commits)

**Goal:** No plaintext secrets, sops-nix fully operational

**Tasks:**
1. Generate host age keys from SSH keys
2. Create `.sops.yaml` with all host keys
3. Encrypt WiFi password in `secrets/laptop.yaml`
4. Update `modules/networking/wifi.nix` to use secret
5. Encrypt any other sensitive values found
6. Test secret rotation

**Files:**
- New: `secrets/*.yaml` (encrypted)
- Modified: `secrets/.sops.yaml`, `modules/secrets/default.nix`, wifi config

**Risk:** High (secrets are critical)
**Verification:**
- WiFi connects on laptop
- `/run/secrets/` contains decrypted secrets
- Secrets not in `/nix/store/`
**Rollback:** Keep plaintext fallback, disable sops for debugging

### Phase 6: Reduce mkForce Usage (2-3 commits)

**Goal:** Fix option conflicts at source

**Tasks:**
1. Audit all `lib.mkForce` usages
2. For each, determine root cause (option conflict vs override)
3. Fix conflicts by using `lib.mkDefault` in modules
4. Remove unnecessary `mkForce`

**Files:** Various (14 files currently)
**Risk:** Medium
**Verification:** No regressions, `nix flake check` passes
**Rollback:** Restore `mkForce` where needed

### Phase 7: Deploy Tooling (Optional, 1-2 commits)

**Goal:** Remote deployment capability

**Tasks:**
1. Add colmena to flake outputs
2. Configure deployment targets
3. Test remote deployment to one host
4. Document workflow

**Files:**
- Modified: `flake.nix`
- New: Deploy documentation

**Risk:** Low (additive, doesn't change builds)
**Verification:** `colmena build` succeeds, `colmena apply` works
**Rollback:** Remove colmena config from flake

---

## 9. Acceptance Criteria (Measurable)

### Code Quality

- [ ] Host configuration files < 100 lines each (excluding hardware)
- [ ] Zero `lib.mkForce` without documented justification comment
- [ ] `nix flake check` passes on all commits
- [ ] No statix warnings
- [ ] No deadnix findings

### Duplication Reduction

- [ ] Single `users.users.notroot` definition (in `profiles/common.nix`)
- [ ] Package defaults defined once in profiles, not per-host
- [ ] GNOME common settings in module, not duplicated

### Secrets

- [ ] No plaintext secrets in repository
- [ ] All secrets decrypt correctly on target hosts
- [ ] Secrets never appear in `/nix/store/`
- [ ] Secret files have correct ownership and mode

### Build & Deploy

- [ ] All 3 hosts build successfully: `nix build .#nixosConfigurations.{desktop,laptop,server}.config.system.build.toplevel`
- [ ] `nixswitch` script works for local builds
- [ ] Rollback procedure documented and tested

### Documentation

- [ ] Migration guide for future architecture changes
- [ ] Secrets management guide (bootstrap, rotation)
- [ ] Module authoring conventions documented

---

## 10. Research Brief

### Sources Consulted

1. **nix.dev Module System Tutorial**
   - URL: https://nix.dev/tutorials/module-system/deep-dive
   - Influence: Module option patterns, mkIf/mkMerge usage, option precedence

2. **NixOS & Flakes Book - Modularization**
   - URL: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration
   - Influence: Directory structure patterns, host/module separation

3. **sops-nix Repository**
   - URL: https://github.com/Mic92/sops-nix
   - Influence: Secrets implementation patterns, per-host scoping

4. **NixOS Wiki - Secret Comparison**
   - URL: https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes
   - Influence: sops-nix vs agenix decision

5. **NixOS Discourse - Secrets Overview**
   - URL: https://discourse.nixos.org/t/handling-secrets-in-nixos-an-overview/35462
   - Influence: Best practices for secrets in multi-host setups

6. **colmena Documentation**
   - URL: https://colmena.cli.rs/
   - Influence: Remote deployment without Home Manager

7. **Community Flake Examples**
   - Various GitHub repos demonstrating multi-host flake patterns
   - Influence: hosts/modules/profiles directory convention

### Key Decisions from Research

| Decision | Rationale |
|----------|-----------|
| Keep sops-nix (already imported) | Lower migration cost than switching to agenix |
| Profiles over roles | Clearer semantics: "what this machine is" vs "what features it has" |
| No NixOps/morph | Too heavyweight for 3 hosts; colmena is simpler |
| Incremental migration | Lower risk than big-bang rewrite |
| No Home Manager | Per user constraint; NixOS modules handle user config |

---

## 11. Open Questions & Resolution Steps

### Q1: Should server remain with GNOME or go headless?

**Current State:** Server has GNOME enabled for Proxmox VM GUI access
**Resolution:** Inspect `hosts/server/configuration.nix` for headless viability
**Decision:** Defer - server GNOME provides value for management

### Q2: How are dotfiles managed without Home Manager?

**Current State:** `modules/dotfiles/` uses chezmoi (external to NixOS)
**Resolution:** This is acceptable - chezmoi is independent of HM
**Decision:** Keep current approach; chezmoi handles mutable dotfiles

### Q3: Should colmena deployment be mandatory?

**Current State:** No remote deploy tooling
**Resolution:** Make it optional (Phase 7)
**Decision:** Add colmena but keep nixswitch as primary local workflow

### Q4: What about per-user secrets (GPG keys, SSH keys)?

**Current State:** Not managed by NixOS
**Resolution:** These are personal credentials, chezmoi can handle
**Decision:** Out of scope for this spec; secrets focus on system-level

### Q5: How to handle stable vs unstable packages per-host?

**Current State:** `flake-modules/hosts.nix` passes `pkgs-unstable` to all hosts
**Resolution:** Current approach is correct; use `lib.mkDefault` for channel selection in profiles
**Decision:** Keep current pattern; document in conventions

---

## Appendix A: Current Duplication Evidence

### User Configuration Locations

```
modules/roles/desktop.nix:35:    users.users.notroot = {
modules/roles/laptop.nix:39:    users.users.notroot = {
modules/roles/server.nix:26:    users.users.notroot = {
modules/roles/minimal.nix:26:    users.users.notroot = {
hosts/laptop/configuration.nix:374:  users.users.notroot = {
hosts/desktop/configuration.nix:398:  users.users.notroot.extraGroups = [
modules/core/java.nix:130:    users.users.notroot.extraGroups = mkIf cfg.androidTools.enable ["adbusers"];
modules/hardware/amd-gpu.nix:152:    users.users.notroot = {
```

### Package Configuration Duplication

Desktop (`hosts/desktop/configuration.nix:111-188`) - 77 lines
Laptop (`hosts/laptop/configuration.nix:78-156`) - 78 lines
Server (`hosts/server/configuration.nix:249-254`) - 5 lines (minimal)

~90% overlap between desktop and laptop package configuration.

### GNOME Configuration Duplication

Common between desktop and laptop gnome.nix:
- Interface settings (color-scheme, fonts, animations)
- Extension enabled list (8/10 shared)
- Privacy settings
- Search settings
- PAM/security configuration
- systemd service disables

Host-specific only:
- Desktop: AMD GPU vars, mutter triple-buffering, gaming apps
- Laptop: Power settings, idle timeout, single display

---

## Appendix B: Module Option Namespace Audit

Current namespaces in use:
- `modules.core.*` - Base system
- `modules.desktop.gnome.*` - GNOME desktop
- `modules.dotfiles.*` - Chezmoi integration
- `modules.gaming.*` - Gaming subsystem
- `modules.gpu.*` - GPU configuration
- `modules.hardware.*` - Hardware modules
- `modules.networking.*` - Network configuration
- `modules.packages.*` - Package categories
- `modules.profiles.*` - (should be removed)
- `modules.roles.*` - (should be removed)
- `modules.secrets.*` - sops-nix
- `modules.services.*` - Service modules

Recommended consolidation:
- Merge `modules.profiles` and `modules.roles` into top-level `profiles/`
- Keep all other namespaces as-is
