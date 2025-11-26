# Feature Specification: Zellij Terminal Multiplexer Integration

**Feature Branch**: `001-zellij-integration`
**Created**: 2025-11-26
**Status**: Draft
**Input**: User description: "Install zellij as a core dependencie and implement a dotfile for the best usage of it. Web search the best practices and best ways to use it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Terminal Multiplexing (Priority: P1)

As a developer working on NixOS, I want to use Zellij for terminal session management so that I can organize multiple terminal panes within a single window, persist sessions across disconnections, and improve my terminal workflow efficiency.

**Why this priority**: This is the foundational capability that delivers immediate value - users can split terminals, create tabs, and manage their workspace without relying on external tools like tmux or screen.

**Independent Test**: Can be fully tested by launching Zellij from the terminal, creating panes and tabs, closing the terminal, and verifying the session persists and can be reattached.

**Acceptance Scenarios**:

1. **Given** Zellij is installed on the system, **When** user runs `zellij` command, **Then** a new session starts with default layout and keybindings are visible
2. **Given** user is in a Zellij session, **When** user creates horizontal and vertical panes, **Then** all panes are functional and navigable
3. **Given** user has an active Zellij session, **When** terminal window is closed accidentally, **Then** session persists and can be reattached with `zellij attach`
4. **Given** user is in a Zellij session, **When** user creates multiple tabs, **Then** tabs are clearly labeled and switchable

---

### User Story 2 - Optimized Configuration (Priority: P2)

As a developer, I want Zellij to have sensible default keybindings, modern UI themes, and performance optimizations so that I can use it productively without extensive manual configuration.

**Why this priority**: While basic functionality works out-of-the-box, an optimized configuration significantly improves usability, reduces friction, and provides best-practice settings based on community feedback.

**Independent Test**: Can be tested by verifying the configuration file exists, contains recommended settings, and results in improved UX (e.g., faster navigation, clearer status bar, better theme).

**Acceptance Scenarios**:

1. **Given** Zellij is installed, **When** user starts a new session, **Then** the interface uses an optimized theme with clear visual hierarchy
2. **Given** user has the dotfile configuration, **When** user navigates using keybindings, **Then** common actions (split pane, new tab, switch focus) use intuitive shortcuts
3. **Given** configuration includes status bar plugins, **When** session is active, **Then** status bar displays useful system information (CPU, memory, time)
4. **Given** user works with multiple panes, **When** focusing between panes, **Then** transitions are smooth and current pane is clearly indicated

---

### User Story 3 - Custom Layouts (Priority: P3)

As a developer with specific workflow needs, I want predefined Zellij layouts for common development scenarios so that I can quickly spin up complete development environments (e.g., editor + terminal + logs).

**Why this priority**: Layouts are a powerful productivity feature but not essential for basic usage. They represent advanced customization that experienced users will appreciate.

**Independent Test**: Can be tested by loading a layout file and verifying that panes are created with correct commands, working directories, and arrangement.

**Acceptance Scenarios**:

1. **Given** layout files exist for common workflows, **When** user runs `zellij --layout <layout-name>`, **Then** workspace opens with predefined pane arrangement
2. **Given** a development layout is loaded, **When** session starts, **Then** each pane opens in the correct directory with appropriate commands running
3. **Given** user has custom layouts, **When** user switches between layouts, **Then** transitions maintain session state appropriately

---

### Edge Cases

- What happens when Zellij is launched within an existing Zellij session (nested sessions)?
- How does the system handle configuration file syntax errors or missing KDL files?
- What happens when a session name conflict occurs during attachment?
- How does Zellij behave when terminal size changes dramatically (e.g., from desktop to mobile screen via SSH)?
- What happens when the dotfiles directory is not initialized or chezmoi is not installed?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST install Zellij as a core package available to all users on the NixOS system
- **FR-002**: System MUST provide a configuration file in KDL format located in the dotfiles directory for chezmoi management
- **FR-003**: Configuration MUST include optimized keybindings following modern best practices (default to locked mode, modal switching)
- **FR-004**: Configuration MUST define a clear and informative default theme with visual hierarchy
- **FR-005**: Configuration MUST enable useful status bar information (system metrics, session info, time)
- **FR-006**: System MUST include at least one example layout file for common development workflows
- **FR-007**: Configuration MUST enable session persistence to survive terminal disconnections
- **FR-008**: Configuration MUST use floating panes capability for overlay workflows
- **FR-009**: Dotfiles MUST be managed through chezmoi to allow per-host customization
- **FR-010**: System MUST provide clear documentation of keybindings and usage patterns in comments or separate docs

### Key Entities

- **Zellij Session**: Represents a persistent terminal multiplexing session with tabs and panes, identified by session name, survives disconnection
- **Layout Template**: Configuration file defining pane arrangement, working directories, and startup commands for specific workflows
- **Configuration File**: KDL-formatted file (`config.kdl`) containing keybindings, theme settings, plugin configuration, and UI preferences
- **Pane**: Individual terminal instance within a session, can be tiled or floating, has focus state and working directory
- **Plugin**: Extension that provides additional functionality (status bar, file picker, system info)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create, split, and navigate between terminal panes in under 5 seconds using configured keybindings
- **SC-002**: Terminal sessions persist across disconnections and can be reattached without data loss
- **SC-003**: Configuration file loads without errors on system startup
- **SC-004**: Users can switch between at least 3 predefined layouts instantly (under 2 seconds)
- **SC-005**: Status bar displays real-time system information updated at least every 2 seconds
- **SC-006**: Zellij launches in under 1 second on typical NixOS hardware
- **SC-007**: Configuration changes applied via chezmoi take effect immediately without system rebuild

## Assumptions

- Users are familiar with basic terminal usage and understand concepts like tabs and panes
- Chezmoi is already installed and initialized on the NixOS system (per existing dotfiles setup)
- Users primarily work in terminal-based workflows (development, system administration, DevOps)
- Default mode preference is "locked mode" with Alt key combinations for mode switching (based on modern best practices)
- KDL configuration format is acceptable (industry standard for Zellij since v0.32.0)
- Floating panes will be preferred over stacked panes for most overlay use cases
- System resources are sufficient for running Zellij with plugins (minimal overhead expected)

## Scope

### In Scope

- Installing Zellij package via NixOS package management
- Creating optimized configuration file with keybindings, theme, and plugins
- Defining at least one example layout for development workflows
- Integration with chezmoi dotfiles management
- Documentation of keybindings and basic usage

### Out of Scope

- Custom plugin development or third-party plugin integration beyond defaults
- Migration scripts from tmux or screen configurations
- Per-user customization beyond host-level dotfiles
- Zellij session management automation (auto-start, systemd services)
- Integration with specific IDEs or editors (Neovim, VSCode, etc.)
- Advanced collaboration features or multiplayer session setup

## Dependencies

- NixOS package manager with access to nixpkgs (stable or unstable)
- Chezmoi dotfiles management system already configured
- XDG Base Directory specification compliance (`~/.config/zellij/`)
- Terminal emulator with true color support and proper TERM environment variable

## Risks & Mitigations

- **Risk**: Configuration syntax errors in KDL files could prevent Zellij from starting
  - **Mitigation**: Validate configuration with `zellij setup --check` before applying

- **Risk**: Keybinding conflicts with existing terminal or shell shortcuts
  - **Mitigation**: Use locked mode as default to minimize conflicts, document overrides

- **Risk**: Users unfamiliar with modal terminal multiplexers may find UX confusing
  - **Mitigation**: Provide clear documentation, use visual keybinding hints in status bar

- **Risk**: Dotfiles not properly initialized could lead to missing configuration
  - **Mitigation**: Document initialization steps, verify chezmoi setup before proceeding
