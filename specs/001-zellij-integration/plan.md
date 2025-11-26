# Implementation Plan: Zellij Terminal Multiplexer Integration

**Branch**: `001-zellij-integration` | **Date**: 2025-11-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-zellij-integration/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature integrates Zellij terminal multiplexer into the NixOS configuration as a core package with optimized configuration and custom layouts. The implementation follows the NixOS modular architecture, adds Zellij to the packages module, creates KDL-based configuration files managed through chezmoi dotfiles, and provides example layouts for common development workflows. The technical approach leverages NixOS declarative package management for system-level installation and chezmoi for user-space configuration that can be updated independently of system rebuilds.

## Technical Context

**Language/Version**: Nix (NixOS configuration), KDL (Zellij config format v0.32.0+)
**Primary Dependencies**:
- Zellij package from nixpkgs (stable or unstable)
- Chezmoi for dotfiles management
- NixOS module system
**Storage**: File-based configuration in XDG-compliant directories (`~/.config/zellij/`)
**Testing**:
- `nix flake check` for NixOS config validation
- `nixos-rebuild build` for system build verification
- `zellij setup --check` for KDL config validation
- Manual verification of session persistence and keybindings
**Target Platform**: NixOS 25.11+ on desktop (host/default) and laptop (host/laptop) configurations
**Project Type**: System configuration (NixOS modules + dotfiles)
**Performance Goals**:
- Zellij launch time <1 second
- Session attachment <500ms
- Layout loading <2 seconds
**Constraints**:
- Must work on both AMD GPU (desktop) and Intel/NVIDIA (laptop)
- Configuration must survive chezmoi reapplication
- Changes must not require NixOS rebuild (dotfiles only)
- Must maintain compatibility with existing terminal setup
**Scale/Scope**:
- 2 hosts (desktop + laptop)
- 1 core config.kdl file
- 3+ layout templates
- ~10 documented keybindings

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Safety-First Rebuilds (NON-NEGOTIABLE)

✅ **COMPLIANT** - All NixOS rebuild operations will only occur on `host/default` branch. Dotfiles changes via chezmoi do not require rebuilds and can be tested immediately. Implementation plan explicitly documents the safe workflow:
1. Make changes on feature branch (001-zellij-integration)
2. Commit and push to remote
3. Switch to `host/default`
4. Merge changes
5. ONLY THEN run `nixos-rebuild switch`

### II. Modular Architecture

✅ **COMPLIANT** - Integration follows existing modular structure:
- Zellij package added to `modules/packages/default.nix` in appropriate category (terminal or utilities)
- Configuration managed through `dotfiles/` directory using chezmoi
- No duplication between hosts - package enabled/disabled per host via existing mechanism
- Clear separation: system package (NixOS) vs. user config (dotfiles)

### III. Host Flexibility

✅ **COMPLIANT** - Both desktop and laptop hosts can enable/disable Zellij independently:
- Desktop (host/default): Zellij enabled by default
- Laptop (host/laptop): Can choose to enable or disable
- Configuration through chezmoi supports per-host customization via templates
- No changes to core host structure required

### IV. Declarative Package Management

✅ **COMPLIANT** - Zellij will be added declaratively:
- Package declared in `modules/packages/default.nix`
- Categorized appropriately (terminal utilities)
- Per-host enable option via existing pattern
- No imperative installation (`nix-env`, etc.)

### V. Test-Before-Switch

✅ **COMPLIANT** - Testing strategy documented:
- `nix flake check` before commit (validates Nix syntax)
- `nixos-rebuild build` before switch (ensures package builds)
- `zellij setup --check` validates KDL config syntax
- Manual verification of keybindings and layouts
- Rollback available via NixOS generations

### VI. Independent Dotfiles

✅ **COMPLIANT** - Core principle of this feature:
- Configuration files stored in `~/NixOS/dotfiles/`
- Managed via chezmoi (already installed and configured)
- Changes apply immediately via `chezmoi apply` - no rebuilds needed
- Version-controlled separately from system config
- Supports rapid iteration on keybindings, themes, layouts

### VII. Documentation as Code

✅ **COMPLIANT** - Documentation planned:
- KDL config file will contain inline comments explaining keybindings
- `quickstart.md` will be generated with usage guide
- CLAUDE.md may be updated with Zellij usage patterns
- All documentation version-controlled with configuration

**GATE STATUS**: ✅ **PASSED** - All constitution principles satisfied. No violations require justification.

---

## Post-Design Re-evaluation

*Re-checked after Phase 1 design (research, data model, contracts, quickstart)*

### Design Artifact Review

**Generated Artifacts**:
- ✅ `research.md`: Technology decisions (KDL format, locked mode, layouts, chezmoi integration)
- ✅ `data-model.md`: Configuration entities and relationships
- ✅ `contracts/config-schema.kdl`: Configuration schema reference
- ✅ `contracts/layout-schema.kdl`: Layout schema reference
- ✅ `quickstart.md`: User guide with keybindings and workflows

### Constitution Compliance Verification

**I. Safety-First Rebuilds**: ✅ **STILL COMPLIANT**
- Design confirms package installation via NixOS modules (requires rebuild on `host/default`)
- Design confirms configuration via chezmoi dotfiles (no rebuild needed)
- Workflow documented in research.md maintains branch safety

**II. Modular Architecture**: ✅ **STILL COMPLIANT**
- Package integration follows existing `modules/packages/default.nix` pattern
- Dotfiles follow XDG structure (`~/.config/zellij/`)
- No new module files needed - uses existing infrastructure

**III. Host Flexibility**: ✅ **STILL COMPLIANT**
- Per-host enable/disable through existing package categories
- Chezmoi templates support host-specific customization (desktop vs laptop)
- Layouts and configs shareable across hosts

**IV. Declarative Package Management**: ✅ **STILL COMPLIANT**
- Package declared in terminal category (declarative)
- Configuration files version-controlled in dotfiles
- No imperative installation

**V. Test-Before-Switch**: ✅ **STILL COMPLIANT**
- Testing strategy documented in research.md (multi-layered validation)
- `nix flake check`, `nixos-rebuild build`, `zellij setup --check`
- Manual functional testing checklist provided

**VI. Independent Dotfiles**: ✅ **STILL COMPLIANT**
- Core design principle - all configs in `~/NixOS/dotfiles/`
- Managed via chezmoi
- Changes apply instantly with `dotfiles-apply`
- Zero rebuild requirement for configuration changes

**VII. Documentation as Code**: ✅ **STILL COMPLIANT**
- Comprehensive quickstart.md generated (8 sections, 200+ lines)
- Schema documentation in contracts/
- Inline comments planned for config.kdl
- CLAUDE.md updated with active technologies

**FINAL GATE STATUS**: ✅ **PASSED** - Design maintains full compliance with all constitution principles. Ready to proceed to `/speckit.tasks`.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This is a NixOS configuration project - no traditional source code structure. Changes span:

```text
# NixOS System Configuration
modules/packages/default.nix    # Add zellij package to terminal category

# Dotfiles (Chezmoi-managed)
dotfiles/
├── dot_config/
│   └── zellij/
│       ├── config.kdl          # Main Zellij configuration
│       └── layouts/
│           ├── dev.kdl         # Development workflow layout
│           ├── admin.kdl       # System administration layout
│           └── default.kdl     # Default layout

# Feature Documentation
specs/001-zellij-integration/
├── plan.md                     # This file
├── research.md                 # Technology decisions (Phase 0)
├── data-model.md              # Configuration data model (Phase 1)
├── quickstart.md              # User guide (Phase 1)
└── contracts/                 # Config schemas (Phase 1)
    └── config-schema.kdl      # KDL schema reference
```

**Structure Decision**: This feature uses the existing NixOS modular architecture. The Zellij package declaration goes into the shared packages module, while user-facing configuration lives in the dotfiles directory managed by chezmoi. This separation allows the package to be installed system-wide (requires rebuild) while configuration can be modified and applied instantly (no rebuild needed). The dotfiles structure follows XDG Base Directory specification with configs in `~/.config/zellij/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - table not needed.
