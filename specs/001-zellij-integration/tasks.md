# Tasks: Zellij Terminal Multiplexer Integration

**Input**: Design documents from `/specs/001-zellij-integration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: No automated tests requested in specification. Validation will be manual functional testing per research.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a NixOS configuration project:
- **NixOS modules**: `/home/notroot/NixOS/modules/`
- **Dotfiles**: `/home/notroot/NixOS/dotfiles/`
- **Documentation**: `/home/notroot/NixOS/specs/001-zellij-integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize dotfiles structure and verify prerequisites

- [ ] T001 Verify chezmoi is installed and initialized at ~/NixOS/dotfiles/
- [ ] T002 Create dotfiles directory structure: dotfiles/dot_config/zellij/ and dotfiles/dot_config/zellij/layouts/
- [ ] T003 Verify current NixOS branch is 001-zellij-integration

**Checkpoint**: Dotfiles structure ready for configuration files

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core NixOS package installation - MUST be complete before user stories

**⚠️ CRITICAL**: This requires NixOS rebuild and must be done on host/default branch according to Constitution Principle I

- [ ] T004 Read modules/packages/default.nix to understand existing terminal package category structure
- [ ] T005 Add zellij package to terminal category in modules/packages/default.nix with inline comment "Terminal multiplexer with modern UI"
- [ ] T006 Validate Nix syntax with: nix flake check
- [ ] T007 Commit package addition to feature branch (001-zellij-integration)
- [ ] T008 Push commit to remote: git push origin 001-zellij-integration
- [ ] T009 Switch to host/default branch: git checkout host/default
- [ ] T010 Merge feature branch: git merge 001-zellij-integration
- [ ] T011 Build NixOS configuration (test only): nixos-rebuild build --flake .#default
- [ ] T012 Apply NixOS configuration: sudo nixos-rebuild switch --flake .#default
- [ ] T013 Verify zellij is installed: which zellij && zellij --version
- [ ] T014 Switch back to feature branch: git checkout 001-zellij-integration

**Checkpoint**: Zellij package installed system-wide - user story implementation can now begin

---

## Phase 3: User Story 1 - Basic Terminal Multiplexing (Priority: P1) 🎯 MVP

**Goal**: Enable basic Zellij functionality with package installation and minimal working configuration

**Independent Test**:
1. Launch Zellij from terminal: `zellij`
2. Create panes using keybindings (Alt+i → Ctrl+p → n)
3. Create tabs using keybindings (Alt+i → Ctrl+t → n)
4. Close terminal window
5. Reopen terminal and run: `zellij attach`
6. Verify session persisted with all panes and tabs intact

### Implementation for User Story 1

- [ ] T015 [P] [US1] Create base config.kdl in dotfiles/dot_config/zellij/config.kdl with minimal structure (keybindings, themes, ui, plugins, options sections)
- [ ] T016 [P] [US1] Add locked mode keybindings to config.kdl (Alt+i to enter Normal mode)
- [ ] T017 [P] [US1] Add normal mode keybindings to config.kdl (Ctrl+p for Pane, Ctrl+t for Tab, Ctrl+s for Scroll, Ctrl+o for Session, Ctrl+q for Quit)
- [ ] T018 [P] [US1] Add pane mode keybindings to config.kdl (h/j/k/l navigation, n for new pane, d for pane down, r for pane right, x to close, f for fullscreen, w for floating toggle)
- [ ] T019 [P] [US1] Add tab mode keybindings to config.kdl (h/l for prev/next, n for new tab, x to close, r for rename)
- [ ] T020 [P] [US1] Add resize mode keybindings to config.kdl (h/j/k/l to resize panes)
- [ ] T021 [P] [US1] Add scroll mode keybindings to config.kdl (j/k for line scroll, d/u for half-page, e for edit scrollback, s for search)
- [ ] T022 [US1] Apply dotfiles with chezmoi: chezmoi add ~/NixOS/dotfiles/dot_config/zellij/config.kdl && chezmoi apply
- [ ] T023 [US1] Validate KDL syntax: zellij setup --check
- [ ] T024 [US1] Launch Zellij and verify it starts: zellij
- [ ] T025 [US1] Test pane creation (Alt+i → Ctrl+p → n) and verify new pane appears
- [ ] T026 [US1] Test pane navigation (Alt+i → Ctrl+p → h/j/k/l) and verify focus changes
- [ ] T027 [US1] Test tab creation (Alt+i → Ctrl+t → n) and verify new tab appears
- [ ] T028 [US1] Test tab switching (Alt+i → Ctrl+t → h/l) and verify tab changes
- [ ] T029 [US1] Test session persistence: close terminal, reopen, run zellij attach, verify session restored
- [ ] T030 [US1] Document test results in verification checklist

**Checkpoint**: At this point, User Story 1 (basic multiplexing) should be fully functional and testable independently

---

## Phase 4: User Story 2 - Optimized Configuration (Priority: P2)

**Goal**: Enhance UX with optimized theme, status bar plugins, and visual improvements

**Independent Test**:
1. Launch Zellij: `zellij`
2. Verify visual theme has clear visual hierarchy (rounded corners, distinct colors)
3. Verify status bar displays system metrics (CPU, memory, time)
4. Test keybindings feel intuitive and responsive
5. Verify pane focus is clearly indicated

### Implementation for User Story 2

- [ ] T031 [P] [US2] Add Nord theme definition to config.kdl themes section (fg, bg, 8 standard colors + orange per research.md)
- [ ] T032 [P] [US2] Configure UI preferences in config.kdl (rounded_corners true, hide_session_name false)
- [ ] T033 [P] [US2] Enable status bar plugins in config.kdl (tab-bar, status-bar, strider, compact-bar)
- [ ] T034 [P] [US2] Configure options in config.kdl (mouse_mode true, copy_command "wl-copy", copy_clipboard "primary", copy_on_select true)
- [ ] T035 [P] [US2] Set default shell in config.kdl options (default_shell "zsh")
- [ ] T036 [P] [US2] Add inline comments to config.kdl explaining each section and key keybindings
- [ ] T037 [US2] Apply dotfiles: chezmoi apply
- [ ] T038 [US2] Validate KDL syntax: zellij setup --check
- [ ] T039 [US2] Launch Zellij and verify Nord theme is applied (check color scheme)
- [ ] T040 [US2] Verify rounded corners are visible on pane frames
- [ ] T041 [US2] Verify status bar displays at bottom with system metrics
- [ ] T042 [US2] Test mouse mode: click panes to switch focus, drag borders to resize
- [ ] T043 [US2] Test copy-on-select: highlight text and verify it copies to clipboard
- [ ] T044 [US2] Verify current pane is clearly indicated (visual focus indicator)
- [ ] T045 [US2] Document theme and UX improvements in verification checklist

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - basic multiplexing with optimized UX

---

## Phase 5: User Story 3 - Custom Layouts (Priority: P3)

**Goal**: Provide predefined workspace layouts for common development workflows

**Independent Test**:
1. Test default layout: `zellij --layout default` and verify 2-pane horizontal split
2. Test dev layout: `zellij --layout dev` and verify 3-pane arrangement (editor + terminal + git)
3. Test admin layout: `zellij --layout admin` and verify monitor + terminal + logs arrangement
4. Verify each layout opens in correct working directory
5. Verify switching between layouts maintains session state

### Implementation for User Story 3

- [ ] T046 [P] [US3] Create default.kdl layout in dotfiles/dot_config/zellij/layouts/default.kdl (simple 2-pane horizontal 50/50 split)
- [ ] T047 [P] [US3] Create dev.kdl layout in dotfiles/dot_config/zellij/layouts/dev.kdl (vertical: 60% editor top, horizontal bottom: 30% terminal left + 10% git logs right, cwd ~/NixOS)
- [ ] T048 [P] [US3] Create admin.kdl layout in dotfiles/dot_config/zellij/layouts/admin.kdl (horizontal: 30% htop left, vertical right: 70% terminal top + 30% journalctl bottom)
- [ ] T049 [US3] Apply dotfiles: chezmoi apply
- [ ] T050 [US3] Test default layout: zellij --layout default and verify 2-pane split
- [ ] T051 [US3] Test dev layout: zellij --layout dev and verify pane arrangement and working directory
- [ ] T052 [US3] Test admin layout: zellij --layout admin and verify htop and journalctl panes
- [ ] T053 [US3] Verify layout loading time <2 seconds (per success criteria SC-004)
- [ ] T054 [US3] Test switching layouts: kill session, start with different layout, verify new arrangement
- [ ] T055 [US3] Document layout usage in verification checklist

**Checkpoint**: All user stories should now be independently functional - full Zellij integration complete

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and final integration

- [ ] T056 [P] Copy quickstart.md from specs/001-zellij-integration/quickstart.md to dotfiles/dot_config/zellij/QUICKSTART.md for easy reference
- [ ] T057 [P] Add Zellij usage section to CLAUDE.md (optional - keybindings reference, session management patterns)
- [ ] T058 Commit all dotfiles changes: git add dotfiles/ && git commit -m "feat(zellij): add Zellij terminal multiplexer with optimized config and layouts"
- [ ] T059 Run final validation: nix flake check && zellij setup --check
- [ ] T060 Create comprehensive test session: launch Zellij, test all keybindings, all layouts, session persistence, verify all success criteria
- [ ] T061 Measure performance: Zellij launch time, session attachment time, layout loading time (verify against SC-006, SC-004)
- [ ] T062 Test edge cases: nested session handling, config error recovery, terminal size changes
- [ ] T063 Verify configuration survives chezmoi reapplication: chezmoi apply && zellij setup --check
- [ ] T064 Document any known issues or workarounds in verification notes
- [ ] T065 Push final commit to feature branch: git push origin 001-zellij-integration
- [ ] T066 Create pull request: 001-zellij-integration → develop (include test results, screenshots if helpful)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
  - ⚠️ **CRITICAL**: Must switch to host/default branch for NixOS rebuild (Constitution Principle I)
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if multiple developers)
  - Or sequentially in priority order: US1 → US2 → US3
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Builds on US1 config but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends configuration but independently testable

### Within Each User Story

#### US1: Basic Terminal Multiplexing
- T015-T021: All keybinding configuration tasks [P] - can run in parallel
- T022-T030: Sequential validation and testing (depends on T015-T021 complete)

#### US2: Optimized Configuration
- T031-T036: All configuration tasks [P] - can run in parallel
- T037-T045: Sequential validation and testing (depends on T031-T036 complete)

#### US3: Custom Layouts
- T046-T048: All layout creation tasks [P] - can run in parallel
- T049-T055: Sequential validation and testing (depends on T046-T048 complete)

### Parallel Opportunities

**Phase 1 (Setup)**: All tasks sequential (directory checks and creation)

**Phase 2 (Foundational)**: Tasks sequential due to git workflow requirements and NixOS rebuild process

**Phase 3 (US1)**:
- Parallel: T015, T016, T017, T018, T019, T020, T021 (all keybinding sections)
- Sequential: T022-T030 (validation and testing)

**Phase 4 (US2)**:
- Parallel: T031, T032, T033, T034, T035, T036 (all config enhancements)
- Sequential: T037-T045 (validation and testing)

**Phase 5 (US3)**:
- Parallel: T046, T047, T048 (all layout files)
- Sequential: T049-T055 (validation and testing)

**Phase 6 (Polish)**:
- Parallel: T056, T057 (documentation tasks)
- Sequential: T058-T066 (final validation and PR creation)

---

## Parallel Example: User Story 1

```bash
# Launch all keybinding configuration tasks together:
Task: "Add locked mode keybindings to config.kdl"
Task: "Add normal mode keybindings to config.kdl"
Task: "Add pane mode keybindings to config.kdl"
Task: "Add tab mode keybindings to config.kdl"
Task: "Add resize mode keybindings to config.kdl"
Task: "Add scroll mode keybindings to config.kdl"

# Then proceed sequentially with validation:
Task: "Apply dotfiles with chezmoi"
Task: "Validate KDL syntax"
Task: "Test pane creation..."
```

---

## Parallel Example: User Story 2

```bash
# Launch all configuration enhancement tasks together:
Task: "Add Nord theme definition to config.kdl"
Task: "Configure UI preferences in config.kdl"
Task: "Enable status bar plugins in config.kdl"
Task: "Configure options in config.kdl"
Task: "Set default shell in config.kdl"
Task: "Add inline comments to config.kdl"

# Then proceed sequentially with validation:
Task: "Apply dotfiles"
Task: "Validate KDL syntax"
Task: "Verify theme and UX improvements..."
```

---

## Parallel Example: User Story 3

```bash
# Launch all layout creation tasks together:
Task: "Create default.kdl layout"
Task: "Create dev.kdl layout"
Task: "Create admin.kdl layout"

# Then proceed sequentially with validation:
Task: "Apply dotfiles"
Task: "Test each layout..."
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T014) - **CRITICAL: Requires host/default branch**
3. Complete Phase 3: User Story 1 (T015-T030)
4. **STOP and VALIDATE**: Test basic multiplexing independently
5. If successful, this is a working MVP - basic Zellij functionality available

### Incremental Delivery

1. Complete Setup + Foundational → Zellij package installed
2. Add User Story 1 → Test independently → Basic multiplexing works (MVP!)
3. Add User Story 2 → Test independently → Enhanced UX and theme
4. Add User Story 3 → Test independently → Productivity layouts available
5. Polish → Final documentation and validation
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (basic config and keybindings)
   - Developer B: User Story 2 (theme and UX enhancements) - can start in parallel
   - Developer C: User Story 3 (layout templates) - can start in parallel
3. Stories integrate via shared config.kdl and layout files
4. Final validation ensures all pieces work together

**Note**: For this feature, sequential execution is recommended since all tasks modify the same configuration file (config.kdl). Parallel execution would require careful coordination to avoid merge conflicts.

---

## Success Criteria Validation

Each user story must validate against these success criteria from spec.md:

### User Story 1 Validation
- **SC-001**: Verify pane creation, split, and navigation <5 seconds ✓ (T025-T026)
- **SC-002**: Verify session persistence across disconnections ✓ (T029)
- **SC-003**: Verify config loads without errors ✓ (T023)
- **SC-006**: Verify Zellij launches <1 second ✓ (T061)

### User Story 2 Validation
- **SC-001**: Verify keybindings are intuitive and responsive ✓ (T042)
- **SC-003**: Verify enhanced config loads without errors ✓ (T038)
- **SC-005**: Verify status bar updates every 2 seconds ✓ (T041)
- **SC-007**: Verify changes apply via chezmoi without rebuild ✓ (T063)

### User Story 3 Validation
- **SC-004**: Verify layout loading <2 seconds ✓ (T053)
- **SC-001**: Verify layouts enable quick workflow setup ✓ (T050-T052)
- **SC-007**: Verify layout changes apply without rebuild ✓ (T063)

---

## Notes

- [P] tasks = different files/sections, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each logical group of tasks (e.g., after each user story phase)
- Stop at any checkpoint to validate story independently
- All dotfiles changes managed via chezmoi - no NixOS rebuild needed except Phase 2
- **CRITICAL**: Follow Constitution Principle I for NixOS rebuilds (host/default branch only)
- KDL syntax validation before applying: `zellij setup --check`
- Manual functional testing per research.md testing strategy
