# Zellij Terminal Multiplexer - Quick Start Guide

**Feature**: 001-zellij-integration
**Target Users**: Developers using NixOS desktop and laptop configurations
**Last Updated**: 2025-11-26

## What is Zellij?

Zellij is a modern terminal multiplexer that allows you to:
- Split your terminal into multiple panes (horizontal/vertical)
- Create tabs to organize different workflows
- Persist sessions across disconnections
- Use floating panes for quick overlays
- Switch between predefined layouts instantly

Think of it as a workspace manager for your terminal - like tmux or screen, but with a more intuitive UI and modern features.

---

## Installation Status

Zellij is installed as a system package via NixOS and configured through chezmoi-managed dotfiles.

**Package Location**: `modules/packages/default.nix` (terminal category)
**Configuration Location**: `~/NixOS/dotfiles/dot_config/zellij/`

To enable on a host, ensure the terminal packages category is enabled in your host configuration.

---

## Basic Usage

### Starting Zellij

```bash
# Start a new session or attach to the default session
zellij

# Start with a specific layout
zellij --layout dev

# Create a named session
zellij --session mysession

# List all sessions
zellij list-sessions

# Attach to a specific session
zellij attach mysession
```

### Exiting Zellij

```bash
# Detach from session (session continues running)
Ctrl+D  (or close terminal)

# Kill current session
Alt+i (enter Normal mode) → Ctrl+q → y (confirm)
```

---

## Mode System

Zellij uses a **modal interface** similar to Vim. This minimizes conflicts with terminal shortcuts.

### Available Modes

| Mode | Purpose | How to Enter |
|------|---------|--------------|
| **Locked** | Default mode - pure terminal, no Zellij shortcuts active | `Alt+Esc` (from any mode) |
| **Normal** | Primary Zellij control mode for quick actions | `Alt+i` (from Locked) |
| **Pane** | Pane management (split, resize, navigate) | `Ctrl+p` (from Normal) |
| **Tab** | Tab management (create, switch, rename) | `Ctrl+t` (from Normal) |
| **Resize** | Resize panes | `Ctrl+r` (from Normal) |
| **Scroll** | Scrollback navigation | `Ctrl+s` (from Normal) |

**Visual Indicator**: Current mode is shown in the status bar at the bottom.

---

## Essential Keybindings

### Mode Switching

| Keys | Action |
|------|--------|
| `Alt+i` | Enter Normal mode (from Locked) |
| `Alt+Esc` | Return to Locked mode (from any mode) |

### Pane Management (from Normal or Pane mode)

| Keys | Action |
|------|--------|
| `Ctrl+p` | Enter Pane mode |
| `n` | New pane (splits right) |
| `d` | New pane below (splits down) |
| `r` | New pane to the right |
| `x` | Close current pane |
| `f` | Toggle fullscreen for current pane |
| `w` | Toggle floating panes |
| `h/j/k/l` | Move focus (left/down/up/right, Vim-style) |
| `Tab` | Cycle through panes |

### Tab Management (from Normal or Tab mode)

| Keys | Action |
|------|--------|
| `Ctrl+t` | Enter Tab mode |
| `n` | New tab |
| `x` | Close current tab |
| `h` | Previous tab |
| `l` | Next tab |
| `r` | Rename current tab |
| `1-9` | Jump to tab number |

### Resize Mode (from Resize mode)

| Keys | Action |
|------|--------|
| `Ctrl+r` | Enter Resize mode |
| `h/j/k/l` | Increase pane size (left/down/up/right) |
| `H/J/K/L` | Decrease pane size (Shift + direction) |

### Scroll Mode (from Scroll mode)

| Keys | Action |
|------|--------|
| `Ctrl+s` | Enter Scroll mode |
| `j/k` | Scroll down/up (line by line) |
| `d/u` | Half-page scroll down/up |
| `Ctrl+f/b` | Full-page scroll forward/back |
| `/` | Search in scrollback |
| `e` | Edit scrollback in $EDITOR |

### Session Management (from Normal mode)

| Keys | Action |
|------|--------|
| `Ctrl+o` | Enter Session mode |
| `d` | Detach from session |
| `Ctrl+q` | Quit Zellij (prompts for confirmation) |

---

## Workflow Examples

### Example 1: Development Workflow

```bash
# Start Zellij with dev layout
zellij --layout dev

# Result:
# ┌─────────────────────────────────┐
# │  Editor (60%)                   │
# ├───────────────┬─────────────────┤
# │ Terminal (30%)│ Git logs (10%)  │
# └───────────────┴─────────────────┘
```

**Use case**: Coding session with editor, terminal for commands, and git log viewer.

### Example 2: System Administration

```bash
# Start Zellij with admin layout
zellij --layout admin

# Result:
# ┌──────┬───────────────────────┐
# │ htop │  Main terminal (70%)  │
# │(30%) ├───────────────────────┤
# │      │  Journal logs (30%)   │
# └──────┴───────────────────────┘
```

**Use case**: System monitoring + command execution + log watching.

### Example 3: Quick Floating Pane

```bash
# While working in Zellij:
1. Alt+i (enter Normal mode)
2. Ctrl+p (enter Pane mode)
3. w (toggle floating panes)

# A floating pane appears as an overlay
# Use for quick commands, man pages, or searches
# Press 'w' again to hide floating panes
```

---

## Session Persistence

Zellij automatically persists sessions. If your terminal crashes or you accidentally close it:

```bash
# List all sessions
zellij list-sessions

# Output example:
# main (DETACHED) - created 2h ago
# dev-work (ATTACHED) - created 30m ago

# Reattach to a session
zellij attach main
```

**All your panes, tabs, and running commands will be exactly as you left them.**

---

## Layouts

Layouts are predefined workspace configurations stored in `~/.config/zellij/layouts/`.

### Available Layouts

1. **default.kdl**: Simple 2-pane horizontal split
2. **dev.kdl**: Development workflow (editor + terminal + logs)
3. **admin.kdl**: System administration (monitor + terminal + logs)

### Using Layouts

```bash
# Start with a layout
zellij --layout dev

# Set default layout in config.kdl
# Edit ~/.config/zellij/config.kdl:
# options {
#     default_layout "dev"
# }
```

### Creating Custom Layouts

Layouts are KDL files in `~/.config/zellij/layouts/`. Example:

```kdl
// my-workflow.kdl
layout {
    tab name="Code" {
        pane split_direction="horizontal" {
            pane size="70%" { command "nvim"; }
            pane size="30%" { command "zsh"; }
        }
    }
    tab name="Terminal" {
        pane { command "zsh"; }
    }
}
```

Load with: `zellij --layout my-workflow`

---

## Configuration

Zellij configuration is located at `~/.config/zellij/config.kdl`.

**Managed via chezmoi**: Changes to `~/NixOS/dotfiles/dot_config/zellij/config.kdl` are applied with:

```bash
dotfiles-apply  # Alias for 'chezmoi apply'
```

### Common Customizations

**Change default shell**:
```kdl
options {
    default_shell "bash"  // or "zsh", "fish", etc.
}
```

**Adjust theme colors**:
```kdl
themes {
    my_theme {
        fg "#FFFFFF"
        bg "#000000"
        // ... other colors
    }
}
```

**Modify keybindings**:
```kdl
keybindings {
    normal {
        bind "Ctrl b" { NewPane; SwitchToMode "Locked"; }
    }
}
```

**After editing config**, Zellij auto-reloads. No restart needed.

---

## Tips and Tricks

### 1. Quick Pane Creation
Instead of entering Pane mode, use quick actions from Normal mode:
- `n` - New pane (auto-returns to Locked mode)

### 2. Mouse Support
Zellij supports mouse:
- Click panes to switch focus
- Click tabs to switch
- Drag pane borders to resize

Enable in config:
```kdl
options {
    mouse_mode true
}
```

### 3. Copy/Paste
- Enter Scroll mode (`Ctrl+s`)
- Use mouse to select text (auto-copies to clipboard)
- Or use terminal's built-in copy shortcuts (Ctrl+Shift+C)

Configure copy command:
```kdl
options {
    copy_command "wl-copy"  // Wayland
    # copy_command "xclip -selection clipboard"  // X11
}
```

### 4. Session Auto-attach
Auto-attach to existing session instead of creating new:
```kdl
options {
    attach_to_session true
}
```

### 5. Floating Pane Shortcuts
Use floating panes for:
- Quick file browsing (Strider plugin: `Ctrl+o` → `s`)
- Man pages
- Git status checks
- Calculator or quick commands

### 6. Edit Scrollback
View/search scrollback in your editor:
- Enter Scroll mode (`Ctrl+s`)
- Press `e` to open in `$EDITOR`
- Requires setting: `options { scrollback_editor "nvim"; }`

---

## Troubleshooting

### Issue: Keybindings not working
**Solution**: Check current mode in status bar. You might be in Locked mode.
- Press `Alt+i` to enter Normal mode
- Then try your keybinding

### Issue: Config changes not applying
**Solution**:
1. Validate config: `zellij setup --check`
2. Check for syntax errors in output
3. Apply dotfiles: `dotfiles-apply`
4. Restart Zellij if auto-reload fails

### Issue: Session not persisting
**Solution**:
- Check session wasn't explicitly deleted
- Verify cache directory exists: `~/.cache/zellij/`
- Session may have timed out (default: no timeout)

### Issue: Nested Zellij sessions
**Solution**:
- Avoid launching Zellij within Zellij
- Check `$ZELLIJ` environment variable (set when inside Zellij)
- Add to shell rc: `[[ -n "$ZELLIJ" ]] && return` to prevent nesting

### Issue: Colors look wrong
**Solution**:
- Ensure terminal supports true color
- Check `$TERM` variable: should be `xterm-256color` or similar
- Verify theme colors in config.kdl are valid hex codes

---

## Learning Resources

### Official Documentation
- [Zellij User Guide](https://zellij.dev/documentation/)
- [Configuration Reference](https://zellij.dev/documentation/configuration.html)
- [Layout System](https://zellij.dev/documentation/layouts.html)

### Community Resources
- [Zellij GitHub](https://github.com/zellij-org/zellij)
- [Example Configurations](https://github.com/topics/zellij-config)

### Quick Reference Card

```
┌─────────────────────────────────────────────┐
│         ZELLIJ QUICK REFERENCE              │
├─────────────────────────────────────────────┤
│ START:                                      │
│   zellij                 - Start/attach     │
│   zellij --layout dev    - Use layout       │
│                                             │
│ MODES:                                      │
│   Alt+i        → Normal mode                │
│   Alt+Esc      → Locked mode                │
│   Ctrl+p       → Pane mode                  │
│   Ctrl+t       → Tab mode                   │
│                                             │
│ PANES:                                      │
│   n            - New pane                   │
│   x            - Close pane                 │
│   f            - Fullscreen                 │
│   h/j/k/l      - Navigate                   │
│   w            - Toggle floating            │
│                                             │
│ TABS:                                       │
│   n            - New tab                    │
│   x            - Close tab                  │
│   h/l          - Previous/Next              │
│   1-9          - Jump to tab                │
│                                             │
│ SESSION:                                    │
│   Ctrl+o → d   - Detach                     │
│   Ctrl+q       - Quit                       │
└─────────────────────────────────────────────┘
```

Print this reference and keep it handy while learning Zellij!

---

## Next Steps

1. **Learn basic navigation**: Practice switching modes and creating panes
2. **Try layouts**: Experiment with `dev` and `admin` layouts
3. **Customize config**: Adjust keybindings and theme to your preference
4. **Create your layout**: Design a layout for your most common workflow
5. **Integrate into workflow**: Make Zellij your default terminal multiplexer

**Happy multiplexing!** 🚀
