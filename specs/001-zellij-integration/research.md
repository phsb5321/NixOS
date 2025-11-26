# Research: Zellij Terminal Multiplexer Integration

**Feature**: 001-zellij-integration
**Date**: 2025-11-26
**Purpose**: Document technology decisions, best practices, and design choices for Zellij integration

## Overview

This research document consolidates findings from web searches and analysis of Zellij best practices, NixOS integration patterns, and chezmoi dotfiles management to inform the implementation plan.

## Key Research Areas

### 1. Zellij Configuration Format (KDL)

**Decision**: Use KDL (Kiss Document Language) for all Zellij configuration files

**Rationale**:
- KDL became the official Zellij configuration format in v0.32.0 (replacing YAML)
- More human-readable and pleasant to write than YAML
- Better suited for large configuration files with complex nesting
- Official Zellij tooling (`zellij setup --check`) validates KDL syntax
- All modern Zellij documentation and examples use KDL

**Alternatives Considered**:
- **YAML**: Legacy format, deprecated since v0.32.0. Automatic conversion available but not recommended for new configurations.
- **TOML**: Not supported by Zellij

**References**:
- [Zellij 0.32.0 Release Notes](https://zellij.dev/news/config-command-layouts/) - KDL migration announcement
- [Zellij Configuration Guide](https://zellij.dev/documentation/configuration.html) - Official KDL documentation

---

### 2. Keybinding Mode Strategy

**Decision**: Default to "locked mode" with Alt-based mode switching

**Rationale**:
- Locked mode is the recommended default for 2025 best practices
- Minimizes conflicts with terminal and shell shortcuts (Ctrl+A, Ctrl+B in bash/tmux)
- Modal approach (similar to Vim) reduces cognitive load - clear separation between terminal input and multiplexer control
- Alt key combinations are less commonly used by other tools
- Follows patterns from modern dotfiles examples (ethanjli/dotfiles, rlch/dotfiles)

**Alternatives Considered**:
- **Default mode (always active)**: More conflicts with existing shortcuts, steeper learning curve
- **Custom prefix key (like tmux Ctrl+B)**: Less discoverable, requires memorizing prefix
- **Ctrl-based switching**: Conflicts with common terminal operations (Ctrl+C, Ctrl+D, Ctrl+Z)

**Implementation Details**:
- Locked mode as base state
- Alt+i to enter normal mode (for pane/tab operations)
- Alt+Esc to return to locked mode
- Visual indicator in status bar showing current mode

**References**:
- [ethanjli/dotfiles Zellij config](https://github.com/ethanjli/dotfiles) - Modal usage pattern
- [Zellij User Guide](https://zellij.dev/documentation/) - Mode documentation

---

### 3. Status Bar Plugin Configuration

**Decision**: Enable default status bar with system metrics (CPU, memory, time)

**Rationale**:
- Built-in plugins require no additional installation
- Provides at-a-glance system health monitoring
- Complements developer workflow (spotting resource-intensive processes)
- Minimal performance overhead (Rust-based plugins)
- Industry-standard practice for terminal multiplexers

**Alternatives Considered**:
- **No status bar**: Cleaner UI but loses valuable information
- **Custom plugins**: More complex, requires plugin development (out of scope per spec)
- **Minimal status bar**: Only tabs/mode indicator, misses system info value

**Implementation Details**:
```kdl
// Status bar configuration
ui {
    pane_frames {
        rounded_corners true
    }
}

// Enable default plugins
plugins {
    tab-bar { path "tab-bar"; }
    status-bar { path "status-bar"; }
    strider { path "strider"; }
    compact-bar { path "compact-bar"; }
}
```

**References**:
- [Zellij Plugins Overview](https://zellij.dev/documentation/) - Built-in plugins
- Community examples showing status bar best practices

---

### 4. Layout Template Structure

**Decision**: Create 3 layout templates (dev, admin, default) with dynamic CWD composition

**Rationale**:
- Meets spec requirement of "at least one example layout"
- Covers primary use cases for NixOS development workflow
- KDL layout system supports templates and CWD composition (v0.32.0+)
- Layouts as "quick shortcuts" align with Zellij's design philosophy
- Can be shared in dotfiles repository and version-controlled

**Alternatives Considered**:
- **Single default layout**: Less flexible, doesn't cover diverse workflows
- **Many specialized layouts (5+)**: Over-engineering, maintenance burden
- **No layouts**: Misses major Zellij productivity feature

**Layout Definitions**:

1. **dev.kdl** (Development workflow):
   - Top pane: Editor/IDE (80% height)
   - Bottom split: Terminal (left 50%) + Git status/logs (right 50%)
   - Working directory: `~/NixOS` or current project

2. **admin.kdl** (System administration):
   - Left pane: htop/system monitor (30% width)
   - Right split vertical:
     - Top: Main terminal (70% height)
     - Bottom: Journal logs (30% height)

3. **default.kdl** (General purpose):
   - Simple 2-pane horizontal split
   - Respects current working directory

**Implementation Pattern**:
```kdl
layout {
    pane_template name="terminal_pane" {
        command "zsh"
    }

    tab name="Dev" {
        pane split_direction="vertical" {
            pane size="80%" { }
            pane split_direction="horizontal" {
                pane size="50%" { }
                pane size="50%" { command "git"; args "status"; }
            }
        }
    }
}
```

**References**:
- [Zellij Layout System](https://zellij.dev/news/config-command-layouts/) - Templates and composition
- [Including Configuration in Layouts](https://zellij.dev/documentation/layouts-with-config)

---

### 5. Chezmoi Integration Pattern

**Decision**: Store Zellij configs in `dotfiles/dot_config/zellij/` with chezmoi templates for per-host customization

**Rationale**:
- Follows XDG Base Directory specification (`~/.config/zellij/`)
- Chezmoi `dot_` prefix translates to `.` in target path
- Template support allows host-specific variations (desktop vs laptop)
- No NixOS rebuild needed for config changes (aligns with Constitution Principle VI)
- Version-controlled alongside other dotfiles

**Alternatives Considered**:
- **Home Manager**: Requires NixOS rebuild for changes, conflicts with rapid iteration goal
- **Manual symlinks**: Not version-controlled, no per-host support
- **Direct edit in .config**: No version control, no reproducibility

**Directory Structure**:
```
dotfiles/
├── dot_config/
│   └── zellij/
│       ├── config.kdl              # Main config
│       ├── config.kdl.tmpl         # Optional: templated version for per-host
│       └── layouts/
│           ├── dev.kdl
│           ├── admin.kdl
│           └── default.kdl
```

**Chezmoi Template Example** (if needed for per-host):
```kdl
// config.kdl.tmpl
{{- if eq .chezmoi.hostname "default" }}
// Desktop-specific settings
default_layout "dev"
{{- else if eq .chezmoi.hostname "laptop" }}
// Laptop-specific settings
default_layout "default"
{{- end }}
```

**References**:
- [Chezmoi Templating Guide](https://www.chezmoi.io/user-guide/templating/)
- Existing NixOS dotfiles setup in project

---

### 6. NixOS Package Integration

**Decision**: Add `zellij` to `modules/packages/default.nix` in the `terminal` category

**Rationale**:
- Follows existing package categorization pattern
- Terminal multiplexer naturally fits "terminal" category
- Allows per-host enable/disable via existing mechanism
- Declarative package management (Constitution Principle IV)
- Package available system-wide for all users

**Alternatives Considered**:
- **utilities category**: Less semantically accurate
- **New category**: Over-engineering for single package
- **Per-user installation**: Conflicts with system-wide availability requirement

**Implementation**:
```nix
# In modules/packages/default.nix
terminal = mkOption {
  type = types.listOf types.package;
  default = with pkgs; [
    # ... existing terminal packages
    zellij  # Terminal multiplexer with modern UI
  ];
  description = "Terminal emulators and multiplexers";
};
```

**Package Source**:
- Use `nixpkgs-unstable` for latest Zellij version (follows project pattern)
- Fallback to stable if unstable has issues

**References**:
- Existing `modules/packages/default.nix` structure
- NixOS manual on package management

---

### 7. Theme and Visual Configuration

**Decision**: Use a clean, high-contrast theme with rounded corners and visual pane indicators

**Rationale**:
- Improved visual hierarchy makes pane focus clear
- Rounded corners (modern UI trend) improve aesthetics
- High contrast ensures readability in various lighting conditions
- Aligns with "clear visual hierarchy" requirement (FR-004)

**Theme Configuration**:
```kdl
themes {
    default {
        fg "#D8DEE9"
        bg "#2E3440"
        black "#3B4252"
        red "#BF616A"
        green "#A3BE8C"
        yellow "#EBCB8B"
        blue "#81A1C1"
        magenta "#B48EAD"
        cyan "#88C0D0"
        white "#E5E9F0"
        orange "#D08770"
    }
}

ui {
    pane_frames {
        rounded_corners true
        hide_session_name false
    }
}
```

**Alternatives Considered**:
- **No theme (terminal default)**: Less cohesive, no visual optimization
- **Light theme**: Harder on eyes for extended terminal use
- **Sharp corners**: Less modern, more visual noise

**References**:
- [Zellij Themes Documentation](https://zellij.dev/documentation/)
- Nord color palette (popular for terminal UIs)

---

### 8. Floating Panes vs. Stacked Panes

**Decision**: Enable floating panes, document stacked panes as optional

**Rationale**:
- Floating panes are better for "overlay workflows" (FR-008)
- Quick tasks (checking logs, man pages, searches) without disrupting layout
- Stacked panes useful for limited screen space but not primary use case
- Floating is more intuitive (like window managers)

**Implementation**:
- Default keybinding for floating pane toggle
- Floating panes appear centered with semi-transparent background
- Can be moved and resized independently

**Alternatives Considered**:
- **Stacked panes only**: Less flexible, harder to manage overlays
- **Both enabled equally**: Confusing UX, overlapping functionality
- **Neither**: Misses productivity features

**References**:
- [Zellij Floating Windows Feature](https://www.tecmint.com/zellij-linux-terminal-multiplexer/)

---

### 9. Session Persistence Strategy

**Decision**: Rely on Zellij's built-in session persistence, no additional tooling

**Rationale**:
- Zellij automatically persists sessions to disk
- Sessions survive terminal disconnections and system reboots
- `zellij attach` automatically reconnects to last session
- No need for tmux-resurrect equivalent - built into Zellij
- Meets SC-002 (session persistence) requirement

**Session Management Commands**:
```bash
zellij                    # Create or attach to default session
zellij attach <name>      # Attach to named session
zellij list-sessions      # List all sessions
zellij delete-session <name>  # Remove session
```

**Alternatives Considered**:
- **Custom persistence script**: Unnecessary, built-in works
- **Systemd service auto-start**: Out of scope per spec
- **Manual session save/restore**: Too complex, built-in better

**References**:
- [Zellij Session Management](https://zellij.dev/documentation/)

---

### 10. Testing and Validation Strategy

**Decision**: Multi-layered validation (Nix, KDL, Manual)

**Testing Layers**:

1. **Nix Configuration Validation**:
   ```bash
   nix flake check  # Validates flake.nix and all imports
   ```

2. **Build Verification**:
   ```bash
   nixos-rebuild build --flake .#default  # Ensures package builds
   ```

3. **KDL Syntax Validation**:
   ```bash
   zellij setup --check  # Validates config.kdl syntax
   ```

4. **Manual Functional Testing**:
   - Launch Zellij and verify UI appears
   - Test keybindings (pane split, tab creation, mode switching)
   - Test layout loading (`zellij --layout dev`)
   - Test session persistence (close terminal, reattach)
   - Verify status bar shows system info
   - Test floating pane creation

**Rationale**:
- Automated checks catch syntax errors before runtime
- Manual testing verifies user experience (SC-001, SC-004, SC-005)
- Layered approach minimizes risk of broken configuration
- Aligns with Constitution Principle V (Test-Before-Switch)

**References**:
- Zellij documentation on config validation
- NixOS testing best practices

---

## Implementation Priorities

Based on research, implementation should follow this order:

1. **P1 - Package Installation** (NixOS module change):
   - Add zellij to packages module
   - Requires rebuild on `host/default`

2. **P1 - Basic Configuration** (Dotfiles):
   - Create minimal `config.kdl` with keybindings and theme
   - Enable status bar plugins
   - Test with `zellij setup --check`

3. **P2 - Layout Templates** (Dotfiles):
   - Create `dev.kdl` layout
   - Create `admin.kdl` layout
   - Create `default.kdl` layout

4. **P2 - Documentation**:
   - Write quickstart.md with keybinding reference
   - Add inline comments to config.kdl
   - Update CLAUDE.md if needed

5. **P3 - Per-host Customization** (Optional):
   - Add chezmoi templates for host-specific configs
   - Test on both desktop and laptop

---

## Open Questions / Risks

### Resolved:
- ✅ **Config format**: KDL (official since v0.32.0)
- ✅ **Keybinding mode**: Locked mode with Alt switching
- ✅ **Dotfiles integration**: Chezmoi with XDG structure
- ✅ **Package category**: Terminal category in packages module

### Remaining:
- **Nested session handling**: Need to test behavior when launching Zellij within Zellij
  - Mitigation: Document expected behavior, disable nested sessions via config if problematic

- **Terminal compatibility**: Verify works with both desktop and laptop terminal emulators
  - Desktop: Check terminal emulator used
  - Laptop: Verify TERM variable set correctly
  - Mitigation: Document required TERM settings

---

## Summary

All technical decisions have been made based on:
- Official Zellij best practices (2025)
- Modern community examples (dotfiles repositories)
- NixOS modular architecture patterns
- Chezmoi dotfiles management best practices
- Constitution compliance

The implementation is ready to proceed to Phase 1 (data model and contracts).
