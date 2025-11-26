# Data Model: Zellij Configuration

**Feature**: 001-zellij-integration
**Date**: 2025-11-26
**Purpose**: Define the structure of Zellij configuration entities and their relationships

## Overview

Zellij configuration is file-based using KDL (Kiss Document Language) format. The data model defines the structure of configuration files, layout templates, and runtime session state. This is not a traditional database model but rather a schema for declarative configuration files.

## Core Entities

### 1. Configuration File (`config.kdl`)

The main configuration file defining global Zellij behavior.

**Location**: `~/.config/zellij/config.kdl` (managed via chezmoi)

**Structure**:
```kdl
// Top-level configuration nodes
config.kdl {
    keybindings {}      // Key mapping definitions
    themes {}           // Color scheme definitions
    ui {}               // UI preferences
    plugins {}          // Plugin configuration
    options {}          // General options
}
```

**Key Attributes**:

- **keybindings** (KeybindingConfig):
  - Defines keyboard shortcuts for all modes
  - Organized by mode (locked, normal, pane, tab, etc.)
  - Each binding maps key combination to action

- **themes** (ThemeConfig):
  - Color palette definitions
  - Named themes for different contexts
  - fg/bg and 8 standard terminal colors

- **ui** (UIConfig):
  - Visual preferences (rounded corners, pane frames)
  - Status bar visibility
  - Tab/pane styling

- **plugins** (PluginConfig):
  - List of enabled plugins
  - Plugin-specific settings
  - Plugin paths

- **options** (OptionsConfig):
  - Global settings (mouse mode, copy on select)
  - Default layout
  - Session behavior

**Validation Rules**:
- Must be valid KDL syntax
- Color values must be valid hex codes (#RRGGBB)
- Plugin paths must exist
- Keybindings cannot conflict within a mode

**State Lifecycle**:
1. Read from disk on Zellij startup
2. Validated via `zellij setup --check`
3. Applied to running instance
4. Reloaded on config file change (automatic detection)

---

### 2. Layout Template

Defines a predefined workspace arrangement with panes, tabs, and commands.

**Location**: `~/.config/zellij/layouts/*.kdl`

**Structure**:
```kdl
layout {
    tab name="TabName" {
        pane {
            // Pane configuration
        }
    }
    pane_template name="template_name" {
        // Reusable pane definition
    }
}
```

**Key Attributes**:

- **name** (string):
  - Unique identifier for the layout
  - Used in `zellij --layout <name>` command

- **tab** (TabDefinition, array):
  - Collection of tabs in the layout
  - Each tab contains pane arrangement

- **pane** (PaneDefinition, nested):
  - Tree structure defining pane splits
  - Horizontal or vertical splits
  - Size percentages

- **pane_template** (TemplateDefinition, optional):
  - Reusable pane configurations
  - Can be referenced in multiple places

- **cwd** (string, optional):
  - Working directory for panes
  - Supports dynamic composition

**Relationships**:
- Layout has-many Tabs
- Tab has-many Panes (tree structure)
- Pane can-reference PaneTemplate

**Validation Rules**:
- Tab names must be unique within layout
- Pane sizes must sum to 100% (or use fractional)
- Split directions must be valid (horizontal/vertical)
- Commands must be executable paths or shell commands
- Working directories must exist

**State Lifecycle**:
1. Selected via CLI argument or default_layout option
2. Parsed and validated
3. Session created with defined structure
4. Panes spawned with specified commands/cwd

---

### 3. Session

Runtime representation of an active Zellij instance.

**Storage**: In-memory + disk persistence (`~/.cache/zellij/`)

**Structure** (conceptual, not file-based):
```
Session {
    name: string
    tabs: Tab[]
    created_at: timestamp
    last_accessed: timestamp
    layout: string (name of layout used)
    attached: boolean
}
```

**Key Attributes**:

- **name** (string):
  - Unique session identifier
  - Auto-generated or user-specified

- **tabs** (Tab[], runtime):
  - Collection of active tabs
  - Each tab contains running panes

- **created_at** (timestamp):
  - Session creation time
  - Used for listing and cleanup

- **attached** (boolean):
  - Whether a terminal is currently attached
  - Sessions persist when detached

**Validation Rules**:
- Session name must be unique across all sessions
- At least one tab must exist
- Cannot delete currently attached session

**State Transitions**:
1. **Created**: New session spawned
2. **Attached**: Terminal connected to session
3. **Detached**: Terminal disconnected, session persists
4. **Reattached**: Terminal reconnected to existing session
5. **Deleted**: Session explicitly removed

**Relationships**:
- Session has-many Tabs
- Session created-from Layout (optional)
- Session persisted-to DiskCache

---

### 4. Pane (Runtime)

Individual terminal instance within a session.

**Structure** (runtime state):
```
Pane {
    id: number
    title: string
    command: string
    cwd: string
    focused: boolean
    type: tiled | floating
    position: { x, y, width, height }
}
```

**Key Attributes**:

- **id** (number):
  - Unique within session
  - Used for pane switching commands

- **title** (string):
  - Displayed in pane border
  - Auto-set from command or user-defined

- **command** (string, optional):
  - Running process (e.g., "zsh", "htop")
  - Default shell if not specified

- **cwd** (string):
  - Current working directory
  - Inherited or explicitly set

- **focused** (boolean):
  - Whether pane has keyboard focus
  - Only one pane focused per session

- **type** (enum: tiled, floating):
  - Tiled: Part of grid layout
  - Floating: Overlay on top of tiled panes

- **position** (coordinates):
  - For tiled: grid position and size
  - For floating: absolute coordinates

**Validation Rules**:
- Only one pane can be focused at a time
- Floating panes must have valid coordinates
- Working directory must exist

**State Transitions**:
1. **Created**: Pane spawned from layout or user action
2. **Focused**: User navigates to pane
3. **Resized**: Pane size changed
4. **Closed**: Pane terminated (process exit or user action)

---

### 5. Keybinding

Maps keyboard input to Zellij actions.

**Structure** (in config.kdl):
```kdl
keybindings {
    locked {
        bind "Alt i" { SwitchToMode "Normal"; }
    }
    normal {
        bind "Ctrl p" { SwitchToMode "Pane"; }
        bind "n" { NewPane; SwitchToMode "Locked"; }
    }
}
```

**Key Attributes**:

- **mode** (string):
  - Context for the binding (locked, normal, pane, tab, etc.)
  - Determines when binding is active

- **key** (string):
  - Key combination (e.g., "Ctrl p", "Alt i", "F1")
  - Modifiers: Ctrl, Alt, Shift

- **action** (Action):
  - Command to execute
  - Can be chained (multiple actions per binding)

**Common Actions**:
- `SwitchToMode`: Change mode
- `NewPane`: Create new pane
- `NewTab`: Create new tab
- `MoveFocus`: Navigate between panes
- `Resize`: Change pane size
- `ToggleFloatingPanes`: Show/hide floating panes

**Validation Rules**:
- Key combinations must be valid
- Actions must be recognized Zellij commands
- Cannot bind the same key twice in the same mode

---

### 6. Theme

Color scheme definition for UI elements.

**Structure** (in config.kdl):
```kdl
themes {
    nord {
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
```

**Key Attributes**:

- **name** (string):
  - Theme identifier
  - Referenced in UI config

- **fg/bg** (hex color):
  - Foreground and background colors

- **color palette** (8 colors + orange):
  - Standard terminal colors
  - Used for syntax highlighting and UI elements

**Validation Rules**:
- All color values must be valid hex codes
- Sufficient contrast between fg/bg for readability

---

### 7. Plugin

Extension that provides additional functionality.

**Structure** (in config.kdl):
```kdl
plugins {
    tab-bar { path "tab-bar"; }
    status-bar { path "status-bar"; }
    strider { path "strider"; }
}
```

**Key Attributes**:

- **name** (string):
  - Plugin identifier
  - Matches plugin directory name

- **path** (string):
  - Relative or absolute path to plugin
  - Built-in plugins use simple names

- **config** (map, optional):
  - Plugin-specific settings
  - Varies by plugin

**Built-in Plugins**:
- `tab-bar`: Tab switcher and indicator
- `status-bar`: System info and session details
- `strider`: File picker
- `compact-bar`: Minimal status bar

**Validation Rules**:
- Plugin path must exist
- Plugin must be compatible with Zellij version

---

## Entity Relationships

```
Configuration (config.kdl)
    ├─ defines → Keybindings (many)
    ├─ defines → Themes (many)
    ├─ defines → UI Preferences
    ├─ enables → Plugins (many)
    └─ specifies → Default Layout

Layout Template (*.kdl)
    ├─ contains → Tabs (many)
    │   └─ contains → Panes (tree)
    └─ defines → Pane Templates (many)

Session (runtime)
    ├─ created from → Layout Template (optional)
    ├─ contains → Tabs (many, runtime)
    │   └─ contains → Panes (many, runtime)
    ├─ uses → Configuration
    └─ persists to → Disk Cache

Pane (runtime)
    ├─ runs → Command
    ├─ has → Working Directory
    ├─ can be → Tiled | Floating
    └─ belongs to → Tab

Keybinding
    ├─ belongs to → Mode
    ├─ triggers → Action
    └─ defined in → Configuration

Theme
    ├─ defines → Color Palette
    └─ applied to → UI Elements
```

---

## Data Flow

### Startup Flow
```
1. User launches Zellij
   ↓
2. Load config.kdl from ~/.config/zellij/
   ↓
3. Validate configuration (keybindings, themes, plugins)
   ↓
4. Load default or specified layout
   ↓
5. Create session with layout structure
   ↓
6. Spawn panes with commands/cwd
   ↓
7. Apply theme to UI
   ↓
8. Enable configured plugins
   ↓
9. Ready for user input
```

### Configuration Change Flow
```
1. User edits config.kdl or layout file
   ↓
2. Save file to disk
   ↓
3. Apply changes with chezmoi (dotfiles-apply)
   ↓
4. Zellij auto-detects config change
   ↓
5. Reload configuration (no restart needed)
   ↓
6. Apply new keybindings/theme
```

### Session Persistence Flow
```
1. User detaches from session (Ctrl+D or close terminal)
   ↓
2. Session state serialized to disk cache
   ↓
3. Session continues running in background
   ↓
4. User runs `zellij attach`
   ↓
5. Session state loaded from cache
   ↓
6. Terminal reattached to session
   ↓
7. All panes and state restored
```

---

## File Locations

| Entity | Location | Managed By |
|--------|----------|------------|
| Main Config | `~/.config/zellij/config.kdl` | Chezmoi |
| Layouts | `~/.config/zellij/layouts/*.kdl` | Chezmoi |
| Session Cache | `~/.cache/zellij/` | Zellij (automatic) |
| Plugin Data | `~/.local/share/zellij/` | Zellij (automatic) |
| Dotfiles Source | `~/NixOS/dotfiles/dot_config/zellij/` | Git + Chezmoi |

---

## Validation Summary

Each entity has specific validation requirements:

1. **Configuration**: KDL syntax, valid color codes, existing plugin paths
2. **Layout**: Valid split directions, size percentages sum to 100%, executable commands
3. **Session**: Unique names, at least one tab
4. **Pane**: Valid cwd, unique ID within session
5. **Keybinding**: Valid key combinations, recognized actions, no conflicts within mode
6. **Theme**: Valid hex colors, sufficient contrast
7. **Plugin**: Existing paths, version compatibility

Validation occurs at:
- **Design time**: Manual review of KDL syntax
- **Pre-commit**: `zellij setup --check` in CI/validation script
- **Runtime**: Zellij config parser on startup
- **Deployment**: `chezmoi apply` applies validated configs
