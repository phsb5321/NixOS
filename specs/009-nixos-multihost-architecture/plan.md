# Implementation Plan: NixOS Multi-Host Architecture

**Feature ID:** 009-nixos-multihost-architecture
**Branch:** 009-nixos-multihost-architecture
**Spec:** [spec.md](./spec.md)
**Created:** 2026-01-07

---

## Technical Context

### Project Type
- **Type:** NixOS Configuration / Infrastructure as Code
- **Language:** Nix (Nix Expression Language)
- **Framework:** NixOS Flakes with flake-parts

### Key Technologies
| Technology | Purpose | Version/Notes |
|------------|---------|---------------|
| NixOS | Operating system | 25.11 (unstable) / 25.05 (stable) |
| Nix Flakes | Package/config management | Enabled via experimental features |
| flake-parts | Modular flake framework | Current in flake.nix |
| sops-nix | Secrets management | Already in flake inputs (unused) |
| age | Encryption for secrets | Required by sops-nix |
| alejandra | Nix formatter | Already in devShell |
| statix | Nix linter | Already in devShell |
| colmena | Remote deployment (optional) | To be added in Phase 7 |

### Existing Infrastructure
- **Hosts:** desktop (unstable), laptop (stable), server (stable)
- **Current Structure:** flake-parts with mkNixosSystem helper
- **User Management:** Duplicated across 6+ locations (pain point)
- **Secrets:** sops-nix imported but not actively used
- **Deployment:** Local nixswitch script, no remote tooling

### Dependencies
| Dependency | Status | Notes |
|------------|--------|-------|
| sops-nix | In flake | Needs implementation |
| age keys | Missing | Need to generate per-host |
| colmena | Not present | Optional Phase 7 |

### Unknowns (Resolved)
All technical unknowns were resolved in the spec:
- Cross-host safety: Test builds allowed, switch only on target
- Migration order: Desktop → Laptop → Server per phase
- Secrets tool: sops-nix (already imported)
- Deployment tool: colmena (optional)

---

## Constitution Check

### Principle 1: Desktop Host Feature Priorities
| Priority Feature | Impact | Mitigation |
|------------------|--------|------------|
| Waydroid | No impact - architecture change doesn't touch Waydroid config | Verify `virtualisation.waydroid.enable = true` after Phase 2 |

**Compliance:** PASS - Waydroid configuration preserved in all phases

### Principle 2: Host Isolation
| Rule | Compliance | Notes |
|------|------------|-------|
| Never deploy desktop to server | PASS | Spec adds explicit safety rules |
| Never deploy server to desktop | PASS | Migration order ensures isolation |
| Host-specific in host files | PASS | Target architecture reduces host files to <100 lines |

**Compliance:** PASS - Spec explicitly reinforces host isolation with safety rules

### Principle 3: Modular Architecture
| Rule | Compliance | Notes |
|------|------------|-------|
| New features as modules | PASS | No new features, refactoring existing |
| Host-specific overrides in hosts/ | PASS | Target structure improves this |
| DRY principle | PASS | Primary goal is reducing duplication |

**Compliance:** PASS - Spec directly improves modular architecture

### Principle 4: Wayland-First for Desktop
| Rule | Compliance | Notes |
|------|------------|-------|
| Desktop uses Wayland | PASS | No change to Wayland config |
| Waydroid supported | PASS | Wayland dependency preserved |

**Compliance:** PASS - No impact on Wayland configuration

### Gate Evaluation
- **All principles:** PASS
- **Blocking violations:** None
- **Proceed:** YES

---

## Phase 0: Research Summary

### Research Tasks Completed

#### R1: NixOS Module Patterns (Best Practices)

**Decision:** Use `lib.mkDefault` in profiles, `lib.mkAfter` for extending lists, avoid `lib.mkForce`

**Rationale:**
- `mkDefault` allows hosts to override without force
- `mkAfter` enables additive modifications (e.g., extraGroups)
- `mkForce` indicates architecture problems, not solutions

**Sources:**
- nix.dev module system tutorial
- NixOS & Flakes Book
- Existing codebase patterns

#### R2: Secrets Management (sops-nix Implementation)

**Decision:** Complete existing sops-nix integration

**Rationale:**
- Already in flake inputs (zero migration cost)
- YAML format allows partial encryption
- Per-host scoping via .sops.yaml creation_rules
- Secrets decrypted to /run/secrets/ (tmpfs, never in store)

**Implementation Pattern:**
```nix
sops = {
  defaultSopsFile = ../../secrets/${config.networking.hostName}.yaml;
  age.keyFile = "/var/lib/sops-nix/key.txt";
  secrets.wifi_password = { mode = "0400"; };
};
```

**Bootstrap:** Use `ssh-to-age` to derive host key from SSH host key

#### R3: Profile/Role Consolidation

**Decision:** Move to top-level `profiles/` directory, eliminate `modules/roles/` and `modules/profiles/`

**Rationale:**
- Clear hierarchy: hosts → profiles → modules
- Eliminates confusion between two overlapping systems
- Profiles are "what this machine is", modules are "reusable components"

**Directory Change:**
```
Before: modules/roles/, modules/profiles/
After: profiles/ (top-level)
```

#### R4: Remote Deployment (Optional)

**Decision:** Add colmena as optional enhancement in Phase 7

**Rationale:**
- Does not require Home Manager
- Type-safe deployment with validation
- Can coexist with existing nixswitch workflow

**Alternatives Considered:**
- deploy-rs: More complex, less documentation
- NixOps: Too heavyweight for 3 hosts
- Manual SSH: Current approach, preserved as fallback

---

## Phase 1: Design Artifacts

### Data Model

For this architecture refactoring, the "data model" is the **module option namespace structure** and **file organization**.

#### Entity: Host Configuration

| Field | Type | Description |
|-------|------|-------------|
| hostname | string | Network hostname (e.g., "nixos-desktop") |
| profile | enum | desktop \| laptop \| server |
| nixpkgsInput | flake input | stable \| unstable |
| hardware | path | Path to hardware-configuration.nix |
| overrides | attrset | Host-specific option overrides |

#### Entity: Profile

| Field | Type | Description |
|-------|------|-------------|
| name | string | Profile identifier |
| imports | list[path] | Modules this profile enables |
| defaults | attrset | Default option values (mkDefault) |
| packages | attrset | Package category enables |

#### Entity: Secret

| Field | Type | Description |
|-------|------|-------------|
| name | string | Secret identifier |
| scope | enum | common \| per-host |
| owner | string | Unix user owner |
| mode | string | File permissions |
| path | path | /run/secrets/{name} |

#### State Transitions

```
Migration Phase States:
┌─────────┐     ┌──────────┐     ┌──────────┐
│ Pending │ ──▶ │ Desktop  │ ──▶ │ Laptop   │ ──▶ ┌──────────┐
└─────────┘     │ Complete │     │ Complete │     │ Server   │
                └──────────┘     └──────────┘     │ Complete │
                                                  └──────────┘
                                                       │
                                                       ▼
                                               ┌──────────────┐
                                               │ Phase Done   │
                                               └──────────────┘
```

### Contracts (Module Option Interfaces)

Since this is NixOS configuration (not an API), "contracts" are the module option interfaces.

#### profiles/common.nix Interface

```nix
# Provides: Single source of truth for user configuration
# Imports: modules/core, modules/networking, modules/shell, modules/secrets
# Sets:
#   users.users.notroot = { ... }
#   programs.zsh.enable = true
#   users.defaultUserShell = pkgs.zsh
```

#### profiles/desktop.nix Interface

```nix
# Provides: Desktop workstation configuration
# Imports: profiles/common.nix, modules/desktop/gnome, modules/gaming, modules/gpu/amd
# Sets (with mkDefault):
#   modules.desktop.gnome.enable = true
#   modules.desktop.gnome.wayland.enable = true
#   modules.packages.gaming.enable = true
#   modules.packages.development.enable = true
```

#### profiles/laptop.nix Interface

```nix
# Provides: Laptop configuration with power management
# Imports: profiles/common.nix, modules/desktop/gnome, modules/hardware/laptop
# Sets (with mkDefault):
#   modules.desktop.gnome.enable = true
#   modules.desktop.gnome.wayland.enable = false  # X11 for Intel/NVIDIA
#   modules.packages.gaming.enable = true
#   boot.kernel.sysctl."vm.laptop_mode" = 5
#   zramSwap.enable = true
```

#### profiles/server.nix Interface

```nix
# Provides: Server configuration for services
# Imports: profiles/common.nix, modules/services/*
# Sets (with mkDefault):
#   modules.services.qbittorrent.enable = true
#   modules.services.plex.enable = true
#   hardware.graphics.enable = false  # Headless
```

#### modules/secrets/default.nix Interface

```nix
# Options:
#   modules.secrets.enable : bool (default: false)
#   modules.secrets.defaultSopsFile : path (auto from hostname)
#   modules.secrets.ageKeyFile : path (default: /var/lib/sops-nix/key.txt)
#
# Provides:
#   sops.secrets.<name>.path : /run/secrets/<name>
#   Secrets NEVER in /nix/store
```

---

## Implementation Tasks

### Phase 0: Baseline

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T0.1 | Run alejandra formatter on all .nix files | All *.nix | Low | 1 |
| T0.2 | Run statix and fix warnings | Various | Low | 1 |
| T0.3 | Run deadnix and remove dead code | Various | Low | 1 |
| T0.4 | Verify nix flake check passes | - | Low | 0 |
| T0.5 | Test build all hosts (no switch) | - | Low | 0 |

**Verification:** `nix flake check` + `nix build .#nixosConfigurations.<host>...` for all 3 hosts
**Rollback:** `git revert`

### Phase 1: Consolidate User Configuration

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T1.1 | Create profiles/common.nix with canonical user definition | NEW: profiles/common.nix | Medium | 1 |
| T1.2 | Update modules/roles/desktop.nix to import common, remove user block | modules/roles/desktop.nix | Medium | 1 |
| T1.3 | Update modules/roles/laptop.nix to import common, remove user block | modules/roles/laptop.nix | Medium | 1 |
| T1.4 | Update modules/roles/server.nix to import common, remove user block | modules/roles/server.nix | Medium | 1 |
| T1.5 | Update hosts to use lib.mkAfter for extra groups | hosts/*/configuration.nix | Medium | 1 |
| T1.6 | Verify login, sudo, and groups work on desktop | - | Critical | 0 |

**Migration Order:** Desktop → Laptop → Server
**Verification:** Login works, all groups present, sudo works
**Rollback:** Revert commits

### Phase 2: Unify Profiles and Roles

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T2.1 | Create profiles/desktop.nix from roles/desktop.nix | NEW: profiles/desktop.nix | Medium | 1 |
| T2.2 | Create profiles/laptop.nix combining roles + profiles | NEW: profiles/laptop.nix | Medium | 1 |
| T2.3 | Create profiles/server.nix from roles/server.nix | NEW: profiles/server.nix | Medium | 1 |
| T2.4 | Update host imports to use profiles/ | hosts/*/configuration.nix | Medium | 1 |
| T2.5 | Remove modules/roles/ directory | DELETE: modules/roles/ | Medium | 1 |
| T2.6 | Remove modules/profiles/ directory | DELETE: modules/profiles/ | Medium | 1 |
| T2.7 | Update modules/default.nix to remove roles/profiles imports | modules/default.nix | Low | 1 |

**Migration Order:** Desktop → Laptop → Server
**Verification:** Each host builds and boots
**Rollback:** Revert and restore old structure

### Phase 3: Extract Common Package Defaults

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T3.1 | Add package defaults to profiles/common.nix | profiles/common.nix | Low | 1 |
| T3.2 | Add profile-specific packages to profiles/*.nix | profiles/*.nix | Low | 1 |
| T3.3 | Reduce hosts/desktop/configuration.nix package block | hosts/desktop/configuration.nix | Low | 1 |
| T3.4 | Reduce hosts/laptop/configuration.nix package block | hosts/laptop/configuration.nix | Low | 1 |

**Migration Order:** Desktop → Laptop → Server
**Verification:** Expected packages installed
**Rollback:** Restore explicit package lists

### Phase 4: Consolidate GNOME Configuration

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T4.1 | Create modules/desktop/gnome/settings.nix with common dconf | NEW: modules/desktop/gnome/settings.nix | Medium | 1 |
| T4.2 | Update modules/desktop/gnome/default.nix to import settings | modules/desktop/gnome/default.nix | Low | 1 |
| T4.3 | Reduce hosts/desktop/gnome.nix to host-specific only | hosts/desktop/gnome.nix | Medium | 1 |
| T4.4 | Reduce hosts/laptop/gnome.nix to host-specific only | hosts/laptop/gnome.nix | Medium | 1 |
| T4.5 | Verify GNOME boots with correct settings on desktop | - | Critical | 0 |

**Migration Order:** Desktop → Laptop → Server
**Verification:** GNOME boots, extensions work, settings applied
**Rollback:** Restore full gnome.nix files

### Phase 5: Implement Secrets

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T5.1 | Generate age key from SSH host key on each host | /var/lib/sops-nix/key.txt | High | 0 |
| T5.2 | Update secrets/.sops.yaml with all host public keys | secrets/.sops.yaml | High | 1 |
| T5.3 | Create secrets/laptop.yaml with encrypted WiFi password | NEW: secrets/laptop.yaml | High | 1 |
| T5.4 | Create secrets/common.yaml for shared secrets | NEW: secrets/common.yaml | Medium | 1 |
| T5.5 | Update modules/secrets/default.nix to declare secrets | modules/secrets/default.nix | High | 1 |
| T5.6 | Update modules/networking/wifi.nix to use sops secret | modules/networking/wifi.nix | High | 1 |
| T5.7 | Enable modules.secrets in profiles/common.nix | profiles/common.nix | Medium | 1 |
| T5.8 | Remove plaintext WiFi password from config | hosts/laptop/configuration.nix | High | 1 |
| T5.9 | Verify WiFi connects on laptop using secret | - | Critical | 0 |
| T5.10 | Verify /run/secrets/ contains decrypted secret | - | Critical | 0 |
| T5.11 | Verify secret NOT in /nix/store | - | Critical | 0 |

**Migration Order:** Desktop → Laptop → Server (secrets bootstrap per-host)
**Verification:** WiFi connects, secrets in /run/secrets/, not in /nix/store
**Rollback:** Keep plaintext fallback, disable sops

### Phase 6: Reduce mkForce Usage

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T6.1 | Audit all lib.mkForce usages (14 files) | Various | Low | 0 |
| T6.2 | Fix server/configuration.nix mkForce (7 occurrences) | hosts/server/configuration.nix | Medium | 1 |
| T6.3 | Fix desktop/configuration.nix mkForce (3 occurrences) | hosts/desktop/configuration.nix | Medium | 1 |
| T6.4 | Fix laptop/configuration.nix mkForce (2 occurrences) | hosts/laptop/configuration.nix | Medium | 1 |
| T6.5 | Fix profiles/laptop.nix mkForce (2 occurrences) | profiles/laptop.nix | Medium | 1 |
| T6.6 | Document remaining mkForce with justification comments | Various | Low | 1 |

**Migration Order:** Desktop → Laptop → Server
**Verification:** No regressions, nix flake check passes
**Rollback:** Restore mkForce where needed

### Phase 7: Deploy Tooling (Optional)

| Task ID | Description | Files | Risk | Est. Commits |
|---------|-------------|-------|------|--------------|
| T7.1 | Add colmena to flake inputs | flake.nix | Low | 1 |
| T7.2 | Add colmena configuration to flake outputs | flake.nix | Low | 1 |
| T7.3 | Test colmena build for all hosts | - | Low | 0 |
| T7.4 | Test colmena apply to one host | - | Medium | 0 |
| T7.5 | Document colmena workflow | docs/ or README | Low | 1 |

**Migration Order:** Desktop first (local test), then validate remote to laptop/server
**Verification:** colmena build succeeds, colmena apply works
**Rollback:** Remove colmena config from flake

---

## Quickstart

### Prerequisites

1. On each host, generate age key from SSH host key:
   ```bash
   sudo mkdir -p /var/lib/sops-nix
   sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -o /var/lib/sops-nix/key.txt
   sudo chmod 600 /var/lib/sops-nix/key.txt
   ```

2. Get public key for .sops.yaml:
   ```bash
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

### Development Workflow

```bash
# 1. Enter dev shell
nix develop

# 2. Format code
alejandra .

# 3. Check for issues
statix check .
deadnix .

# 4. Validate all hosts (safe from any machine)
nix flake check

# 5. Test build specific host (safe from any machine)
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# 6. Switch (ONLY on target machine!)
sudo nixos-rebuild switch --flake .#desktop
```

### Secret Management

```bash
# Edit secrets (requires your age key in ~/.config/sops/age/keys.txt)
sops secrets/laptop.yaml

# View decrypted secrets
sops -d secrets/laptop.yaml

# Rotate keys after adding new host
sops updatekeys secrets/laptop.yaml
```

### Verification Commands

```bash
# Check if secrets are in /run/secrets/ (not /nix/store)
ls -la /run/secrets/

# Verify secret not in nix store
grep -r "wifi_password" /nix/store/ 2>/dev/null | head -5  # Should be empty

# Check user groups
groups notroot
```

---

## Risk Matrix

| Phase | Risk Level | Impact | Mitigation |
|-------|------------|--------|------------|
| 0 | Low | Formatting only | Git revert |
| 1 | Medium | User login | Test immediately, revert if broken |
| 2 | Medium | Boot failure | Test builds before switch |
| 3 | Low | Missing packages | Additive, easily fixed |
| 4 | Medium | GNOME broken | Keep backup gnome.nix |
| 5 | High | WiFi broken, secrets exposed | Keep plaintext fallback |
| 6 | Medium | Config broken | Restore mkForce |
| 7 | Low | Additive feature | Remove colmena if issues |

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Host config lines | < 100 each | `wc -l hosts/*/configuration.nix` |
| mkForce count | 0 undocumented | `grep -r "mkForce" \| wc -l` |
| User definitions | 1 (in common.nix) | `grep -r "users.users.notroot" \| wc -l` |
| Plaintext secrets | 0 | `grep -rE "(password|secret|key)\s*=" hosts/ modules/` |
| Flake check | Pass | `nix flake check` |
| All hosts build | Pass | `nix build .#nixosConfigurations.{desktop,laptop,server}...` |

---

## Appendix: File Change Summary

### New Files
- `profiles/common.nix`
- `profiles/desktop.nix`
- `profiles/laptop.nix`
- `profiles/server.nix`
- `modules/desktop/gnome/settings.nix`
- `secrets/common.yaml`
- `secrets/desktop.yaml`
- `secrets/laptop.yaml`
- `secrets/server.yaml`

### Deleted Files
- `modules/roles/desktop.nix`
- `modules/roles/laptop.nix`
- `modules/roles/server.nix`
- `modules/roles/minimal.nix`
- `modules/roles/default.nix`
- `modules/profiles/laptop.nix`
- `modules/profiles/default.nix`

### Modified Files
- `flake.nix` (Phase 7 only)
- `modules/default.nix`
- `modules/secrets/default.nix`
- `modules/networking/wifi.nix`
- `modules/desktop/gnome/default.nix`
- `hosts/desktop/configuration.nix`
- `hosts/desktop/gnome.nix`
- `hosts/laptop/configuration.nix`
- `hosts/laptop/gnome.nix`
- `hosts/server/configuration.nix`
- `secrets/.sops.yaml`
