# CMake 4.0 Compatibility Issue Investigation

## Issue Summary
On October 7, 2025, attempting to update NixOS flake inputs resulted in multiple package build failures due to CMake 4.0 removing support for CMake versions < 3.5.

## Affected Packages
The following packages failed to build with the updated nixpkgs:
- **piper-tts** - Failed due to ucd-tools CMake build error
- **pamixer** - Failed due to missing icu-cu dependency
- **lutris** - Failed due to allegro CMake < 3.5 compatibility
- **qgnomeplatform** - Failed with CMake minimum version error (unmaintained package)

## Root Cause
CMake 4.0.0 removed support for features deprecated in CMake 3.5 or earlier. Many packages in nixpkgs have not updated their CMakeLists.txt files to specify a minimum version of 3.5 or higher.

## Attempted Solutions
1. **Package-specific overlays** - Attempted to patch CMakeLists.txt files
2. **CMAKE_POLICY_VERSION_MINIMUM** - Tried to force CMake to accept older versions
3. **Temporary package disabling** - Commented out affected packages

## Resolution
Rolled back nixpkgs to pre-CMake 4.0 versions (September 2025 commits):
- nixpkgs: `8eaee110344796db060382e15d3af0a9fc396e0e`
- nixpkgs-unstable: `a1f79a1770d05af18111fbbe2a3ab2c42c0f6cd0`

## Recommendations
1. **Pin nixpkgs** to these working versions until upstream fixes are available
2. **Monitor nixpkgs issues** for CMake 4.0 compatibility fixes
3. **Test updates carefully** before committing flake.lock changes

## References
- [CMake 4.0 Release Notes](https://cmake.org/cmake/help/latest/release/4.0.html)
- CMake Error: "Compatibility with CMake < 3.5 has been removed from CMake"

## Status
As of October 7, 2025, the system is running on the September 2025 nixpkgs versions with all packages working correctly.