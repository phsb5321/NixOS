<!--
  Sync Impact Report
  ==================
  Version: 0.1.0 → 1.0.0 (Initial Constitution)

  Changes:
  - Created first version of constitution from template
  - Defined 7 core principles for NixOS configuration management
  - Added safety and testing requirements
  - Established governance rules

  Templates Status:
  ✅ plan-template.md: Constitution Check section already references constitution
  ✅ spec-template.md: Requirements naturally align with principles
  ✅ tasks-template.md: Task organization supports safety and testing principles

  Follow-up TODOs: None - all placeholders filled
-->

# NixOS Configuration Constitution

## Core Principles

### I. Safety-First Rebuilds (NON-NEGOTIABLE)

NixOS rebuilds MUST only be executed on the `host/default` branch. This is a strict safety requirement to prevent breaking production systems.

**Rules:**
- ✅ **SAFE**: Only perform `sudo nixos-rebuild switch/build/test` when on `host/default` branch
- ❌ **UNSAFE**: Never run rebuild commands on any other branch (`develop`, `host/laptop`, `main`, etc.)
- ALL configuration changes on other branches MUST be committed and pushed, then the branch switched to `host/default` before rebuilding
- If asked to rebuild while not on `host/default`, the request MUST be refused with explanation and alternative offered

**Rationale**: The desktop system is the primary development environment. Breaking it would halt all work. Branch isolation ensures changes are reviewed and intentional before being applied to the running system.

### II. Modular Architecture

Configuration MUST follow a modular structure with clear separation of concerns. Each system area (core, hardware, networking, desktop, packages) MUST be independently configurable.

**Rules:**
- Each module MUST have a single, well-defined responsibility
- Host-specific configurations MUST import shared modules and only override what is unique
- No duplication of configuration across hosts (DRY principle)
- New modules MUST follow the categorical organization under `modules/`

**Rationale**: Modularity enables maintainability, reusability, and scalability as the number of hosts and configurations grows.

### III. Host Flexibility

Adding a new host MUST be trivial and only require defining host-specific overrides. Common configuration MUST be inherited automatically.

**Rules:**
- New hosts MUST inherit from shared modules
- Host-specific files MUST only contain overrides and unique configuration
- Package categories MUST be enable/disable per host without modifying shared definitions
- All hosts MUST use the same flake structure and module system

**Rationale**: Reduces the friction and time required to manage multiple machines with similar but not identical configurations.

### IV. Declarative Package Management

All packages MUST be declared in categorized modules with per-host enable/disable options. No imperative package installation allowed.

**Rules:**
- Packages MUST be organized into logical categories (browsers, development, media, utilities, gaming, etc.)
- Each category MUST have an enable option for per-host control
- Host-specific packages that don't fit categories go in `extraPackages`
- Package additions MUST follow existing patterns in `modules/packages/`

**Rationale**: Declarative management ensures reproducibility, version control, and easy rollbacks. Categorization reduces complexity and makes intent clear.

### V. Test-Before-Switch

Configuration changes MUST be validated before switching to them. Emergency rollback paths MUST always be available.

**Rules:**
- Run `nix flake check` before committing configuration changes
- Use `nixos-rebuild build` or `test` before `switch` when possible
- Never force-push to protected branches (main, develop)
- Keep previous generation available for emergency rollback via bootloader

**Rationale**: NixOS's biggest strength is safe configuration management. This principle ensures we actually use it rather than treating the system like a mutable traditional distro.

### VI. Independent Dotfiles

User-space configuration (dotfiles) MUST be managed independently of NixOS configuration using chezmoi. Dotfiles MUST apply instantly without rebuilds.

**Rules:**
- Dotfiles MUST be stored in project-local directory (`~/NixOS/dotfiles/`)
- Dotfiles MUST be version-controlled separately from NixOS config
- Changes to dotfiles MUST NOT require NixOS rebuilds
- Helper scripts MUST be provided for common dotfiles operations

**Rationale**: Separating dotfiles from system configuration allows rapid iteration on user-space tools without the overhead of system rebuilds. This separation of concerns improves development velocity.

### VII. Documentation as Code

All configuration decisions, workflows, and architecture MUST be documented in version-controlled markdown files alongside the configuration itself.

**Rules:**
- `CLAUDE.md` MUST contain guidance for AI assistants working with the codebase
- `README.md` MUST explain structure, usage, and provide quick reference
- Breaking changes or new workflows MUST be documented before merging
- Documentation MUST be updated atomically with configuration changes

**Rationale**: Configuration is code. Documentation is essential for understanding intent, onboarding, and maintaining the system over time. AI assistance requires clear, written guidance.

## Development Workflow

### Branch Strategy

- **main**: Production-ready stable configuration (protected, requires PR approval)
- **develop**: Integration branch for features affecting multiple hosts or shared modules
- **host/default**: Desktop-specific changes (AMD GPU, gaming, performance) - ONLY branch safe for rebuilds
- **host/laptop**: Laptop-specific changes (Intel/NVIDIA GPU, power management) - NO rebuilds allowed
- **hotfix/***: Emergency fixes branched from main, merged back to all branches

### Safe Workflow Pattern

1. Work on any branch for configuration changes
2. Commit and push changes to remote
3. Switch to `host/default`: `git checkout host/default`
4. Merge or cherry-pick changes if needed
5. **ONLY THEN** run rebuild commands
6. After successful rebuild, create PR to appropriate upstream branch

### Testing Requirements

All configuration changes MUST pass:
- `nix flake check` - Validates flake syntax and configuration
- `nixos-rebuild build` - Builds configuration without switching
- Manual verification after `switch` on `host/default`

## Governance

### Amendment Process

1. Amendments MUST be proposed via PR to this constitution file
2. Breaking changes (removing principles, changing core rules) REQUIRE major version bump
3. New principles or material expansions REQUIRE minor version bump
4. Clarifications and wording improvements REQUIRE patch version bump
5. Amendment MUST include Sync Impact Report (as HTML comment at top of file)
6. Dependent templates MUST be validated and updated if affected

### Compliance

- All PRs and reviews MUST verify compliance with these principles
- Violations MUST be justified in PR description with explicit reasoning
- Complexity that violates simplicity principles MUST be documented in plan.md Complexity Tracking section
- Claude Code (via CLAUDE.md) MUST enforce Safety-First Rebuilds principle

### Version Control

- Constitution version uses semantic versioning: MAJOR.MINOR.PATCH
- Ratification date is the original adoption date
- Last amended date is updated with each change
- All versions MUST be tagged in git

**Version**: 1.0.0 | **Ratified**: 2025-11-26 | **Last Amended**: 2025-11-26
