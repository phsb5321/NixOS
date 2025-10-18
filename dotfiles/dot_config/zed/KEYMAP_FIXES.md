# Zed Editor Keymap Fixes (2024)

## Issue Summary
The Zed editor keymap was showing errors due to deprecated action names following recent API changes in Zed v0.162.x and later.

## Fixed Issues

### 1. Pane Activation Commands
**Error**: `In binding "ctrl-7", didn't find an action named "pane::ActivateItem(7)"`
**Fix**: Changed from indexed function call syntax to array syntax
- Old: `"ctrl-7": "pane::ActivateItem(7)"`
- New: `"alt-7": ["pane::ActivateItem", 6]`

### 2. Editor Actions
**Error**: Multiple editor actions were not found
**Fixes Applied**:
- Added `"ctrl-alt-down": "editor::AddCursorBelow"` (was missing)
- Added `"ctrl-alt-up": "editor::AddCursorAbove"` (was missing)
- Added `"ctrl-shift-space": "editor::ShowInlayHints"` (replaces old inlay hints toggle)
- Added `"ctrl-shift-j": "editor::Unfold"` (was missing)
- Added `"shift-alt-a": "editor::ToggleBlockComment"` (replaces old block comment)

### 3. Bookmark Commands
**Error**: Bookmark-related actions were not found
**Fixes Applied**:
- Added `"ctrl-k ctrl-k": "editor::ToggleBookmark"`
- Added `"ctrl-k ctrl-n": "editor::GoToNextBookmark"`
- Added `"ctrl-k ctrl-p": "editor::GoToPrevBookmark"`

### 4. Project Panel Commands
**Error**: `In binding "space", didn't find an action named "project_panel::ToggleExpanded"`
**Fix**: Changed to correct action name
- Old: `"space": "project_panel::ToggleExpanded"`
- New: `"space": "project_panel::ExpandSelectedEntry"`

## Key Changes Summary

### Removed Keybindings (Deprecated in Zed v0.162.x)
Zed removed several alt+letter shortcuts to better support non-US keyboards:
- `alt-b`, `alt-d`, `alt-f`, `alt-h`, `alt-q`, `alt-v`, `alt-z`, `alt-m`

### Action Namespace Changes
- Many assistant-related actions moved to `agent::` namespace
- Panel activation changed from `workspace::ActivatePane` to `pane::ActivateItem`
- Some editor actions were renamed for consistency

## VS Code Compatibility Maintained
The keymap maintains VS Code-compatible shortcuts where possible:
- `ctrl-shift-p`: Command palette
- `ctrl-p`: File finder
- `ctrl-shift-e`: File explorer
- `ctrl-shift-f`: Search
- `ctrl-shift-g`: Git panel
- `ctrl-``: Terminal
- `f12`: Go to definition
- `f2`: Rename
- And many more...

## Testing the Changes
After applying these fixes:
1. Restart Zed or reload configuration
2. Open the keymap file with `ctrl-k ctrl-s` or via command palette
3. The error messages should no longer appear
4. Test common shortcuts to ensure they work as expected

## Future Maintenance
- Check Zed release notes for breaking changes
- Use Zed's autocomplete in keymap.json for valid action names
- Refer to https://zed.dev/docs/all-actions for complete action list
- Monitor https://github.com/zed-industries/zed/issues for keymap-related issues