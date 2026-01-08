# ~/NixOS/shells/testing-toolchain.nix
# Shared testing toolchain for browser-based E2E testing
# Provides Playwright, Selenium drivers, and MCP compatibility across all devShells
#
# Usage: Import this module in any shell to add browser testing capabilities
#   let testingToolchain = import ./testing-toolchain.nix { inherit pkgs; };
#   in pkgs.mkShell {
#     buildInputs = [ ... ] ++ testingToolchain.packages;
#     shellHook = ''
#       ${testingToolchain.shellHook}
#       # ... other shell hooks
#     '';
#   }
{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}:
let
  # Get the directory where this file is located for script paths
  toolchainDir = builtins.toString ./.;
  scriptsDir = builtins.toString ../scripts;
in {
  # Packages to add to buildInputs
  packages = with pkgs; [
    # Playwright browsers (Nix-patched for NixOS compatibility)
    playwright-driver.browsers

    # Standalone Chromium (for Puppeteer fallback and direct browser access)
    chromium

    # Node.js 22 (required for MCP server, Playwright, and npm packages)
    # MCP requires Node.js 18+; we use 22 for latest features
    nodejs_22

    # Selenium WebDriver executables
    chromedriver  # Chrome/Chromium WebDriver
    geckodriver   # Firefox WebDriver

    # Debugging and diagnostic utilities
    jq        # JSON parsing for diagnostics and test output
    curl      # HTTP debugging and health checks
    ripgrep   # Fast text search in logs and output
  ];

  # Shell hook to set environment variables and add diagnostic command
  shellHook = ''
    # ============================================================
    # NixOS Test Toolchain - Environment Configuration
    # ============================================================

    # Required: Point Playwright to Nix-provided browsers
    # This is critical for NixOS - without this, Playwright will fail to find browsers
    export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"

    # Required: Skip FHS-style host validation that fails on NixOS
    # NixOS uses the Nix store instead of standard Linux library paths
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

    # Recommended: Provide Puppeteer with Chromium path for compatibility
    # Some projects use Puppeteer instead of Playwright
    export PUPPETEER_EXECUTABLE_PATH="${pkgs.chromium}/bin/chromium"

    # Optional: Explicit Node.js path for Playwright internals
    export PLAYWRIGHT_NODEJS_PATH="${pkgs.nodejs_22}/bin/node"

    # ============================================================
    # Diagnostic Command
    # ============================================================

    # Add diagnostic script to PATH if it exists
    if [ -d "${scriptsDir}" ]; then
      export PATH="${scriptsDir}:$PATH"
    fi

    # Define inline diagnostic function as fallback
    test-toolchain-diagnose() {
      if command -v "${scriptsDir}/test-toolchain-diagnose.sh" &> /dev/null; then
        "${scriptsDir}/test-toolchain-diagnose.sh" "$@"
      else
        echo "=== NixOS Test Toolchain Diagnostics ==="
        echo ""
        echo "[Environment Variables]"
        echo "  PLAYWRIGHT_BROWSERS_PATH: ''${PLAYWRIGHT_BROWSERS_PATH:-NOT SET}"
        echo "  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS: ''${PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS:-NOT SET}"
        echo "  PUPPETEER_EXECUTABLE_PATH: ''${PUPPETEER_EXECUTABLE_PATH:-NOT SET}"
        echo ""
        echo "[Browsers]"
        if [ -d "''${PLAYWRIGHT_BROWSERS_PATH:-}" ]; then
          echo "  Playwright browsers: ''${PLAYWRIGHT_BROWSERS_PATH} [OK]"
        else
          echo "  Playwright browsers: NOT FOUND [ERROR]"
        fi
        echo "  Chromium: $(which chromium 2>/dev/null || echo 'NOT FOUND')"
        echo ""
        echo "[Drivers]"
        echo "  chromedriver: $(which chromedriver 2>/dev/null || echo 'NOT FOUND')"
        echo "  geckodriver: $(which geckodriver 2>/dev/null || echo 'NOT FOUND')"
        echo ""
        echo "[Node.js]"
        echo "  Version: $(node --version 2>/dev/null || echo 'NOT FOUND')"
        echo ""
        echo "[Docker]"
        if command -v docker &> /dev/null; then
          echo "  Status: Available"
        else
          echo "  Status: Not installed (Docker fallback unavailable)"
        fi
        echo ""
        echo "=== End Diagnostics ==="
      fi
    }

    # Export the function so it's available in subshells
    export -f test-toolchain-diagnose
  '';
}
