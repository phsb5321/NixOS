#!/usr/bin/env bash
#
# NixOS Laptop Post-Rebuild Health Check
# Verifies system health after nixos-rebuild
#
# Usage: ./scripts/laptop/healthcheck.sh [--verbose] [--gdm-only]
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical check failed (system may be unstable)
#   2 - Warning (non-critical issue detected)

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_DIR="${SCRIPT_DIR}/../.."

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERBOSE=false
GDM_ONLY=false
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

check_system_running() {
    log_info "Checking systemd system state..."

    local state
    state=$(systemctl is-system-running 2>/dev/null || echo "unknown")

    log_verbose "System state: $state"

    case "$state" in
        running)
            log_success "System is running normally"
            return 0
            ;;
        degraded)
            log_warning "System is degraded (some units failed)"
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  Failed units:"
                systemctl --failed --no-pager | head -10
            fi
            return 2
            ;;
        maintenance|initializing|starting)
            log_warning "System is in $state state"
            return 2
            ;;
        *)
            log_error "System state is: $state"
            return 1
            ;;
    esac
}

check_gdm_service() {
    log_info "Checking GDM display manager..."

    # Check if GDM is the active display manager
    if ! systemctl is-active --quiet gdm; then
        # Maybe using different display manager
        if systemctl is-active --quiet display-manager; then
            log_success "Display manager is active (not GDM)"
            return 0
        fi
        log_error "GDM service is not running"
        return 1
    fi

    log_success "GDM service is active"

    # Check for GDM errors in journal
    log_info "Checking GDM journal for errors..."

    local gdm_errors
    gdm_errors=$(journalctl -b -u gdm -p warning..alert --no-pager 2>/dev/null | tail -20 || true)

    if [[ -n "$gdm_errors" ]]; then
        local error_count
        error_count=$(echo "$gdm_errors" | wc -l)

        if [[ "$error_count" -gt 5 ]]; then
            log_warning "GDM has $error_count warnings/errors in current boot"
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  Recent errors:"
                echo "$gdm_errors" | head -5
            fi
            return 2
        fi
    fi

    log_success "GDM journal clean"
    return 0
}

check_gdm_wayland_status() {
    log_info "Checking GDM Wayland/X11 status..."

    # Check current session type
    local session_type
    session_type=$(loginctl show-session "$(loginctl | grep "$(whoami)" | awk '{print $1}')" -p Type --value 2>/dev/null || echo "unknown")

    log_verbose "Current session type: $session_type"

    # Check GDM configuration
    if [[ -f /etc/gdm/custom.conf ]]; then
        if grep -q "WaylandEnable=false" /etc/gdm/custom.conf 2>/dev/null; then
            log_info "GDM configured for X11 (Wayland disabled)"
        else
            log_info "GDM configured for Wayland"
        fi
    fi

    # Check for NVIDIA which often needs X11
    if lspci 2>/dev/null | grep -qi nvidia; then
        if [[ "$session_type" == "wayland" ]]; then
            log_warning "Running Wayland with NVIDIA GPU (may cause issues)"
            echo "  If you experience black screens, force X11:"
            echo "    services.xserver.displayManager.gdm.wayland = false;"
            return 2
        fi
    fi

    log_success "Display session type: $session_type"
    return 0
}

check_graphical_target() {
    log_info "Checking graphical target..."

    if systemctl is-active --quiet graphical.target; then
        log_success "Graphical target is active"
        return 0
    else
        log_error "Graphical target is not active"
        return 1
    fi
}

check_critical_services() {
    log_info "Checking critical services..."

    local services=(
        "NetworkManager"
        "systemd-resolved"
        "dbus"
    )

    local failed_services=()

    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            failed_services+=("$service")
        else
            log_verbose "$service: active"
        fi
    done

    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_error "Critical services not running: ${failed_services[*]}"
        return 1
    fi

    log_success "All critical services running"
    return 0
}

check_network_connectivity() {
    log_info "Checking network connectivity..."

    # Check if we can reach the gateway
    local gateway
    gateway=$(ip route | grep default | awk '{print $3}' | head -1)

    if [[ -z "$gateway" ]]; then
        log_warning "No default gateway (offline or WiFi not connected)"
        return 2
    fi

    log_verbose "Gateway: $gateway"

    # Ping gateway
    if ! ping -c 1 -W 2 "$gateway" &>/dev/null; then
        log_warning "Cannot reach gateway $gateway"
        return 2
    fi

    # Check DNS resolution
    if ! host google.com &>/dev/null 2>&1; then
        log_warning "DNS resolution not working"
        return 2
    fi

    log_success "Network connectivity OK"
    return 0
}

check_boot_partition() {
    log_info "Checking /boot partition..."

    if [[ ! -d /boot ]]; then
        log_warning "/boot not mounted"
        return 2
    fi

    local usage_percent
    usage_percent=$(df /boot --output=pcent | tail -1 | tr -d ' %')

    if [[ "$usage_percent" -ge 80 ]]; then
        log_warning "/boot is ${usage_percent}% full - cleanup recommended"
        echo "  Run: sudo nix-collect-garbage -d"
        return 2
    fi

    log_success "/boot partition OK (${usage_percent}% used)"
    return 0
}

check_current_generation() {
    log_info "Checking current system generation..."

    local current_gen
    current_gen=$(readlink -f /run/current-system 2>/dev/null || echo "unknown")

    if [[ "$current_gen" == "unknown" ]]; then
        log_warning "Could not determine current generation"
        return 2
    fi

    # Extract generation number from path
    local gen_num
    gen_num=$(echo "$current_gen" | grep -oP 'system-\K\d+' || echo "?")

    log_success "Running generation: $gen_num"

    # Count available generations
    local gen_count
    gen_count=$(ls -1d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l || echo "0")

    log_verbose "Available generations: $gen_count"

    if [[ "$gen_count" -lt 2 ]]; then
        log_warning "Only $gen_count generation(s) available - limited rollback options"
        return 2
    fi

    return 0
}

check_failed_units() {
    log_info "Checking for failed systemd units..."

    local failed_units
    failed_units=$(systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l || echo "0")

    if [[ "$failed_units" -gt 0 ]]; then
        log_warning "$failed_units systemd unit(s) failed"
        if [[ "$VERBOSE" == "true" ]]; then
            systemctl --failed --no-pager | head -10
        fi
        return 2
    fi

    log_success "No failed systemd units"
    return 0
}

check_journal_errors() {
    log_info "Checking journal for critical errors..."

    # Look for critical errors in current boot
    local crit_count
    crit_count=$(journalctl -b -p crit --no-pager 2>/dev/null | wc -l || echo "0")

    if [[ "$crit_count" -gt 10 ]]; then
        log_warning "$crit_count critical messages in journal"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "  Recent critical messages:"
            journalctl -b -p crit --no-pager | tail -5
        fi
        return 2
    fi

    log_success "Journal critical errors: $crit_count"
    return 0
}

#######################################
# Main
#######################################

main() {
    echo ""
    echo "========================================="
    echo "  NixOS Laptop Health Check"
    echo "========================================="
    echo ""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v) VERBOSE=true; shift ;;
            --gdm-only) GDM_ONLY=true; shift ;;
            --help|-h)
                echo "Usage: $0 [--verbose] [--gdm-only]"
                echo ""
                echo "Options:"
                echo "  --verbose, -v   Show detailed output"
                echo "  --gdm-only      Only check GDM/display manager"
                echo "  --help, -h      Show this help"
                exit 0
                ;;
            *) shift ;;
        esac
    done

    local exit_code=0

    if [[ "$GDM_ONLY" == "true" ]]; then
        # GDM-specific checks only
        check_gdm_service || { [[ $? -eq 1 ]] && exit_code=1; }
        check_gdm_wayland_status || true
        check_graphical_target || exit_code=1
    else
        # Full system health check
        check_system_running || { [[ $? -eq 1 ]] && exit_code=1; }
        check_gdm_service || { [[ $? -eq 1 ]] && exit_code=1; }
        check_gdm_wayland_status || true
        check_graphical_target || exit_code=1
        check_critical_services || exit_code=1
        check_network_connectivity || true
        check_boot_partition || true
        check_current_generation || true
        check_failed_units || true
        check_journal_errors || true
    fi

    # Summary
    echo ""
    echo "========================================="
    echo "  Health Check Summary"
    echo "========================================="
    echo ""

    if [[ "$ERRORS" -gt 0 ]]; then
        log_error "Health check FAILED: $ERRORS error(s), $WARNINGS warning(s)"
        echo ""
        echo "  System may be unstable. Consider rollback:"
        echo "    sudo nixos-rebuild --rollback switch"
        echo ""
        echo "  Or boot to previous generation from boot menu."
        echo ""
        exit 1
    elif [[ "$WARNINGS" -gt 0 ]]; then
        log_warning "Health check PASSED with $WARNINGS warning(s)"
        echo ""
        echo "  System is functional but some issues detected."
        echo "  Review warnings above."
        echo ""
        exit 2
    else
        log_success "Health check PASSED: All checks OK"
        echo ""
        echo "  System is healthy and stable."
        echo ""
        exit 0
    fi
}

main "$@"
