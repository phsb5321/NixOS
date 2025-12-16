# Tasks: Flake-Parts Integration for Multi-Host NixOS

**Input**: Design documents from `/specs/001-flake-parts-integration/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Tests are NOT explicitly requested in the feature specification. This migration is validated through system builds and flake checks rather than dedicated test files.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **NixOS Config**: Repository root (`/home/notroot/NixOS`)
- **Flake modules**: `flake-modules/` (to be created)
- **Existing structure**: `hosts/`, `modules/` (unchanged)

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Prepare for migration by backing up and creating directory structure

- [ ] T001 Backup current flake.nix to flake.nix.backup
- [ ] T002 Create flake-modules/ directory
- [ ] T003 Verify flake-parts input exists in flake.nix inputs section
- [ ] T004 Commit checkpoint before migration starts

**Checkpoint**: Setup complete - ready to begin migration

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core flake-parts setup that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Wrap flake.nix outputs in flake-parts.lib.mkFlake structure
- [ ] T006 Declare systems array with x86_64-linux and aarch64-linux
- [ ] T007 Add empty imports array for future flake-modules
- [ ] T008 Create escape hatch flake = { } block preserving all current outputs
- [ ] T009 Move all existing output generation into escape hatch (nixosConfigurations, formatter, checks, apps, devShells)
- [ ] T010 Format code with alejandra
- [ ] T011 Validate Phase 2: Run nix flake check
- [ ] T012 Validate Phase 2: Build desktop with nixos-rebuild build --flake .#desktop
- [ ] T013 Validate Phase 2: Build laptop with nixos-rebuild build --flake .#laptop
- [ ] T014 Validate Phase 2: Test nix flake show displays all outputs
- [ ] T015 Validate Phase 2: Test nix develop enters dev shell
- [ ] T016 Validate Phase 2: Test nix fmt formats code
- [ ] T017 Commit Phase 2 with message "feat(flake): setup flake-parts with escape hatch"

**Checkpoint**: Foundation ready - user story implementation can now begin independently

---

## Phase 3: User Story 1 - Modular Flake Structure (Priority: P1) 🎯 MVP

**Goal**: Organize multi-host configuration using flake-parts modules with modular structure

**Independent Test**: Both hosts build successfully with `nixos-rebuild build --flake .#desktop` and `nixos-rebuild build --flake .#laptop`, all outputs accessible via `nix flake show`

### Implementation for User Story 1

#### Part A: Migrate Per-System Outputs

- [ ] T018 [US1] Create flake-modules/outputs.nix with perSystem function signature
- [ ] T019 [US1] Implement checks in perSystem.checks (format-check, lint-check, deadnix-check) in flake-modules/outputs.nix
- [ ] T020 [US1] Implement formatter as perSystem.formatter = pkgs.alejandra in flake-modules/outputs.nix
- [ ] T021 [US1] Implement default dev shell in perSystem.devShells.default with nixos-rebuild, git, alejandra, statix, deadnix in flake-modules/outputs.nix
- [ ] T022 [US1] Implement apps in perSystem.apps (format, update, check-config) in flake-modules/outputs.nix
- [ ] T023 [US1] Implement packages in perSystem.packages (deploy, build scripts) in flake-modules/outputs.nix
- [ ] T024 [US1] Add ./flake-modules/outputs.nix to imports array in flake.nix
- [ ] T025 [US1] Remove per-system outputs from escape hatch (keep only nixosConfigurations) in flake.nix
- [ ] T026 [US1] Format code with alejandra
- [ ] T027 [US1] Validate US1 Part A: Run nix flake check
- [ ] T028 [US1] Validate US1 Part A: Test nix develop enters dev shell
- [ ] T029 [US1] Validate US1 Part A: Test nix fmt flake.nix formats code
- [ ] T030 [US1] Validate US1 Part A: Test nix run .#format works
- [ ] T031 [US1] Validate US1 Part A: Test nix run .#update works
- [ ] T032 [US1] Validate US1 Part A: Test nix build .#deploy succeeds
- [ ] T033 [US1] Commit US1 Part A with message "feat(flake): migrate per-system outputs to perSystem"

#### Part B: Migrate Host Configurations

- [ ] T034 [US1] Create flake-modules/hosts.nix with flake.nixosConfigurations structure
- [ ] T035 [US1] Define pkgsConfig attrset in flake-modules/hosts.nix
- [ ] T036 [US1] Implement mkNixosSystem function using withSystem for perSystem context in flake-modules/hosts.nix
- [ ] T037 [US1] Add systemVersion calculation logic to mkNixosSystem in flake-modules/hosts.nix
- [ ] T038 [US1] Add package set creation (pkgs, pkgs-unstable) in mkNixosSystem in flake-modules/hosts.nix
- [ ] T039 [US1] Add baseSpecialArgs with inputs, self', inputs', systemVersion, hostname, pkgs-unstable, stablePkgs in flake-modules/hosts.nix
- [ ] T040 [US1] Add nixosSystem call with modules (host config, base system config) in mkNixosSystem in flake-modules/hosts.nix
- [ ] T041 [US1] Define hosts attrset with desktop and laptop entries in flake-modules/hosts.nix
- [ ] T042 [US1] Set desktop host to use nixpkgsInput = inputs.nixpkgs-unstable in flake-modules/hosts.nix
- [ ] T043 [US1] Set laptop host to use default nixpkgs (stable) in flake-modules/hosts.nix
- [ ] T044 [US1] Generate nixosConfigurations with mapAttrs over hosts in flake-modules/hosts.nix
- [ ] T045 [US1] Add compatibility aliases (nixos, nixos-desktop, nixos-laptop, default) in flake-modules/hosts.nix
- [ ] T046 [US1] Add ./flake-modules/hosts.nix to imports array in flake.nix
- [ ] T047 [US1] Remove escape hatch flake = { } block entirely from flake.nix
- [ ] T048 [US1] Verify flake.nix is now minimal (~30 lines) with only mkFlake, systems, and imports
- [ ] T049 [US1] Format code with alejandra
- [ ] T050 [US1] Validate US1 Part B: Run nix flake show to verify structure
- [ ] T051 [US1] Validate US1 Part B: Build desktop with nixos-rebuild build --flake .#desktop
- [ ] T052 [US1] Validate US1 Part B: Build laptop with nixos-rebuild build --flake .#laptop
- [ ] T053 [US1] Validate US1 Part B: Test alias nixos builds with nixos-rebuild build --flake .#nixos
- [ ] T054 [US1] Validate US1 Part B: Test alias default builds with nixos-rebuild build --flake .#default
- [ ] T055 [US1] Validate US1 Part B: Run nix flake check passes
- [ ] T056 [US1] Validate US1 Part B: Test nix develop still works
- [ ] T057 [US1] Commit US1 Part B with message "feat(flake): migrate nixosConfigurations to flake-parts"

**Checkpoint**: User Story 1 is now complete - modular flake structure fully implemented and tested

---

## Phase 4: User Story 2 - Per-Host Custom Outputs (Priority: P2)

**Goal**: Enable host-specific development shells, deployment scripts, and VM tests

**Independent Test**: Host-specific outputs appear in `nix flake show` and are accessible via `nix develop .#desktop`, `nix run .#laptop-<script>`

**Note**: This story builds on US1's foundation. The basic per-system outputs are already in place. This phase adds the capability for hosts to define their own custom outputs.

### Implementation for User Story 2

- [ ] T058 [US2] Document pattern for per-host devShells in flake-modules/outputs.nix comments
- [ ] T059 [US2] Add example desktop-specific devShell to perSystem.devShells.desktop in flake-modules/outputs.nix
- [ ] T060 [US2] Add desktop-specific tools to desktop devShell (AMD GPU utils, gaming tools) in flake-modules/outputs.nix
- [ ] T061 [US2] Add example laptop-specific devShell to perSystem.devShells.laptop in flake-modules/outputs.nix
- [ ] T062 [US2] Add laptop-specific tools to laptop devShell (power management, battery utils) in flake-modules/outputs.nix
- [ ] T063 [US2] Document pattern for per-host apps in flake-modules/outputs.nix comments
- [ ] T064 [US2] Add example laptop-specific app (battery-check) to perSystem.apps in flake-modules/outputs.nix
- [ ] T065 [US2] Document pattern for per-host VM tests in flake-modules/outputs.nix comments (note: implementation would require VM test infrastructure)
- [ ] T066 [US2] Format code with alejandra
- [ ] T067 [US2] Validate US2: Run nix flake show and verify host-specific outputs listed
- [ ] T068 [US2] Validate US2: Test nix develop .#desktop enters desktop-specific shell
- [ ] T069 [US2] Validate US2: Test nix develop .#laptop enters laptop-specific shell
- [ ] T070 [US2] Validate US2: Test nix run .#battery-check executes laptop app
- [ ] T071 [US2] Validate US2: Run nix flake check passes
- [ ] T072 [US2] Commit US2 with message "feat(flake): add per-host custom outputs (devShells, apps)"

**Checkpoint**: User Story 2 complete - hosts can now define custom outputs independently

---

## Phase 5: User Story 3 - Shared Module System (Priority: P3)

**Goal**: Define shared functionality in flake-parts modules for composition across hosts

**Independent Test**: Extract common configuration into shared modules, verify both hosts build with shared config

**Note**: This story demonstrates the shared module capability by creating optional reusable modules.

### Implementation for User Story 3

- [ ] T073 [US3] Create flake-modules/README.md documenting module structure
- [ ] T074 [US3] Document flake-modules/hosts.nix purpose and usage in README.md
- [ ] T075 [US3] Document flake-modules/outputs.nix purpose and usage in README.md
- [ ] T076 [US3] Document how to add new hosts in README.md
- [ ] T077 [US3] Document how to add per-system outputs in README.md
- [ ] T078 [US3] Document benefits of flake-parts structure in README.md
- [ ] T079 [US3] Add example shared module pattern (commented out) in flake-modules/hosts.nix
- [ ] T080 [US3] Document how hosts can import shared modules in comments in flake-modules/hosts.nix
- [ ] T081 [US3] Add inline documentation for mkNixosSystem parameters in flake-modules/hosts.nix
- [ ] T082 [US3] Add inline documentation for host definition structure in flake-modules/hosts.nix
- [ ] T083 [US3] Format code with alejandra
- [ ] T084 [US3] Validate US3: Verify README.md covers all module patterns
- [ ] T085 [US3] Validate US3: Run nix flake check passes
- [ ] T086 [US3] Validate US3: Build both hosts to confirm shared patterns work
- [ ] T087 [US3] Commit US3 with message "docs(flake): add shared module system documentation"

**Checkpoint**: All user stories complete - shared module system documented and ready for use

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting the entire migration

- [ ] T088 [P] Update CLAUDE.md with flake-parts structure section after Architecture Overview
- [ ] T089 [P] Document flake.nix entry point structure in CLAUDE.md
- [ ] T090 [P] Document flake-modules/hosts.nix purpose in CLAUDE.md
- [ ] T091 [P] Document flake-modules/outputs.nix purpose in CLAUDE.md
- [ ] T092 [P] Document how to add new hosts in CLAUDE.md
- [ ] T093 [P] Document benefits of flake-parts in CLAUDE.md
- [ ] T094 Measure line count reduction: flake.nix before vs after
- [ ] T095 Measure total line count: flake.nix + flake-modules/*.nix
- [ ] T096 Measure evaluation time baseline (current)
- [ ] T097 Measure evaluation time after migration
- [ ] T098 Verify evaluation time is within 5% of baseline
- [ ] T099 Final validation: Run alejandra . to format all code
- [ ] T100 Final validation: Run nix flake check
- [ ] T101 Final validation: Build desktop with nixos-rebuild build --flake .#desktop
- [ ] T102 Final validation: Build laptop with nixos-rebuild build --flake .#laptop
- [ ] T103 Final validation: Test all aliases (nixos, nixos-desktop, nixos-laptop, default)
- [ ] T104 Final validation: Test nix develop works
- [ ] T105 Final validation: Test nix fmt works
- [ ] T106 Final validation: Test all apps (format, update, check-config) work
- [ ] T107 Final validation: Test all packages (deploy, build) build
- [ ] T108 Final validation: Verify nix flake metadata shows correct structure
- [ ] T109 Final validation: Verify nix flake show displays all outputs
- [ ] T110 Commit polish phase with message "docs(flake): document flake-parts migration"
- [ ] T111 Optional: Remove flake.nix.backup after confirming everything works
- [ ] T112 Optional: Commit cleanup with message "chore: remove flake.nix backup"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
  - Part A (migrate perSystem): Independent
  - Part B (migrate hosts): Depends on Part A completion
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (needs perSystem foundation)
- **User Story 3 (Phase 5)**: Depends on User Story 1 completion (needs modular structure)
  - Can run in parallel with User Story 2 if staffed
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Must complete first - foundation for all others
  - Part A: No dependencies within US1
  - Part B: Depends on Part A
- **User Story 2 (P2)**: Depends on US1 (needs perSystem structure)
- **User Story 3 (P3)**: Depends on US1 (needs modular structure)
- **US2 and US3 can run in parallel** after US1 completes

### Within Each User Story

User Story 1 Part A (Per-System Outputs):
- T018-T023: Can run in parallel (different output types)
- T024-T025: Sequential (modify flake.nix)
- T026-T033: Sequential validation and commit

User Story 1 Part B (Host Configurations):
- T034-T045: Sequential (building mkNixosSystem and hosts)
- T046-T048: Sequential (modify flake.nix)
- T049-T057: Sequential validation and commit

User Story 2:
- T058-T065: Can run in parallel (different outputs)
- T066-T072: Sequential validation and commit

User Story 3:
- T073-T082: Can run in parallel (different documentation tasks)
- T083-T087: Sequential validation and commit

Polish Phase:
- T088-T093: Can run in parallel (different CLAUDE.md sections)
- T094-T098: Sequential (measurements)
- T099-T109: Sequential validation
- T110-T112: Sequential commits

### Parallel Opportunities

```bash
# Within Foundational Phase:
# (No parallel - escape hatch setup is sequential)

# User Story 1 Part A - Create outputs:
Task: "Implement checks in perSystem.checks in flake-modules/outputs.nix"
Task: "Implement formatter in flake-modules/outputs.nix"
Task: "Implement default dev shell in flake-modules/outputs.nix"
Task: "Implement apps in perSystem.apps in flake-modules/outputs.nix"
Task: "Implement packages in perSystem.packages in flake-modules/outputs.nix"

# User Story 2 - Add per-host outputs:
Task: "Add desktop devShell in flake-modules/outputs.nix"
Task: "Add laptop devShell in flake-modules/outputs.nix"
Task: "Add laptop app in flake-modules/outputs.nix"

# User Story 3 - Documentation:
Task: "Document hosts.nix in README.md"
Task: "Document outputs.nix in README.md"
Task: "Add inline docs in hosts.nix"
Task: "Add inline docs in outputs.nix"

# Polish Phase - CLAUDE.md updates:
Task: "Update CLAUDE.md flake-parts section"
Task: "Document benefits in CLAUDE.md"
Task: "Document new host process in CLAUDE.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 Part A (perSystem outputs)
4. Complete Phase 3: User Story 1 Part B (host configurations)
5. **STOP and VALIDATE**: Test both hosts build, all outputs work
6. Optionally proceed to US2 and US3 for enhancement

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Commit (MVP - modular structure)
3. Add User Story 2 → Test independently → Commit (per-host outputs capability)
4. Add User Story 3 → Test independently → Commit (shared modules documented)
5. Polish Phase → Final validation → Commit
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once User Story 1 completes:
   - Developer A: User Story 2 (per-host outputs)
   - Developer B: User Story 3 (shared modules doc)
   - Developer C: Polish phase preparation
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- This is a configuration migration, not software development - validation is via builds, not tests
- Commit after each user story completes
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- The quickstart.md provides detailed step-by-step instructions for each task
- File paths are relative to repository root (/home/notroot/NixOS)

---

## Task Statistics

- **Total Tasks**: 112
- **Setup Phase**: 4 tasks
- **Foundational Phase**: 13 tasks
- **User Story 1**: 40 tasks (Part A: 16, Part B: 24)
- **User Story 2**: 15 tasks
- **User Story 3**: 15 tasks
- **Polish Phase**: 25 tasks

**Parallelizable Tasks**: 23 (20.5% of total)

**Critical Path**: Setup → Foundational → US1 Part A → US1 Part B → Validation → Polish (estimated 2-3 hours)

**MVP Scope**: Phases 1-3 (User Story 1) = 57 tasks - delivers core modular flake structure
