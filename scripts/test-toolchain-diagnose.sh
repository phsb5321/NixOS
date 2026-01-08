#!/usr/bin/env bash
# test-toolchain-diagnose.sh
# Diagnostic command for NixOS Test Toolchain
# Prints browser paths, environment variables, and version information
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical component missing (browsers, node)
#   2 - Warning (Docker unavailable, version mismatch hint)
#
# Usage: test-toolchain-diagnose [--help]

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track overall status
CRITICAL_ERROR=0
WARNING=0

show_help() {
    cat << EOF
NixOS Test Toolchain Diagnostics v${VERSION}

Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
    --help, -h      Show this help message
    --version, -v   Show version information
    --json          Output in JSON format (for scripting)
    --quiet, -q     Only show errors and warnings

Description:
    Validates the testing toolchain environment and reports:
    - Browser availability and paths
    - Environment variable configuration
    - Driver versions (chromedriver, geckodriver)
    - Node.js version (for MCP compatibility)
    - Docker availability (for fallback)
    - Version alignment hints

Exit Codes:
    0   All checks passed - ready for testing
    1   Critical error - missing browsers or Node.js
    2   Warning - non-critical issues detected

Examples:
    ${SCRIPT_NAME}              # Run full diagnostics
    ${SCRIPT_NAME} --json       # Output as JSON
    ${SCRIPT_NAME} --quiet      # Only show problems
EOF
}

show_version() {
    echo "test-toolchain-diagnose v${VERSION}"
}

# Helper functions
print_ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

print_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
    WARNING=1
}

print_error() {
    echo -e "  ${RED}[ERROR]${NC} $1"
    CRITICAL_ERROR=1
}

print_section() {
    echo ""
    echo -e "${BLUE}[$1]${NC}"
}

# Get Playwright version from the browser path or npm
get_playwright_version() {
    if [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ] && [ -d "${PLAYWRIGHT_BROWSERS_PATH}" ]; then
        # Try to extract version from path like /nix/store/xxx-playwright-driver-1.52.0-browsers
        local version
        version=$(echo "${PLAYWRIGHT_BROWSERS_PATH}" | grep -oP 'playwright-driver-\K[0-9]+\.[0-9]+\.[0-9]+' || echo "")
        if [ -n "$version" ]; then
            echo "$version"
            return
        fi
        
        # Alternative: Check chromium directory name for build number (e.g., chromium-1200)
        # and map to approximate Playwright version
        local chromium_build
        chromium_build=$(ls "${PLAYWRIGHT_BROWSERS_PATH}" 2>/dev/null | grep -oP 'chromium-\K[0-9]+' | head -1 || echo "")
        if [ -n "$chromium_build" ]; then
            # Build 1200 corresponds to Playwright 1.52.x range
            echo "~1.52.x (build ${chromium_build})"
            return
        fi
    fi
    
    # Fallback: try to get version from npx
    local npx_version
    npx_version=$(npx playwright --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
    if [ -n "$npx_version" ]; then
        echo "$npx_version (from npm)"
        return
    fi
    
    echo "unknown"
}

# Check Node.js version meets minimum requirement (18+)
check_node_version() {
    local node_version
    node_version=$(node --version 2>/dev/null | sed 's/v//' || echo "0.0.0")
    local major_version
    major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [ "$major_version" -ge 18 ] 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Main diagnostic function
run_diagnostics() {
    local quiet="${1:-false}"
    
    echo "=== NixOS Test Toolchain Diagnostics ==="
    echo "Version: ${VERSION}"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Environment Variables
    print_section "Environment Variables"
    
    if [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ]; then
        print_ok "PLAYWRIGHT_BROWSERS_PATH: ${PLAYWRIGHT_BROWSERS_PATH}"
    else
        print_error "PLAYWRIGHT_BROWSERS_PATH: NOT SET"
    fi
    
    if [ "${PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS:-}" = "true" ]; then
        print_ok "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS: true"
    else
        print_warn "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS: ${PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS:-NOT SET} (should be 'true')"
    fi
    
    if [ -n "${PUPPETEER_EXECUTABLE_PATH:-}" ]; then
        if [ -x "${PUPPETEER_EXECUTABLE_PATH}" ]; then
            print_ok "PUPPETEER_EXECUTABLE_PATH: ${PUPPETEER_EXECUTABLE_PATH}"
        else
            print_warn "PUPPETEER_EXECUTABLE_PATH: ${PUPPETEER_EXECUTABLE_PATH} (not executable)"
        fi
    else
        print_warn "PUPPETEER_EXECUTABLE_PATH: NOT SET (optional)"
    fi
    
    # Browsers
    print_section "Browser Availability"
    
    if [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ] && [ -d "${PLAYWRIGHT_BROWSERS_PATH}" ]; then
        print_ok "Playwright browsers directory exists"
        # Check for chromium in the browsers directory
        if ls "${PLAYWRIGHT_BROWSERS_PATH}"/chromium-* &>/dev/null; then
            print_ok "Chromium browser found in Playwright browsers"
        else
            print_warn "Chromium not found in Playwright browsers directory"
        fi
    else
        print_error "Playwright browsers directory NOT FOUND"
    fi
    
    local chromium_path
    chromium_path=$(which chromium 2>/dev/null || echo "")
    if [ -n "$chromium_path" ]; then
        local chromium_version
        chromium_version=$(chromium --version 2>/dev/null | head -1 || echo "unknown")
        print_ok "Standalone Chromium: ${chromium_path} (${chromium_version})"
    else
        print_warn "Standalone Chromium: NOT FOUND on PATH"
    fi
    
    # Selenium Drivers
    print_section "Selenium Drivers"
    
    local chromedriver_path
    chromedriver_path=$(which chromedriver 2>/dev/null || echo "")
    if [ -n "$chromedriver_path" ]; then
        local chromedriver_version
        chromedriver_version=$(chromedriver --version 2>/dev/null | head -1 || echo "unknown")
        print_ok "chromedriver: ${chromedriver_path}"
        echo "             Version: ${chromedriver_version}"
    else
        print_warn "chromedriver: NOT FOUND on PATH"
    fi
    
    local geckodriver_path
    geckodriver_path=$(which geckodriver 2>/dev/null || echo "")
    if [ -n "$geckodriver_path" ]; then
        local geckodriver_version
        geckodriver_version=$(geckodriver --version 2>/dev/null | head -1 || echo "unknown")
        print_ok "geckodriver: ${geckodriver_path}"
        echo "             Version: ${geckodriver_version}"
    else
        print_warn "geckodriver: NOT FOUND on PATH"
    fi
    
    # Node.js
    print_section "Node.js (MCP Requirement)"
    
    local node_path
    node_path=$(which node 2>/dev/null || echo "")
    if [ -n "$node_path" ]; then
        local node_version
        node_version=$(node --version 2>/dev/null || echo "unknown")
        if check_node_version; then
            print_ok "Node.js: ${node_version} (>= 18 required for MCP)"
        else
            print_warn "Node.js: ${node_version} (MCP requires >= 18)"
        fi
    else
        print_error "Node.js: NOT FOUND (required for Playwright and MCP)"
    fi
    
    # Docker (optional)
    print_section "Docker (Fallback)"
    
    if command -v docker &>/dev/null; then
        if docker info &>/dev/null 2>&1; then
            print_ok "Docker: Available and running"
        else
            print_warn "Docker: Installed but daemon not running"
        fi
    else
        print_warn "Docker: NOT INSTALLED (fallback unavailable)"
        echo "         Install with: virtualisation.docker.enable = true;"
    fi
    
    # Version Alignment
    print_section "Version Alignment"
    
    local pw_version
    pw_version=$(get_playwright_version)
    if [ "$pw_version" != "unknown" ]; then
        print_ok "Nix Playwright version: ${pw_version}"
        # Extract just the semver part for package.json hint
        local semver_hint
        semver_hint=$(echo "$pw_version" | grep -oP '^~?[0-9]+\.[0-9]+\.[0-9x]+' || echo "1.52.0")
        if [[ "$pw_version" == *"build"* ]]; then
            echo "         Hint: Pin npm @playwright/test to ~1.57.0 (approximate)"
            echo "         In package.json: \"@playwright/test\": \"~1.57.0\""
        else
            echo "         Hint: Pin npm @playwright/test to ${pw_version}"
            echo "         In package.json: \"@playwright/test\": \"${pw_version}\""
        fi
    else
        print_warn "Could not detect Playwright version from Nix store path"
        echo "         Hint: Run 'nix-env -qaP playwright' to find version"
    fi
    
    # Summary
    print_section "Summary"
    
    if [ "$CRITICAL_ERROR" -eq 1 ]; then
        echo -e "${RED}Status: CRITICAL ERRORS DETECTED${NC}"
        echo "Some required components are missing. Testing may not work."
    elif [ "$WARNING" -eq 1 ]; then
        echo -e "${YELLOW}Status: READY WITH WARNINGS${NC}"
        echo "Toolchain is functional but some optional components are missing."
    else
        echo -e "${GREEN}Status: READY${NC}"
        echo "All components are properly configured."
    fi
    
    echo ""
    echo "=== End Diagnostics ==="
}

# JSON output function
run_diagnostics_json() {
    local pw_browsers_ok="false"
    local skip_validate_ok="false"
    local chromium_ok="false"
    local chromedriver_ok="false"
    local geckodriver_ok="false"
    local node_ok="false"
    local docker_ok="false"
    local status="ready"
    
    [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ] && [ -d "${PLAYWRIGHT_BROWSERS_PATH}" ] && pw_browsers_ok="true"
    [ "${PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS:-}" = "true" ] && skip_validate_ok="true"
    command -v chromium &>/dev/null && chromium_ok="true"
    command -v chromedriver &>/dev/null && chromedriver_ok="true"
    command -v geckodriver &>/dev/null && geckodriver_ok="true"
    command -v node &>/dev/null && check_node_version && node_ok="true"
    command -v docker &>/dev/null && docker info &>/dev/null 2>&1 && docker_ok="true"
    
    [ "$pw_browsers_ok" = "false" ] || [ "$node_ok" = "false" ] && status="error"
    [ "$status" = "ready" ] && [ "$docker_ok" = "false" ] && status="warning"
    
    cat << EOF
{
  "version": "${VERSION}",
  "timestamp": "$(date -Iseconds)",
  "status": "${status}",
  "environment": {
    "PLAYWRIGHT_BROWSERS_PATH": "${PLAYWRIGHT_BROWSERS_PATH:-}",
    "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS": "${PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS:-}",
    "PUPPETEER_EXECUTABLE_PATH": "${PUPPETEER_EXECUTABLE_PATH:-}"
  },
  "components": {
    "playwright_browsers": ${pw_browsers_ok},
    "chromium": ${chromium_ok},
    "chromedriver": ${chromedriver_ok},
    "geckodriver": ${geckodriver_ok},
    "node": ${node_ok},
    "docker": ${docker_ok}
  },
  "versions": {
    "playwright": "$(get_playwright_version)",
    "node": "$(node --version 2>/dev/null || echo 'not found')",
    "chromium": "$(chromium --version 2>/dev/null | head -1 || echo 'not found')"
  }
}
EOF
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --version|-v)
        show_version
        exit 0
        ;;
    --json)
        run_diagnostics_json
        exit 0
        ;;
    --quiet|-q)
        run_diagnostics "true" 2>&1 | grep -E '\[(ERROR|WARN)\]|Status:'
        ;;
    *)
        run_diagnostics
        ;;
esac

# Exit with appropriate code
if [ "$CRITICAL_ERROR" -eq 1 ]; then
    exit 1
elif [ "$WARNING" -eq 1 ]; then
    exit 2
else
    exit 0
fi
