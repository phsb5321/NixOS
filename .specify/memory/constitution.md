# NixOS Configuration Constitution

<!--
Sync Impact Report - Version 1.0.0

Version Change: Initial → 1.0.0
Rationale: MAJOR version (1.0.0) - Initial constitution establishing foundational governance principles

Modified Principles: N/A (Initial creation)
Added Sections:
  - Core Principles (5 principles)
  - Development Workflow
  - Quality Standards
  - Governance

Templates Status:
  ✅ plan-template.md - Verified compatible (Constitution Check section aligns)
  ✅ spec-template.md - Verified compatible (Requirements align with principles)
  ✅ tasks-template.md - Verified compatible (Task organization reflects principles)

Follow-up TODOs: None
-->

## Core Principles

### I. Modularity and Composability

**Rule**: Every system component MUST be independently configurable, reusable, and composable.

- Host configurations MUST NOT contain duplicated code; shared functionality belongs in modules
- New features MUST be implemented as discrete modules with clear enable/disable toggles
- Modules MUST follow the established directory structure (core/, hardware/, networking/, packages/, desktop/, roles/)
- Each module MUST have a well-defined interface with explicit options
- Cross-module dependencies MUST be minimized and explicitly documented

**Rationale**: This prevents configuration drift between hosts, reduces maintenance burden, and enables easy addition of new hosts. The successful refactoring from monolithic 372-line common.nix to 51 focused modules demonstrates this principle's value.

### II. Declarative Configuration (NON-NEGOTIABLE)

**Rule**: All system state MUST be declaratively defined in Nix expressions; imperative modifications are forbidden in production.

- System configuration MUST be reproducible from the repository alone
- Manual system modifications MUST be converted to declarative Nix expressions
- Hardware-specific settings belong in hardware-configuration.nix
- User-level configuration MUST use chezmoi dotfiles system (NOT Home Manager)
- Environment setup MUST use nix shells, not global installations

**Rationale**: Declarative configuration ensures reproducibility, simplifies rollbacks, and enables version control of system state. This is the foundational principle of NixOS and cannot be compromised.

### III. No Home Manager Policy (NON-NEGOTIABLE)

**Rule**: Home Manager MUST NOT be used or suggested; all user configuration MUST use the chezmoi dotfiles system.

- User-level configuration (GNOME settings, app configs, shell configs) belongs in `~/NixOS/dotfiles/`
- Dotfiles provide template support for host-specific settings (isDesktop/isLaptop detection)
- Changes to user configuration apply instantly via `dotfiles-apply` without NixOS rebuilds
- System packages are managed in NixOS modules; user configs in dotfiles
- NEVER suggest `home-manager.users.*`, `programs.*`, or `dconf.settings` in Home Manager context

**Rationale**: Home Manager adds unnecessary complexity. The chezmoi dotfiles system is simpler, more flexible, portable across non-NixOS systems, and already fully functional with validation, templates, and secrets integration.

### IV. Testing and Validation

**Rule**: All configuration changes MUST pass validation before deployment; critical changes MUST include tests.

- Flake outputs MUST include comprehensive checks (format-check, lint-check, eval-test)
- Use `alejandra` for formatting (enforced via pre-commit hooks)
- Major module additions SHOULD include integration tests in tests/ directory
- Configuration MUST build successfully for all defined hosts before merge
- GPU configurations MUST provide fallback variants (hardware/conservative/software)
- Use `nixswitch` script for rebuilds (handles validation, cleanup, error recovery)

**Rationale**: The testing infrastructure (385 lines across 5 test files) prevents broken deployments and ensures multi-host configurations remain functional. Validation gates catch issues before they reach production systems.

### V. Documentation and Maintainability

**Rule**: All architectural decisions, module interfaces, and workflows MUST be documented in CLAUDE.md and module-specific README files.

- CLAUDE.md is the single source of truth for development guidance
- Module additions MUST include inline documentation of options and purpose
- Breaking changes MUST be documented with migration guides
- Git workflow MUST follow branch strategy (main/develop/host/*/feature branches)
- Commit messages MUST follow conventional commits format (feat/fix/docs/refactor/chore)

**Rationale**: Comprehensive documentation (5 major guides created during refactoring) enables maintainability, onboarding, and prevents knowledge loss. Clear guidelines reduce decision paralysis and ensure consistency.

## Development Workflow

### Configuration Changes

1. **Branch Selection**:
   - Host-specific changes → `host/desktop` or `host/laptop`
   - Shared module changes → `develop`
   - Emergency fixes → `hotfix/*` from `main`

2. **Development Process**:
   - Make changes to relevant modules
   - Run `alejandra .` to format code
   - Test with `nix flake check`
   - Build target host: `sudo nixos-rebuild build --flake .#<host>`
   - Apply with `nixswitch` script (preferred) or manual rebuild

3. **Validation Gates**:
   - All checks MUST pass before commit
   - Both host configurations MUST build successfully before merge to develop
   - Test on actual hardware before merging develop to main

### User Configuration Changes

1. **Dotfiles Workflow**:
   - Edit dotfiles in `~/NixOS/dotfiles/`
   - Run `dotfiles-check` for validation (syntax, secrets scanning)
   - Apply with `dotfiles-apply` (instant, no rebuild)
   - Commit dotfiles changes independently of NixOS config

2. **Template Usage**:
   - Use Chezmoi templates for host-specific configs (SSH, Git)
   - Test on both desktop and laptop when using conditionals

### Adding New Modules

1. **Module Creation**:
   - Place in appropriate subdirectory (core/hardware/networking/packages/desktop/roles)
   - Follow existing module patterns (enable options, explicit dependencies)
   - Include inline documentation

2. **Integration**:
   - Update module imports in hosts/
   - Add enable toggle in host configurations
   - Update CLAUDE.md with module description and usage

## Quality Standards

### Code Quality

- **Formatting**: Enforced via `alejandra` (no exceptions)
- **Linting**: `statix` and `deadnix` checks MUST pass
- **Naming**: Follow NixOS conventions (camelCase options, kebab-case file names)
- **Complexity**: Modules over 500 lines SHOULD be split into focused sub-modules

### Performance

- **Build Time**: Host configurations SHOULD build in under 5 minutes
- **Store Optimization**: Use `nix-store --optimise` regularly
- **Garbage Collection**: Automated via maintenance scripts
- **Evaluation**: Configurations MUST evaluate without warnings

### Security

- **Secrets Management**: Use sops-nix for sensitive data (secrets/ directory)
- **SSH Hardening**: Enforce key-based auth, disable password auth
- **Firewall**: Explicit port allowances, deny by default
- **Updates**: Run `nix flake update` regularly; test before deployment

## Governance

### Amendment Process

1. **Proposal**: Document proposed principle changes in issue or PR
2. **Review**: Discuss impact on existing configurations and workflows
3. **Migration**: Create migration guide for breaking changes
4. **Approval**: Changes require successful build of all hosts and documentation update
5. **Version Bump**: Follow semantic versioning for constitution changes

### Versioning Policy

- **MAJOR**: Backward-incompatible governance changes or principle removals/redefinitions
- **MINOR**: New principles added or materially expanded guidance
- **PATCH**: Clarifications, wording improvements, non-semantic refinements

### Compliance

- All PRs and reviews MUST verify compliance with Core Principles
- Complexity violations (e.g., Home Manager suggestions) MUST be rejected immediately
- Constitution supersedes all other practices and documentation
- When templates/documentation conflict with constitution, constitution wins

### Conflict Resolution

- For ambiguous situations, defer to CLAUDE.md guidance
- If CLAUDE.md silent, follow NixOS community best practices
- Propose constitution amendment if recurring conflicts arise

**Version**: 1.0.0 | **Ratified**: 2025-11-24 | **Last Amended**: 2025-11-24
