#!/usr/bin/env bash
#
# NixOS Laptop Preflight Check
# Validates configuration before rebuild to prevent boot failures
#
# Usage: ./scripts/laptop/preflight.sh [--verbose]
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical check failed (do not proceed with rebuild)
#   2 - Warning (non-critical issue detected)

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_DIR="${SCRIPT_DIR}/../.."
readonly HOST="laptop"
readonly BOOT_THRESHOLD_PERCENT=80
readonly DISK_THRESHOLD_GB=5

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERBOSE=false
WARNINGS=0
ERRORS=0

#######################################
# Logging functions
#######################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((ERRORS++))
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

#######################################
# Check functions
#######################################

check_flake_syntax() {
    log_info "Checking flake syntax..."

    if timeout 180s nix flake check --no-build "$FLAKE_DIR" 2>&1; then
        log_success "Flake syntax check passed"
        return 0
    else
        log_error "Flake syntax check failed"
        return 1
    fi
}

check_host_config() {
    log_info "Validating host configuration for '$HOST'..."

    local build_cmd="nix build $FLAKE_DIR#nixosConfigurations.$HOST.config.system.build.toplevel --dry-run"

    if timeout 120s $build_cmd 2>&1; then
        log_success "Host configuration '$HOST' is valid"
        return 0
    else
        log_error "Host configuration validation failed for '$HOST'"
        log_info "Run with --verbose for more details"
        return 1
    fi
}

check_insecure_packages() {
    log_info "Checking for insecure package errors..."

    # Try to evaluate and capture insecure package errors
    local output
    output=$(nix build "$FLAKE_DIR#nixosConfigurations.$HOST.config.system.build.toplevel" --dry-run 2>&1) || true

    if echo "$output" | grep -q "is marked as insecure"; then
        log_warning "Insecure packages detected in configuration"
        echo ""
        echo "  Affected packages:"
        echo "$output" | grep "is marked as insecure" | head -5 | while read -r line; do
            echo "    - $line"
        done
        echo ""
        echo "  To trace the dependency:"
        echo "    nix why-depends .#nixosConfigurations.$HOST <package>"
        echo ""
        echo "  To allow (scoped to dev shell preferred):"
        echo "    nixpkgs.config.permittedInsecurePackages = [ \"package-version\" ];"
        echo ""
        return 2
    fi

    log_success "No insecure package blockers"
    return 0
}

check_boot_partition() {
    log_info "Checking /boot partition capacity..."

    if [[ ! -d /boot ]]; then
        log_warning "/boot partition not mounted (running in dev environment?)"
        return 2
    fi

    local usage_percent
    usage_percent=$(df /boot --output=pcent | tail -1 | tr -d ' %')

    local available_mb
    available_mb=$(df /boot --output=avail --block-size=1M | tail -1 | tr -d ' ')

    log_verbose "/boot usage: ${usage_percent}% (${available_mb}MB available)"

    if [[ "$usage_percent" -ge "$BOOT_THRESHOLD_PERCENT" ]]; then
        log_error "/boot partition is ${usage_percent}% full (threshold: ${BOOT_THRESHOLD_PERCENT}%)"
        echo ""
        echo "  Recovery steps:"
        echo "    1. sudo nix-collect-garbage -d"
        echo "    2. sudo nixos-rebuild boot --flake .#$HOST"
        echo "    3. If still full, check for orphaned .efi files:"
        echo "       ls -la /boot/EFI/nixos/"
        echo ""
        return 1
    elif [[ "$usage_percent" -ge 60 ]]; then
        log_warning "/boot partition is ${usage_percent}% full (consider cleanup)"
        return 2
    fi

    log_success "/boot partition OK (${usage_percent}% used, ${available_mb}MB available)"
    return 0
}

check_nix_store_space() {
    log_info "Checking /nix store disk space..."

    local available_gb
    available_gb=$(df /nix --output=avail --block-size=1G | tail -1 | tr -d ' ')

    log_verbose "/nix available: ${available_gb}GB"

    if [[ "$available_gb" -lt "$DISK_THRESHOLD_GB" ]]; then
        log_error "Low disk space for /nix store: ${available_gb}GB available (need ${DISK_THRESHOLD_GB}GB)"
        echo ""
        echo "  Cleanup commands:"
        echo "    nix-collect-garbage -d"
        echo "    nix store optimise"
        echo ""
        return 1
    fi

    log_success "/nix store space OK (${available_gb}GB available)"
    return 0
}

check_generation_count() {
    log_info "Checking system generations..."

    local gen_count
    gen_count=$(ls -1 /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l || echo "0")

    log_verbose "Current generations: $gen_count"

    if [[ "$gen_count" -gt 50 ]]; then
        log_warning "High generation count ($gen_count) - consider cleanup"
        echo "  Run: sudo nix-collect-garbage --delete-older-than 14d"
        return 2
    elif [[ "$gen_count" -eq 0 ]]; then
        log_warning "No generations found (running in dev environment?)"
        return 2
    fi

    log_success "Generation count OK ($gen_count generations)"
    return 0
}

check_closure_diff() {
    log_info "Computing closure diff (current vs new)..."

    # Build the new configuration first
    local new_closure
    if ! new_closure=$(nix build "$FLAKE_DIR#nixosConfigurations.$HOST.config.system.build.toplevel" --no-link --print-out-paths 2>/dev/null); then
        log_warning "Could not build new closure for diff (non-critical)"
        return 2
    fi

    local current_system="/run/current-system"

    if [[ ! -e "$current_system" ]]; then
        log_verbose "No current system (fresh install or dev environment)"
        return 0
    fi

    # Use nix store diff-closures if available
    if nix store diff-closures "$current_system" "$new_closure" 2>/dev/null | head -20; then
        log_success "Closure diff computed"
    else
        log_verbose "Could not compute diff (nix store diff-closures not available)"
    fi

    return 0
}

check_git_status() {
    log_info "Checking git status..."

    cd "$FLAKE_DIR"

    if ! git rev-parse --git-dir &>/dev/null; then
        log_warning "Not a git repository"
        return 2
    fi

    local uncommitted
    uncommitted=$(git status --porcelain | wc -l)

    if [[ "$uncommitted" -gt 0 ]]; then
        log_warning "$uncommitted uncommitted changes in flake directory"
        if [[ "$VERBOSE" == "true" ]]; then
            git status --short
        fi
        return 2
    fi

    log_success "Git status clean"
    return 0
}

#######################################
# Main
#######################################

main() {
    echo ""
    echo "========================================="
    echo "  NixOS Laptop Preflight Check"
    echo "========================================="
    echo ""

    cd "$FLAKE_DIR"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v) VERBOSE=true; shift ;;
            --help|-h)
                echo "Usage: $0 [--verbose]"
                echo ""
                echo "Options:"
                echo "  --verbose, -v   Show detailed output"
                echo "  --help, -h      Show this help"
                exit 0
                ;;
            *) shift ;;
        esac
    done

    # Run checks
    local exit_code=0

    # Critical checks (fail = do not proceed)
    check_flake_syntax || exit_code=1
    check_host_config || exit_code=1
    check_boot_partition || { [[ $? -eq 1 ]] && exit_code=1; }
    check_nix_store_space || exit_code=1

    # Non-critical checks (warn only)
    check_insecure_packages || true
    check_generation_count || true
    check_git_status || true

    # Optional: closure diff (informational)
    if [[ "$VERBOSE" == "true" ]]; then
        check_closure_diff || true
    fi

    # Summary
    echo ""
    echo "========================================="
    echo "  Preflight Summary"
    echo "========================================="
    echo ""

    if [[ "$ERRORS" -gt 0 ]]; then
        log_error "Preflight FAILED: $ERRORS error(s), $WARNINGS warning(s)"
        echo ""
        echo "  Do NOT proceed with rebuild until errors are resolved."
        echo "  See docs/research/laptop-stability.md for recovery playbooks."
        echo ""
        exit 1
    elif [[ "$WARNINGS" -gt 0 ]]; then
        log_warning "Preflight PASSED with $WARNINGS warning(s)"
        echo ""
        echo "  Proceed with caution. Review warnings above."
        echo ""
        exit 2
    else
        log_success "Preflight PASSED: All checks OK"
        echo ""
        echo "  Safe to proceed with rebuild:"
        echo "    ./scripts/laptop/update-safe.sh"
        echo ""
        exit 0
    fi
}

main "$@"
