# Implementation Tasks: NixOS Codebase Optimization & Reduction

**Feature**: 002-codebase-reduction | **Branch**: `002-codebase-reduction` | **Date**: 2025-11-25
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Summary

This task list breaks down the codebase reduction feature into ~150 actionable tasks organized by implementation phase. Target: 25% reduction (~1457 lines) while maintaining 100% feature parity.

**Task Format**: `- [ ] [TaskID] [Priority] [Story] Description (file: path)`

**Priorities**: P1 (MVP), P2 (Important), P3 (Polish)
**Stories**: US1 (Consolidate modules), US2 (Extract helpers), US3 (Optimize options)

---

## Phase 0: Setup & Baseline (10 tasks)

### Baseline Metrics & Validation

- [X] [T001] [P1] [US1] Generate baseline line count metrics for all modules (file: metrics-baseline.txt)
- [X] [T002] [P1] [US1] Document current total lines: `wc -l modules/**/*.nix` (file: metrics-baseline.txt)
- [X] [T003] [P1] [US1] Create per-category line counts for progress tracking (file: metrics-baseline.txt)
- [X] [T004] [P1] [US1] Build desktop configuration and capture system path (file: baseline-desktop-path.txt)
- [ ] [T005] [P1] [US1] Build laptop configuration and capture system path (file: baseline-laptop-path.txt)
- [X] [T006] [P1] [US1] Capture desktop system derivation: `nix derivation show $(readlink -f /run/current-system)` (file: baseline-desktop-derivation.json)
- [X] [T007] [P1] [US1] Capture desktop enabled services: `systemctl list-units --state=active` (file: baseline-desktop-services.txt)
- [X] [T008] [P1] [US1] Run initial flake check and document status (file: baseline-flake-check.log)
- [X] [T009] [P1] [US1] Measure baseline build time for desktop config (file: metrics-baseline.txt)
- [ ] [T010] [P1] [US1] Measure baseline build time for laptop config (file: metrics-baseline.txt)

---

## Phase 1: Helper Function Library (20 tasks)

### Core Helper Functions (lib/builders.nix)

- [X] [T011] [P2] [US2] Create `mkCategoryModule` builder for package categories (file: lib/builders.nix)
- [X] [T012] [P2] [US2] Add docstring to `mkCategoryModule` with signature and usage example (file: lib/builders.nix)
- [X] [T013] [P2] [US2] Create `mkServiceModule` builder for simple service modules (file: lib/builders.nix)
- [X] [T014] [P2] [US2] Add docstring to `mkServiceModule` with signature and usage example (file: lib/builders.nix)
- [X] [T015] [P2] [US2] Create `mkGPUModule` builder for GPU configuration modules (file: lib/builders.nix)
- [X] [T016] [P2] [US2] Add docstring to `mkGPUModule` with signature and usage example (file: lib/builders.nix)
- [X] [T017] [P2] [US2] Create `mkDocumentToolModule` builder for document-tools.nix sections (file: lib/builders.nix)
- [X] [T018] [P2] [US2] Add docstring to `mkDocumentToolModule` with signature and usage example (file: lib/builders.nix)
- [X] [T019] [P2] [US2] Create `mkImportList` helper for auto-importing directory modules (file: lib/builders.nix)
- [X] [T020] [P2] [US2] Add docstring to `mkImportList` with signature and usage example (file: lib/builders.nix)

### Utility Helpers (lib/utils.nix)

- [X] [T021] [P2] [US2] Create `mkConditionalPackages` helper for conditional package lists (file: lib/utils.nix)
- [X] [T022] [P2] [US2] Add docstring to `mkConditionalPackages` with signature and usage example (file: lib/utils.nix)
- [X] [T023] [P2] [US2] Create `mkOptionDefault` helper for simplified option definitions (file: lib/utils.nix)
- [X] [T024] [P2] [US2] Add docstring to `mkOptionDefault` with signature and usage example (file: lib/utils.nix)
- [X] [T025] [P2] [US2] Create `mkMergedOptions` helper for combining option sets (file: lib/utils.nix)
- [X] [T026] [P2] [US2] Add docstring to `mkMergedOptions` with signature and usage example (file: lib/utils.nix)

### Library Integration

- [X] [T027] [P2] [US2] Export all new builders from lib/default.nix (file: lib/default.nix)
- [X] [T028] [P2] [US2] Export all new utilities from lib/default.nix (file: lib/default.nix)
- [X] [T029] [P2] [US2] Create lib/README.md documenting all 10 helper functions (file: lib/README.md)
- [X] [T030] [P2] [US2] Add usage examples for each helper in lib/README.md (file: lib/README.md)

---

## Phase 2: Module Consolidation (US1 - P1) (25 tasks)

### CONS-001: Networking Module Merge (LOW RISK)

- [ ] [T031] [P1] [US1] Backup modules/networking/default.nix before merge (file: modules/networking/default.nix.bak)
- [ ] [T032] [P1] [US1] Backup modules/core/networking.nix before merge (file: modules/core/networking.nix.bak)
- [ ] [T033] [P1] [US1] Analyze option overlap between core/networking.nix and networking/default.nix (file: analysis-cons-001.txt)
- [ ] [T034] [P1] [US1] Merge option definitions from core/networking.nix into networking/default.nix (file: modules/networking/default.nix)
- [ ] [T035] [P1] [US1] Merge config sections from core/networking.nix into networking/default.nix (file: modules/networking/default.nix)
- [ ] [T036] [P1] [US1] Remove duplicate firewall rules between merged modules (file: modules/networking/default.nix)
- [ ] [T037] [P1] [US1] Delete modules/core/networking.nix after successful merge (file: modules/core/networking.nix)
- [ ] [T038] [P1] [US1] Update any host imports referencing core/networking.nix (file: hosts/*/configuration.nix)
- [ ] [T039] [P1] [US1] Run nix flake check after CONS-001 merge (file: validation-cons-001.log)
- [ ] [T040] [P1] [US1] Build desktop config after CONS-001 merge (file: validation-cons-001.log)
- [ ] [T041] [P1] [US1] Build laptop config after CONS-001 merge (file: validation-cons-001.log)
- [ ] [T042] [P1] [US1] Compare desktop derivation after CONS-001 (should be identical except timestamps) (file: validation-cons-001-derivation.diff)
- [ ] [T043] [P1] [US1] Measure line reduction from CONS-001 (target: ~74 lines saved) (file: metrics-cons-001.txt)
- [ ] [T044] [P1] [US1] Commit CONS-001 merge with conventional commit message (file: git log)

### CONS-002: Laptop Config Merge (MEDIUM RISK)

- [ ] [T045] [P1] [US1] Backup modules/hardware/laptop.nix before merge (file: modules/hardware/laptop.nix.bak)
- [ ] [T046] [P1] [US1] Backup modules/profiles/laptop.nix before merge (file: modules/profiles/laptop.nix.bak)
- [ ] [T047] [P1] [US1] Analyze option overlap between hardware/laptop.nix and profiles/laptop.nix (file: analysis-cons-002.txt)
- [ ] [T048] [P1] [US1] Merge power management settings from profiles into hardware module (file: modules/hardware/laptop.nix)
- [ ] [T049] [P1] [US1] Merge battery optimization settings from profiles into hardware module (file: modules/hardware/laptop.nix)
- [ ] [T050] [P1] [US1] Merge zram configuration from profiles into hardware module (file: modules/hardware/laptop.nix)
- [ ] [T051] [P1] [US1] Preserve profile abstraction layer for potential future use (file: modules/hardware/laptop.nix)
- [ ] [T052] [P1] [US1] Delete modules/profiles/laptop.nix after successful merge (file: modules/profiles/laptop.nix)
- [ ] [T053] [P1] [US1] Update laptop host imports to use consolidated hardware module (file: hosts/laptop/configuration.nix)
- [ ] [T054] [P1] [US1] Run nix flake check after CONS-002 merge (file: validation-cons-002.log)
- [ ] [T055] [P1] [US1] Build laptop config after CONS-002 merge (file: validation-cons-002.log)
- [ ] [T056] [P1] [US1] Compare laptop derivation after CONS-002 (should be identical except timestamps) (file: validation-cons-002-derivation.diff)
- [ ] [T057] [P1] [US1] Measure line reduction from CONS-002 (target: ~137 lines saved) (file: metrics-cons-002.txt)
- [ ] [T058] [P1] [US1] Commit CONS-002 merge with conventional commit message (file: git log)

### CONS-003: Core Default Optimization (LOW RISK)

- [ ] [T059] [P1] [US1] Backup modules/core/default.nix before optimization (file: modules/core/default.nix.bak)
- [ ] [T060] [P1] [US1] Identify helper function opportunities in core/default.nix (file: analysis-cons-003.txt)
- [ ] [T061] [P1] [US1] Replace verbose enable options with mkEnableOption in core/default.nix (file: modules/core/default.nix)
- [ ] [T062] [P1] [US1] Replace verbose package options with mkPackageOption in core/default.nix (file: modules/core/default.nix)
- [ ] [T063] [P1] [US1] Simplify conditional config blocks using mkConditionalPackages in core/default.nix (file: modules/core/default.nix)
- [ ] [T064] [P1] [US1] Extract repeated patterns into helper function calls in core/default.nix (file: modules/core/default.nix)
- [ ] [T065] [P1] [US1] Run nix flake check after CONS-003 optimization (file: validation-cons-003.log)
- [ ] [T066] [P1] [US1] Build desktop config after CONS-003 optimization (file: validation-cons-003.log)
- [ ] [T067] [P1] [US1] Build laptop config after CONS-003 optimization (file: validation-cons-003.log)
- [ ] [T068] [P1] [US1] Compare desktop derivation after CONS-003 (should be identical except timestamps) (file: validation-cons-003-derivation.diff)
- [ ] [T069] [P1] [US1] Measure line reduction from CONS-003 (target: ~115 lines saved) (file: metrics-cons-003.txt)
- [ ] [T070] [P1] [US1] Commit CONS-003 optimization with conventional commit message (file: git log)

---

## Phase 3: Package Module Refactoring (US2 - P2) (35 tasks)

### REF-001: Browser Package Category

- [ ] [T071] [P2] [US2] Backup modules/packages/categories/browsers.nix before refactor (file: modules/packages/categories/browsers.nix.bak)
- [ ] [T072] [P2] [US2] Analyze browsers.nix for mkCategoryModule applicability (file: analysis-ref-001.txt)
- [ ] [T073] [P2] [US2] Refactor browsers.nix to use mkCategoryModule builder (file: modules/packages/categories/browsers.nix)
- [ ] [T074] [P2] [US2] Test desktop build with refactored browsers.nix (file: validation-ref-001.log)
- [ ] [T075] [P2] [US2] Measure line reduction in browsers.nix (target: ~30 lines) (file: metrics-ref-001.txt)

### REF-002: Development Package Category

- [ ] [T076] [P2] [US2] Backup modules/packages/categories/development.nix before refactor (file: modules/packages/categories/development.nix.bak)
- [ ] [T077] [P2] [US2] Analyze development.nix for mkCategoryModule applicability (file: analysis-ref-002.txt)
- [ ] [T078] [P2] [US2] Refactor development.nix to use mkCategoryModule builder (file: modules/packages/categories/development.nix)
- [ ] [T079] [P2] [US2] Test desktop build with refactored development.nix (file: validation-ref-002.log)
- [ ] [T080] [P2] [US2] Measure line reduction in development.nix (target: ~30 lines) (file: metrics-ref-002.txt)

### REF-003: Media Package Category

- [ ] [T081] [P2] [US2] Backup modules/packages/categories/media.nix before refactor (file: modules/packages/categories/media.nix.bak)
- [ ] [T082] [P2] [US2] Analyze media.nix for mkCategoryModule applicability (file: analysis-ref-003.txt)
- [ ] [T083] [P2] [US2] Refactor media.nix to use mkCategoryModule builder (file: modules/packages/categories/media.nix)
- [ ] [T084] [P2] [US2] Test desktop build with refactored media.nix (file: validation-ref-003.log)
- [ ] [T085] [P2] [US2] Measure line reduction in media.nix (target: ~30 lines) (file: metrics-ref-003.txt)

### REF-004: Gaming Package Category

- [ ] [T086] [P2] [US2] Backup modules/packages/categories/gaming.nix before refactor (file: modules/packages/categories/gaming.nix.bak)
- [ ] [T087] [P2] [US2] Analyze gaming.nix for mkCategoryModule applicability (file: analysis-ref-004.txt)
- [ ] [T088] [P2] [US2] Refactor gaming.nix to use mkCategoryModule builder (file: modules/packages/categories/gaming.nix)
- [ ] [T089] [P2] [US2] Test desktop build with refactored gaming.nix (file: validation-ref-004.log)
- [ ] [T090] [P2] [US2] Measure line reduction in gaming.nix (target: ~30 lines) (file: metrics-ref-004.txt)

### REF-005: Utilities Package Category

- [ ] [T091] [P2] [US2] Backup modules/packages/categories/utilities.nix before refactor (file: modules/packages/categories/utilities.nix.bak)
- [ ] [T092] [P2] [US2] Analyze utilities.nix for mkCategoryModule applicability (file: analysis-ref-005.txt)
- [ ] [T093] [P2] [US2] Refactor utilities.nix to use mkCategoryModule builder (file: modules/packages/categories/utilities.nix)
- [ ] [T094] [P2] [US2] Test desktop build with refactored utilities.nix (file: validation-ref-005.log)
- [ ] [T095] [P2] [US2] Measure line reduction in utilities.nix (target: ~30 lines) (file: metrics-ref-005.txt)

### REF-006: AudioVideo Package Category

- [ ] [T096] [P2] [US2] Backup modules/packages/categories/audioVideo.nix before refactor (file: modules/packages/categories/audioVideo.nix.bak)
- [ ] [T097] [P2] [US2] Analyze audioVideo.nix for mkCategoryModule applicability (file: analysis-ref-006.txt)
- [ ] [T098] [P2] [US2] Refactor audioVideo.nix to use mkCategoryModule builder (file: modules/packages/categories/audioVideo.nix)
- [ ] [T099] [P2] [US2] Test desktop build with refactored audioVideo.nix (file: validation-ref-006.log)
- [ ] [T100] [P2] [US2] Measure line reduction in audioVideo.nix (target: ~30 lines) (file: metrics-ref-006.txt)

### REF-007: Terminal Package Category

- [ ] [T101] [P2] [US2] Backup modules/packages/categories/terminal.nix before refactor (file: modules/packages/categories/terminal.nix.bak)
- [ ] [T102] [P2] [US2] Analyze terminal.nix for mkCategoryModule applicability (file: analysis-ref-007.txt)
- [ ] [T103] [P2] [US2] Refactor terminal.nix to use mkCategoryModule builder (file: modules/packages/categories/terminal.nix)
- [ ] [T104] [P2] [US2] Test desktop build with refactored terminal.nix (file: validation-ref-007.log)
- [ ] [T105] [P2] [US2] Measure line reduction in terminal.nix (target: ~30 lines) (file: metrics-ref-007.txt)

---

## Phase 4: Document Tools Refactoring (US2 - P2) (12 tasks)

### REF-008: Document Tools Module

- [ ] [T106] [P2] [US2] Backup modules/core/document-tools.nix before refactor (file: modules/core/document-tools.nix.bak)
- [ ] [T107] [P2] [US2] Analyze document-tools.nix for repeated patterns (LaTeX/Typst/Markdown sections) (file: analysis-ref-008.txt)
- [ ] [T108] [P2] [US2] Refactor LaTeX section using mkDocumentToolModule builder (file: modules/core/document-tools.nix)
- [ ] [T109] [P2] [US2] Refactor Typst section using mkDocumentToolModule builder (file: modules/core/document-tools.nix)
- [ ] [T110] [P2] [US2] Refactor Markdown section using mkDocumentToolModule builder (file: modules/core/document-tools.nix)
- [ ] [T111] [P2] [US2] Apply mkEnableOption shortcuts to remaining options in document-tools.nix (file: modules/core/document-tools.nix)
- [ ] [T112] [P2] [US2] Apply mkPackageOption shortcuts to remaining options in document-tools.nix (file: modules/core/document-tools.nix)
- [ ] [T113] [P2] [US2] Run nix flake check after document-tools.nix refactor (file: validation-ref-008.log)
- [ ] [T114] [P2] [US2] Build desktop config after document-tools.nix refactor (file: validation-ref-008.log)
- [ ] [T115] [P2] [US2] Build laptop config after document-tools.nix refactor (file: validation-ref-008.log)
- [ ] [T116] [P2] [US2] Measure line reduction in document-tools.nix (target: ~78 lines) (file: metrics-ref-008.txt)
- [ ] [T117] [P2] [US2] Commit REF-008 with conventional commit message (file: git log)

---

## Phase 5: Dotfiles Module Refactoring (US2 - P2) (10 tasks)

### REF-009: Dotfiles Module

- [ ] [T118] [P2] [US2] Backup modules/dotfiles/default.nix before refactor (file: modules/dotfiles/default.nix.bak)
- [ ] [T119] [P2] [US2] Analyze dotfiles/default.nix for optimization opportunities (file: analysis-ref-009.txt)
- [ ] [T120] [P2] [US2] Replace verbose enable options with mkEnableOption in dotfiles module (file: modules/dotfiles/default.nix)
- [ ] [T121] [P2] [US2] Replace verbose package options with mkPackageOption in dotfiles module (file: modules/dotfiles/default.nix)
- [ ] [T122] [P2] [US2] Simplify conditional blocks using mkConditionalPackages in dotfiles module (file: modules/dotfiles/default.nix)
- [ ] [T123] [P2] [US2] Extract repeated option patterns into helper function calls (file: modules/dotfiles/default.nix)
- [ ] [T124] [P2] [US2] Run nix flake check after dotfiles refactor (file: validation-ref-009.log)
- [ ] [T125] [P2] [US2] Build both configs after dotfiles refactor (file: validation-ref-009.log)
- [ ] [T126] [P2] [US2] Measure line reduction in dotfiles module (target: ~96 lines) (file: metrics-ref-009.txt)
- [ ] [T127] [P2] [US2] Commit REF-009 with conventional commit message (file: git log)

---

## Phase 6: Option Definition Optimization (US3 - P3) (30 tasks)

### OPT-001: Enable Option Shortcuts (All Modules)

- [ ] [T128] [P3] [US3] Audit all modules for verbose enable option patterns (file: audit-enable-options.txt)
- [ ] [T129] [P3] [US3] Replace verbose enable options in modules/core/*.nix with mkEnableOption (file: modules/core/*.nix)
- [ ] [T130] [P3] [US3] Replace verbose enable options in modules/networking/*.nix with mkEnableOption (file: modules/networking/*.nix)
- [ ] [T131] [P3] [US3] Replace verbose enable options in modules/desktop/*.nix with mkEnableOption (file: modules/desktop/*.nix)
- [ ] [T132] [P3] [US3] Replace verbose enable options in modules/services/*.nix with mkEnableOption (file: modules/services/*.nix)
- [ ] [T133] [P3] [US3] Replace verbose enable options in modules/gpu/*.nix with mkEnableOption (file: modules/gpu/*.nix)
- [ ] [T134] [P3] [US3] Replace verbose enable options in modules/roles/*.nix with mkEnableOption (file: modules/roles/*.nix)
- [ ] [T135] [P3] [US3] Run flake check after enable option optimization (file: validation-opt-001.log)
- [ ] [T136] [P3] [US3] Measure line reduction from enable option optimization (target: ~150 lines) (file: metrics-opt-001.txt)

### OPT-002: Package Option Shortcuts (All Modules)

- [ ] [T137] [P3] [US3] Audit all modules for verbose package option patterns (file: audit-package-options.txt)
- [ ] [T138] [P3] [US3] Replace verbose package options in modules/core/*.nix with mkPackageOption (file: modules/core/*.nix)
- [ ] [T139] [P3] [US3] Replace verbose package options in modules/desktop/*.nix with mkPackageOption (file: modules/desktop/*.nix)
- [ ] [T140] [P3] [US3] Replace verbose package options in modules/services/*.nix with mkPackageOption (file: modules/services/*.nix)
- [ ] [T141] [P3] [US3] Replace verbose package options in modules/gpu/*.nix with mkPackageOption (file: modules/gpu/*.nix)
- [ ] [T142] [P3] [US3] Run flake check after package option optimization (file: validation-opt-002.log)
- [ ] [T143] [P3] [US3] Measure line reduction from package option optimization (target: ~40 lines) (file: metrics-opt-002.txt)

### OPT-003: Conditional Block Simplification

- [ ] [T144] [P3] [US3] Audit all modules for complex conditional package blocks (file: audit-conditional-blocks.txt)
- [ ] [T145] [P3] [US3] Simplify conditional blocks in modules/core/*.nix using mkConditionalPackages (file: modules/core/*.nix)
- [ ] [T146] [P3] [US3] Simplify conditional blocks in modules/packages/*.nix using mkConditionalPackages (file: modules/packages/*.nix)
- [ ] [T147] [P3] [US3] Simplify conditional blocks in modules/desktop/*.nix using mkConditionalPackages (file: modules/desktop/*.nix)
- [ ] [T148] [P3] [US3] Run flake check after conditional block simplification (file: validation-opt-003.log)
- [ ] [T149] [P3] [US3] Measure line reduction from conditional block simplification (target: ~60 lines) (file: metrics-opt-003.txt)

### OPT-004: Redundant Option Merging

- [ ] [T150] [P3] [US3] Identify overly granular options that can be merged (file: audit-redundant-options.txt)
- [ ] [T151] [P3] [US3] Merge redundant boolean toggles into enum options where appropriate (file: modules/*/*.nix)
- [ ] [T152] [P3] [US3] Simplify option sets with mkMergedOptions helper (file: modules/*/*.nix)
- [ ] [T153] [P3] [US3] Run flake check after redundant option merging (file: validation-opt-004.log)
- [ ] [T154] [P3] [US3] Measure line reduction from redundant option merging (target: ~100 lines) (file: metrics-opt-004.txt)

### OPT-005: Overall Phase 6 Validation

- [ ] [T155] [P3] [US3] Run comprehensive flake check after all Phase 6 optimizations (file: validation-phase6.log)
- [ ] [T156] [P3] [US3] Build desktop config after all Phase 6 optimizations (file: validation-phase6.log)
- [ ] [T157] [P3] [US3] Build laptop config after all Phase 6 optimizations (file: validation-phase6.log)

---

## Phase 7: Final Validation & Documentation (25 tasks)

### Metrics & Comparison

- [ ] [T158] [P1] [--] Generate final line count metrics for all modules (file: metrics-final.txt)
- [ ] [T159] [P1] [--] Calculate total line reduction: baseline - final (file: metrics-final.txt)
- [ ] [T160] [P1] [--] Calculate reduction percentage: (reduction / baseline) × 100% (file: metrics-final.txt)
- [ ] [T161] [P1] [--] Verify 25% reduction target achieved (≥1457 lines saved) (file: metrics-final.txt)
- [ ] [T162] [P1] [--] Document per-category line reductions (file: metrics-final.txt)
- [ ] [T163] [P1] [--] Verify average module size reduced by ≥20% (file: metrics-final.txt)

### Build & Functionality Validation

- [ ] [T164] [P1] [--] Run final nix flake check (must pass with zero errors) (file: validation-final-flake-check.log)
- [ ] [T165] [P1] [--] Build desktop configuration (must succeed) (file: validation-final-desktop-build.log)
- [ ] [T166] [P1] [--] Build laptop configuration (must succeed) (file: validation-final-laptop-build.log)
- [ ] [T167] [P1] [--] Measure final desktop build time (must be <5 min, no regression) (file: metrics-final.txt)
- [ ] [T168] [P1] [--] Measure final laptop build time (must be <5 min, no regression) (file: metrics-final.txt)

### Derivation & Service Comparison

- [ ] [T169] [P1] [--] Capture final desktop system derivation (file: final-desktop-derivation.json)
- [ ] [T170] [P1] [--] Compare baseline vs final desktop derivation (only timestamps should differ) (file: validation-derivation-comparison.diff)
- [ ] [T171] [P1] [--] Deploy to desktop and capture enabled services (file: final-desktop-services.txt)
- [ ] [T172] [P1] [--] Compare baseline vs final desktop services (should be identical) (file: validation-services-comparison.diff)
- [ ] [T173] [P1] [--] Verify 100% feature parity (no lost functionality) (file: validation-feature-parity.txt)

### Documentation Updates

- [ ] [T174] [P1] [--] Update CLAUDE.md with new helper function library (file: CLAUDE.md)
- [ ] [T175] [P1] [--] Update CLAUDE.md with consolidated module structure (file: CLAUDE.md)
- [ ] [T176] [P1] [--] Create lib/README.md if not already done (comprehensive helper docs) (file: lib/README.md)
- [ ] [T177] [P1] [--] Add usage examples for all 10 helper functions in lib/README.md (file: lib/README.md)
- [ ] [T178] [P1] [--] Update module documentation with new structure (file: modules/*/README.md)

### Success Criteria Verification

- [ ] [T179] [P1] [--] Verify SC-001: 25% reduction achieved (file: success-criteria.txt)
- [ ] [T180] [P1] [--] Verify SC-002: Build time <5 min (file: success-criteria.txt)
- [ ] [T181] [P1] [--] Verify SC-003: All flake checks pass (file: success-criteria.txt)
- [ ] [T182] [P1] [--] Verify SC-004: Zero module duplication (file: success-criteria.txt)
- [ ] [T183] [P1] [--] Verify SC-005: 20% avg module size reduction (file: success-criteria.txt)
- [ ] [T184] [P1] [--] Verify SC-006: 10 helper functions created (file: success-criteria.txt)
- [ ] [T185] [P1] [--] Verify SC-007: Improved maintainability (code review) (file: success-criteria.txt)
- [ ] [T186] [P1] [--] Verify SC-008: No build time regression (file: success-criteria.txt)
- [ ] [T187] [P1] [--] Verify SC-009: Identical system behavior (file: success-criteria.txt)
- [ ] [T188] [P1] [--] Verify SC-010: Documentation updated (file: success-criteria.txt)

### Final Commit & Merge

- [ ] [T189] [P1] [--] Create final completion report (file: COMPLETION_REPORT.md)
- [ ] [T190] [P1] [--] Commit final documentation updates (file: git log)
- [ ] [T191] [P1] [--] Tag feature completion: `git tag 002-codebase-reduction-complete` (file: git log)
- [ ] [T192] [P1] [--] Prepare pull request to develop branch (file: PR description)

---

## Task Summary

**Total Tasks**: 192
**MVP (P1)**: 71 tasks
**Important (P2)**: 87 tasks
**Polish (P3)**: 34 tasks

**By User Story**:
- US1 (Consolidate modules): 60 tasks
- US2 (Extract helpers): 87 tasks
- US3 (Optimize options): 30 tasks
- Infrastructure: 15 tasks

**Parallelization Opportunities**:
- Phase 1 helper functions can be created in parallel (T011-T026)
- Package category refactorings can be done in parallel (T071-T105)
- Option optimization audits can be done in parallel (T128-T154)

**Critical Path** (sequential dependencies):
1. Phase 0: Baseline (T001-T010) → MUST complete first
2. Phase 1: Helper library (T011-T030) → Required for Phase 2-6
3. Phase 2: Consolidations (T031-T070) → Sequential (one at a time)
4. Phase 3-5: Refactorings (T071-T127) → Can be parallel within phase
5. Phase 6: Optimizations (T128-T157) → Can be parallel
6. Phase 7: Final validation (T158-T192) → MUST complete last

**MVP Scope** (P1 only):
- Phase 0: All 10 baseline tasks
- Phase 2: All 40 consolidation tasks
- Phase 7: All 25 final validation tasks
**Total MVP**: 75 tasks → Achieves 15% reduction minimum

**Estimated Timeline**:
- Phase 0: 1-2 hours (baseline metrics)
- Phase 1: 4-6 hours (helper library creation)
- Phase 2: 6-8 hours (consolidations, sequential)
- Phase 3-5: 8-10 hours (refactorings, parallelizable)
- Phase 6: 4-6 hours (optimizations, parallelizable)
- Phase 7: 2-3 hours (final validation)
**Total**: ~25-35 hours of work

---

**Generated**: 2025-11-25
**Status**: Ready for implementation
**Next Step**: Begin Phase 0 baseline metrics (T001-T010)
