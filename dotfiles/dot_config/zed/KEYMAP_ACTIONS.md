# Zed Editor Action Names Reference

**Purpose**: Quick reference for valid Zed editor action names and common deprecations
**Last Updated**: 2025-12-04
**Zed Version**: Stable 2024-2025

## Quick Action Lookup

### Valid Action Name Format

Actions follow: `namespace::ActionName`

**Examples**:
- ✅ `editor::AddSelectionBelow`
- ✅ `workspace::Save`
- ✅ `command_palette::Toggle`

## Common Actions by Category

### Multi-Cursor & Selection
```
editor::AddSelectionBelow       # Ctrl+Alt+Down
editor::AddSelectionAbove       # Ctrl+Alt+Up
editor::SelectAll              # Ctrl+A
editor::SelectLine             # Ctrl+L
editor::SelectNext             # Ctrl+D (next occurrence)
editor::SelectAllMatches       # Ctrl+Shift+L
```

### Code Editing
```
editor::ToggleComments         # Ctrl+/ (line comments)
editor::Format                 # Shift+Alt+F
editor::ToggleInlayHints       # Ctrl+Shift+Space
editor::ToggleCodeActions      # Ctrl+.
editor::ShowCompletions        # Ctrl+Space
```

### Navigation
```
editor::GoToDefinition         # F12
editor::GoToTypeDefinition     # Ctrl+F12
editor::FindAllReferences      # Shift+F12
editor::Rename                 # F2
```

### Search
```
buffer_search::Deploy          # Ctrl+F (find in file)
workspace::NewSearch           # Ctrl+Shift+F (find in project)
search::SelectNextMatch        # F3
search::SelectPrevMatch        # Shift+F3
```

### Workspace
```
file_finder::Toggle            # Ctrl+P
command_palette::Toggle        # Ctrl+Shift+P
outline::Toggle                # Ctrl+Shift+O
workspace::Save                # Ctrl+S
workspace::NewFile             # Ctrl+N
```

## ⚠️ Deprecated Actions (DO NOT USE)

### Renamed Actions
| Deprecated | Current | Reason |
|------------|---------|--------|
| `editor::AddCursorBelow` | `editor::AddSelectionBelow` | Adds selections, not just cursors |
| `editor::AddCursorAbove` | `editor::AddSelectionAbove` | Adds selections, not just cursors |
| `editor::ShowInlayHints` | `editor::ToggleInlayHints` | Action toggles, not just shows |

### Removed Actions
- ❌ `editor::ToggleBookmark` - Feature removed
- ❌ `editor::GoToNextBookmark` - Feature removed
- ❌ `editor::GoToPrevBookmark` - Feature removed
- ❌ `extensions::Toggle` - Action doesn't exist
- ❌ `editor::Unfold` - Invalid action
- ❌ `search::ReplaceInProject` - Use `workspace::NewSearch`
- ❌ `editor::ToggleBlockComment` - Use `editor::ToggleComments`

## Finding Action Names

### Method 1: Command Palette
1. `Ctrl+Shift+P` → Open command palette
2. Type desired action
3. Right-click → "Copy Action Name"

### Method 2: Keymap Autocomplete
1. `Ctrl+K Ctrl+S` → Open keymap editor
2. Start typing → Autocomplete shows valid actions

### Method 3: Official Docs
- [All Actions List](https://zed.dev/docs/all-actions)
- [Key Bindings Guide](https://zed.dev/docs/key-bindings)

## Validation

Test your keymap changes:
```bash
# 1. Validate JSON syntax
jq empty ~/.config/zed/keymap.json

# 2. Launch Zed and check for errors
zed

# 3. Test keybindings work
# Press the key combos and verify expected behavior
```

## Related Documentation

- Full configuration guide: [README.md](./README.md)
- Feature spec: `~/NixOS/specs/001-zed-dotfiles/spec.md`
- Research notes: `~/NixOS/specs/001-zed-dotfiles/research.md`
- Action mappings: `~/NixOS/specs/001-zed-dotfiles/contracts/action-mappings.json`

---

**Last Fix**: 2025-12-04 - Replaced 3 renamed actions, removed 7 invalid actions (commit 11b94c1)
