# Tasks: NixOS Multi-Host Architecture

**Feature ID:** 009-nixos-multihost-architecture
**Generated:** 2026-01-07
**Total Tasks:** 92
**Phases:** 8 (including Setup and Polish)

---

## Migration Order (Per Phase)

Each phase must be completed on all hosts in this order before moving to the next phase:

1. **Desktop (canary)** - Primary development machine
2. **Laptop** - Secondary machine, validates portability
3. **Server** - Stability-critical, migrated last

**Critical Safety Rule:** `nixos-rebuild switch` ONLY on target machine. Test builds (`nix build`) are safe cross-host.

---

## Phase 1: Setup & Baseline

**Goal:** Establish clean formatting baseline and verify all hosts build

### Tasks

- [x] T001 Run alejandra formatter on all .nix files in repository root
- [x] T002 Run statix linter and fix all warnings in *.nix files
- [x] T003 Run deadnix and remove all dead code in *.nix files
- [x] T004 Verify `nix flake check` passes with no errors
- [x] T005 [P] Test build desktop: `nix build .#nixosConfigurations.desktop.config.system.build.toplevel`
- [x] T006 [P] Test build laptop: `nix build .#nixosConfigurations.laptop.config.system.build.toplevel`
- [x] T007 [P] Test build server: `nix build .#nixosConfigurations.server.config.system.build.toplevel`
- [x] T008 Commit as "chore: establish formatting baseline"

**Verification:** All 3 hosts build successfully
**Rollback:** `git revert`

---

## Phase 2: Consolidate User Configuration

**Goal:** Single source of truth for `users.users.notroot` in `profiles/common.nix`

### Independent Test Criteria
- Login works on all hosts
- All user groups present (check with `groups notroot`)
- Sudo works without errors
- Waydroid still enabled on desktop (constitution check)

### Tasks

- [x] T009 Create profiles/ directory at repository root
- [x] T010 Create profiles/common.nix with canonical user definition (users.users.notroot, zsh, defaultUserShell)
- [x] T011 Update modules/roles/desktop.nix to import ../../profiles/common.nix and remove users.users.notroot block
- [x] T012 Update modules/roles/laptop.nix to import ../../profiles/common.nix and remove users.users.notroot block
- [x] T013 Update modules/roles/server.nix to import ../../profiles/common.nix and remove users.users.notroot block
- [x] T014 Update modules/roles/minimal.nix to import ../../profiles/common.nix and remove users.users.notroot block
- [x] T015 Update hosts/desktop/configuration.nix to use lib.mkAfter for extraGroups instead of direct assignment
- [x] T016 Update hosts/laptop/configuration.nix to use lib.mkAfter for extraGroups and remove users.users.notroot block
- [x] T017 Update modules/core/java.nix to use lib.mkAfter for extraGroups (line 130)
- [x] T018 Update modules/hardware/amd-gpu.nix to use lib.mkAfter for extraGroups (line 152)
- [x] T019 [P] Test build all hosts after user consolidation
- [ ] T020 Switch on desktop and verify: login, groups, sudo, Waydroid enabled
- [ ] T021 Switch on laptop and verify: login, groups, sudo
- [ ] T022 Switch on server and verify: login, groups, sudo

**Verification:** `grep -r "users.users.notroot" | wc -l` shows 1 definition
**Rollback:** Revert commits

---

## Phase 3: Unify Profiles and Roles

**Goal:** Eliminate modules/roles/ and modules/profiles/, consolidate to top-level profiles/

### Independent Test Criteria
- Each host builds and boots correctly
- All modules still load properly
- No missing imports or broken references

### Tasks

- [ ] T023 Create profiles/desktop.nix from modules/roles/desktop.nix (import common.nix, keep module enables)
- [ ] T024 Create profiles/laptop.nix combining modules/roles/laptop.nix and modules/profiles/laptop.nix
- [ ] T025 Create profiles/server.nix from modules/roles/server.nix
- [ ] T026 Update hosts/desktop/configuration.nix to import ../../profiles/desktop.nix instead of roles
- [ ] T027 Update hosts/laptop/configuration.nix to import ../../profiles/laptop.nix instead of roles
- [ ] T028 Update hosts/server/configuration.nix to import ../../profiles/server.nix instead of roles
- [ ] T029 Update modules/default.nix to remove imports of ./roles and ./profiles directories
- [ ] T030 [P] Test build all hosts after profile migration
- [ ] T031 Switch on desktop and verify boot and functionality
- [ ] T032 Switch on laptop and verify boot and functionality
- [ ] T033 Switch on server and verify boot and functionality
- [ ] T034 Delete modules/roles/ directory (desktop.nix, laptop.nix, server.nix, minimal.nix, default.nix)
- [ ] T035 Delete modules/profiles/ directory (laptop.nix, default.nix)

**Verification:** `ls modules/roles modules/profiles` returns "No such file"
**Rollback:** Restore from git

---

## Phase 4: Extract Common Package Defaults

**Goal:** Reduce package configuration duplication across hosts

### Independent Test Criteria
- Expected packages installed on each host
- No missing packages compared to current state
- Host-specific packages still present

### Tasks

- [ ] T036 Add common package category defaults to profiles/common.nix (browsers, development, utilities)
- [ ] T037 Add desktop-specific package enables to profiles/desktop.nix (gaming, media, audioVideo)
- [ ] T038 Add laptop-specific package enables to profiles/laptop.nix (with power-conscious defaults)
- [ ] T039 Reduce hosts/desktop/configuration.nix modules.packages block to only true overrides
- [ ] T040 Reduce hosts/laptop/configuration.nix modules.packages block to only true overrides
- [ ] T041 [P] Test build all hosts after package consolidation
- [ ] T042 Switch on desktop and verify all expected packages installed
- [ ] T043 Switch on laptop and verify all expected packages installed

**Verification:** Package count matches or exceeds previous
**Rollback:** Restore explicit package lists

---

## Phase 5: Consolidate GNOME Configuration

**Goal:** Extract common GNOME dconf settings to module, reduce host gnome.nix to <50 lines

### Independent Test Criteria
- GNOME boots on desktop and laptop
- All extensions load and work
- Correct settings applied (dark mode, fonts, etc.)
- AMD GPU optimizations preserved on desktop
- Power settings preserved on laptop

### Tasks

- [ ] T044 Create modules/desktop/gnome/settings.nix with common dconf settings (interface, privacy, search, PAM)
- [ ] T045 Update modules/desktop/gnome/default.nix to import ./settings.nix
- [ ] T046 Reduce hosts/desktop/gnome.nix to AMD GPU-specific settings only (mutter, session vars); verify `wc -l hosts/desktop/gnome.nix` < 50
- [ ] T047 Reduce hosts/laptop/gnome.nix to power/battery-specific settings only (idle, sleep); verify `wc -l hosts/laptop/gnome.nix` < 50
- [ ] T048 [P] Test build desktop and laptop after GNOME consolidation
- [ ] T049 Switch on desktop and verify: GNOME boots, extensions work, AMD GPU settings applied
- [ ] T050 Switch on laptop and verify: GNOME boots, extensions work, power settings applied

**Verification:** `wc -l hosts/*/gnome.nix` shows <50 lines each
**Rollback:** Restore full gnome.nix files from git

---

## Phase 6: Implement Secrets (sops-nix)

**Goal:** No plaintext secrets, sops-nix fully operational

### Independent Test Criteria
- WiFi connects on laptop using encrypted secret
- Secrets in /run/secrets/ (tmpfs)
- Secrets NOT in /nix/store/
- Each host can only decrypt its own secrets

### Tasks

- [ ] T051 Generate age key from SSH host key on desktop: `sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -o /var/lib/sops-nix/key.txt`
- [ ] T052 Generate age key from SSH host key on laptop (same command, run on laptop)
- [ ] T053 Generate age key from SSH host key on server (same command, run on server)
- [ ] T054 Get public keys from each host: `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`
- [ ] T055 Update secrets/.sops.yaml with all host public keys and creation_rules
- [ ] T056 Create secrets/laptop.yaml with encrypted WiFi password using sops
- [ ] T057 Create secrets/common.yaml for shared secrets (placeholder or Tailscale key)
- [ ] T058 Update modules/secrets/default.nix to declare sops.secrets for wifi_password
- [ ] T059 Update modules/networking/wifi.nix to read WiFi password from /run/secrets/wifi_password
- [ ] T060 Enable modules.secrets in profiles/common.nix
- [ ] T061 Remove plaintext WiFi password from hosts/laptop/configuration.nix
- [ ] T062 [P] Test build all hosts after secrets integration
- [ ] T063 Switch on laptop and verify WiFi connects using secret
- [ ] T064 Verify /run/secrets/wifi_password exists with correct permissions on laptop
- [ ] T065 Verify secret NOT in /nix/store: `grep -r "wifi_password_value" /nix/store/ | head -5` returns empty

**Verification:** WiFi works, secrets in /run/secrets/, not in store
**Rollback:** Keep plaintext WiFi as commented fallback, disable sops

---

## Phase 7: Reduce mkForce Usage

**Goal:** Fix option conflicts at source, eliminate unnecessary mkForce

### Independent Test Criteria
- No regressions in functionality
- `nix flake check` passes
- All remaining mkForce have justification comments

### Tasks

- [ ] T066 Audit all lib.mkForce usages: `grep -rn "mkForce" --include="*.nix"`
- [ ] T067 Analyze hosts/server/configuration.nix mkForce (7 occurrences) - determine root cause
- [ ] T068 Fix server mkForce by adding lib.mkDefault in source modules
- [ ] T069 Analyze hosts/desktop/configuration.nix mkForce (3 occurrences) - determine root cause
- [ ] T070 Fix desktop mkForce by adding lib.mkDefault in source modules
- [ ] T071 Analyze hosts/laptop/configuration.nix mkForce (2 occurrences) - determine root cause
- [ ] T072 Fix laptop mkForce by adding lib.mkDefault in source modules
- [ ] T073 Analyze profiles/laptop.nix mkForce (2 occurrences) - determine root cause
- [ ] T074 Fix profiles/laptop.nix mkForce by restructuring option precedence
- [ ] T075 Add justification comments to any remaining necessary mkForce
- [ ] T076 [P] Test build all hosts after mkForce reduction
- [ ] T077 Switch on desktop and verify no regressions
- [ ] T078 Switch on laptop and verify no regressions
- [ ] T079 Switch on server and verify no regressions

**Verification:** `grep -r "mkForce" | grep -v "# JUSTIFIED:"` returns 0 undocumented
**Rollback:** Restore mkForce where needed

---

## Phase 8: Deploy Tooling (Optional)

**Goal:** Add colmena for remote deployment capability

### Independent Test Criteria
- colmena build succeeds for all hosts
- colmena apply works to at least one host
- Existing nixswitch workflow still works

### Tasks

- [ ] T080 Add colmena to flake inputs in flake.nix
- [ ] T081 Add colmena configuration to flake outputs with host definitions
- [ ] T082 Test colmena build for all hosts: `colmena build`
- [ ] T083 Test colmena apply to desktop (local): `colmena apply --on desktop`
- [ ] T084 Document colmena workflow in docs/DEPLOYMENT.md or README

**Verification:** `colmena build` succeeds, `colmena apply` works
**Rollback:** Remove colmena from flake.nix

---

## Phase 9: Polish & Documentation

**Goal:** Final cleanup, documentation, and acceptance criteria verification

### Tasks

- [ ] T085 Verify host config lines < 100: `wc -l hosts/*/configuration.nix`
- [ ] T086 Verify single user definition: `grep -r "users.users.notroot" | wc -l` equals 1
- [ ] T087 Verify no plaintext secrets: `grep -rE "(password|secret|key)\s*=" hosts/ modules/ | grep -v sops`
- [ ] T088 Verify Waydroid still enabled on desktop (constitution requirement)
- [ ] T089 Document secrets management (bootstrap, rotation) in docs/SECRETS.md
- [ ] T090 Document module authoring conventions in docs/MODULE_CONVENTIONS.md
- [ ] T091 Run final `nix flake check` and `statix check .` to verify no regressions
- [ ] T092 Create git tag for architecture milestone

**Verification:** All acceptance criteria from spec.md pass
**Rollback:** N/A (documentation only)

---

## Dependencies

```
Phase 1 (Setup) ──────────────────────────────────────────────────────────┐
                                                                          │
Phase 2 (User Config) ◄───────────────────────────────────────────────────┘
    │
    ▼
Phase 3 (Profiles) ◄── Depends on Phase 2 (common.nix must exist)
    │
    ├───────────────────┐
    ▼                   ▼
Phase 4 (Packages)   Phase 5 (GNOME)  ◄── Can run in parallel
    │                   │
    └───────┬───────────┘
            ▼
Phase 6 (Secrets) ◄── Depends on profiles structure
    │
    ▼
Phase 7 (mkForce) ◄── Should run after main refactoring complete
    │
    ▼
Phase 8 (Deploy) ◄── Optional, can run after Phase 3
    │
    ▼
Phase 9 (Polish) ◄── Final phase, depends on all above
```

---

## Parallel Execution Opportunities

### Phase 1: Setup
- T005, T006, T007 can run in parallel (independent host builds)

### Phase 3: Profiles
- T023, T024, T025 can run in parallel (independent profile creation)

### Phase 4 & 5: Can Run in Parallel
- Phase 4 (packages) and Phase 5 (GNOME) have no dependencies on each other

### Phase 7: mkForce
- Analysis tasks (T067, T069, T071, T073) can run in parallel
- Fix tasks must be sequential (each depends on analysis)

---

## Task Count Summary

| Phase | Description | Task Count | Parallelizable |
|-------|-------------|------------|----------------|
| 1 | Setup & Baseline | 8 | 3 |
| 2 | User Configuration | 14 | 1 |
| 3 | Profiles & Roles | 13 | 4 |
| 4 | Package Defaults | 8 | 1 |
| 5 | GNOME Config | 7 | 1 |
| 6 | Secrets (sops-nix) | 15 | 1 |
| 7 | mkForce Reduction | 14 | 4 |
| 8 | Deploy Tooling | 5 | 0 |
| 9 | Polish & Docs | 8 | 0 |
| **Total** | | **92** | **15** |

---

## MVP Scope (Recommended First Implementation)

For minimal viable improvement, complete **Phases 1-3** first:

1. **Phase 1:** Establish clean baseline
2. **Phase 2:** Single source of truth for user config (biggest pain point)
3. **Phase 3:** Unified profiles structure

This addresses the core architectural issues (duplication, roles/profiles confusion) with moderate risk and provides immediate value.

**Phases 4-9** can be implemented incrementally afterward.

---

## Risk Summary

| Phase | Risk | Mitigation |
|-------|------|------------|
| 1 | Low | Formatting only, git revert |
| 2 | Medium | Test login immediately after switch |
| 3 | Medium | Keep old structure in git history |
| 4 | Low | Packages are additive |
| 5 | Medium | Keep backup gnome.nix |
| 6 | High | Plaintext fallback, test on laptop first |
| 7 | Medium | Restore mkForce if needed |
| 8 | Low | Optional, additive only |
| 9 | Low | Documentation only |
