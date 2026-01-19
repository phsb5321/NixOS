# Insecure Packages Policy

## Overview

Nix blocks packages marked as "insecure" by default. This document explains how to handle these situations safely while minimizing security exposure.

## Why Nix Blocks Insecure Packages

Nixpkgs maintainers mark packages as insecure when:
- They have known CVEs (Common Vulnerabilities and Exposures)
- They are end-of-life (EOL) and no longer receiving security updates
- They have unfixed security issues

This is a **safety feature** - it prevents accidentally installing vulnerable software.

## Current Allowlist

The following insecure packages are currently permitted in this configuration:

### System-wide (flake-modules/hosts.nix)

| Package | Reason | CVE/Issue | Removal Plan |
|---------|--------|-----------|--------------|
| `gradle-7.6.6` | Android development toolchain | EOL after Gradle 9 | Upgrade when android-studio supports Gradle 9 |
| `electron-36.9.5` | Required by installed Electron apps | EOL Electron | Upgrade apps to newer Electron versions |

### Development Shells

Dev shells may have additional insecure packages scoped only to that shell.
Check individual shell files in `shells/` for `permittedInsecurePackages`.

## Correct Syntax

**CRITICAL: Version number is REQUIRED**

```nix
# CORRECT - includes version
nixpkgs.config.permittedInsecurePackages = [
  "python-2.7.18.6"
  "nodejs-12.22.12"
];

# WRONG - will NOT work
nixpkgs.config.permittedInsecurePackages = [
  "python"      # Missing version!
  "nodejs"      # Missing version!
];
```

## Decision Tree: How to Handle Insecure Packages

```
Package marked as insecure
         │
         ▼
┌──────────────────────┐
│ Is there a newer,    │
│ secure version?      │
└──────────────────────┘
         │
    ┌────┴────┐
    │ Yes     │ No
    ▼         ▼
┌─────────┐ ┌──────────────────────┐
│ Upgrade │ │ Can you replace with │
│         │ │ alternative package? │
└─────────┘ └──────────────────────┘
                    │
               ┌────┴────┐
               │ Yes     │ No
               ▼         ▼
         ┌─────────┐ ┌──────────────────────┐
         │ Replace │ │ Is it development-   │
         │         │ │ only dependency?     │
         └─────────┘ └──────────────────────┘
                              │
                         ┌────┴────┐
                         │ Yes     │ No
                         ▼         ▼
                   ┌───────────┐ ┌──────────────────┐
                   │ Scope to  │ │ Add to system    │
                   │ dev shell │ │ allowlist with   │
                   │ only      │ │ documentation    │
                   └───────────┘ └──────────────────┘
```

## Workflow: Adding an Insecure Package

### Step 1: Identify the Package

When you see an error like:
```
error: Package 'python-ecdsa-0.19.0' is marked as insecure
```

Note the **exact name and version**: `python-ecdsa-0.19.0`

### Step 2: Research the Issue

```bash
# Check if a newer version exists
nix search nixpkgs python-ecdsa

# Find which package depends on it
nix why-depends .#nixosConfigurations.laptop pkgs.python-ecdsa

# For dev shells:
nix why-depends .#devShells.x86_64-linux.esp pkgs.python-ecdsa
```

### Step 3: Try to Upgrade or Replace

```nix
# Option A: Override to use newer version (if available)
nixpkgs.overlays = [
  (final: prev: {
    python-ecdsa = prev.python-ecdsa.overrideAttrs (old: {
      version = "0.20.0";  # hypothetical newer version
      src = ...;
    });
  })
];

# Option B: Use alternative package
environment.systemPackages = [
  pkgs.python-cryptography  # instead of python-ecdsa
];
```

### Step 4: Scope the Allowlist (If Unavoidable)

**Prefer dev shell scope over system-wide:**

```nix
# shells/ESP.nix - scoped to this shell only
{ pkgs ? import <nixpkgs> {
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "python-ecdsa-0.19.0"  # ESP toolchain dependency
    ];
  };
}}:
```

**System-wide (last resort):**

```nix
# flake-modules/hosts.nix
permittedInsecurePackages = [
  # ESP32/Arduino development - ecdsa used for secure boot signing
  # CVE-2024-XXXX: Side-channel timing attack (low risk for dev use)
  # Removal plan: Upgrade when platformio updates to pyecdsa 0.20+
  # Added: 2025-01-19
  "python-ecdsa-0.19.0"
];
```

### Step 5: Document

Every allowlisted package MUST have:
1. **Reason**: Why it's needed
2. **CVE/Issue**: What makes it insecure
3. **Scope**: Where it's allowed (shell/system)
4. **Removal plan**: When/how to remove it
5. **Date added**: For tracking

## Quarterly Review Checklist

Every 3 months, review the allowlist:

- [ ] Check if newer secure versions are available
- [ ] Verify packages are still needed
- [ ] Update CVE references
- [ ] Remove packages that are no longer used
- [ ] Document any changes

## Predicate-Based Alternative

For complex cases, use a predicate instead of a list:

```nix
nixpkgs.config.allowInsecurePredicate = pkg:
  builtins.elem (lib.getName pkg) [
    "ovftool"        # VMware tool, no secure alternative
    "old-python"     # Legacy project requirement
  ];
```

**Note**: If you define `allowInsecurePredicate`, `permittedInsecurePackages` is **ignored**.

## Emergency: Unblocking Development

If an insecure package is blocking `nix-shell`:

```bash
# Temporary workaround (single invocation)
NIXPKGS_ALLOW_INSECURE=1 nix-shell --impure shells/ESP.nix
```

This is for emergency unblocking only. Add proper allowlist entry afterward.

## References

- [Nixpkgs Manual - Insecure Packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-insecure)
- [NixOS Discourse - permittedInsecurePackages](https://discourse.nixos.org/t/permittedinsecurepackages-not-taking-effect/44449)
- [docs/research/laptop-stability.md](../research/laptop-stability.md) - Failure playbooks
