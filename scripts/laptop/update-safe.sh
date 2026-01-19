#!/usr/bin/env bash
#
# NixOS Laptop Safe Update Workflow
# Implements guardrails for safe system updates
#
# Workflow:
#   1. Create git branch for update
#   2. Update flake inputs (selective or all)
#   3. Run preflight checks
#   4. Test activation (nixos-rebuild test)
#   5. Run health check
#   6. Commit to boot (nixos-rebuild boot)
#   7. Prompt for reboot
#
# Usage: ./scripts/laptop/update-safe.sh [options]
#
# Options:
#   --inputs INPUTS   Update only specific inputs (comma-separated)
#   --skip-branch     Don't create a git branch
#   --auto-reboot     Reboot automatically after success
#   --dry-run         Show what would be done without executing
#   --verbose         Show detailed output
#   --help            Show this help

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_DIR="${SCRIPT_DIR}/../.."
readonly HOST="laptop"
readonly DATE=$(date '+%Y-%m-%d')
readonly BRANCH_NAME="laptop/update-${DATE}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Options
INPUTS=""
SKIP_BRANCH=false
AUTO_REBOOT=false
DRY_RUN=false
VERBOSE=false

#######################################
# Logging functions
#######################################

log_step() {
    echo ""
    echo -e "${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} Would execute: $1"
}

run_cmd() {
    local cmd="$*"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$cmd"
        return 0
    else
        if [[ "$VERBOSE" == "true" ]]; then
            log_info "Running: $cmd"
        fi
        eval "$cmd"
    fi
}

#######################################
# Workflow steps
#######################################

step_create_branch() {
    log_step "Step 1: Creating update branch"

    cd "$FLAKE_DIR"

    if [[ "$SKIP_BRANCH" == "true" ]]; then
        log_info "Skipping branch creation (--skip-branch)"
        return 0
    fi

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
        log_warning "Branch $BRANCH_NAME already exists"
        if [[ "$DRY_RUN" != "true" ]]; then
            read -p "Switch to existing branch? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                run_cmd "git checkout $BRANCH_NAME"
            else
                log_error "Aborted by user"
                exit 1
            fi
        fi
    else
        run_cmd "git checkout -b $BRANCH_NAME"
        log_success "Created and switched to branch: $BRANCH_NAME"
    fi
}

step_update_inputs() {
    log_step "Step 2: Updating flake inputs"

    cd "$FLAKE_DIR"

    if [[ -n "$INPUTS" ]]; then
        # Update specific inputs
        IFS=',' read -ra INPUT_ARRAY <<< "$INPUTS"
        for input in "${INPUT_ARRAY[@]}"; do
            log_info "Updating input: $input"
            run_cmd "nix flake update $FLAKE_DIR $input --refresh"
        done
    else
        # Update all inputs
        log_info "Updating all flake inputs..."
        run_cmd "nix flake update $FLAKE_DIR --refresh"
    fi

    log_success "Flake inputs updated"

    # Show what changed
    if [[ "$DRY_RUN" != "true" ]]; then
        echo ""
        log_info "Changes to flake.lock:"
        git diff --stat flake.lock || true
        echo ""
    fi
}

step_preflight() {
    log_step "Step 3: Running preflight checks"

    local preflight_script="$SCRIPT_DIR/preflight.sh"

    if [[ ! -x "$preflight_script" ]]; then
        log_error "Preflight script not found or not executable: $preflight_script"
        exit 1
    fi

    local preflight_args=""
    if [[ "$VERBOSE" == "true" ]]; then
        preflight_args="--verbose"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$preflight_script $preflight_args"
        return 0
    fi

    if ! "$preflight_script" $preflight_args; then
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            log_error "Preflight checks FAILED - cannot proceed"
            echo ""
            echo "  Fix the errors above and try again."
            echo "  See docs/research/laptop-stability.md for recovery playbooks."
            exit 1
        elif [[ $exit_code -eq 2 ]]; then
            log_warning "Preflight checks passed with warnings"
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Aborted by user"
                exit 0
            fi
        fi
    fi

    log_success "Preflight checks passed"
}

step_test_activation() {
    log_step "Step 4: Testing configuration activation"

    log_info "Running: nixos-rebuild test --flake .#$HOST"
    log_info "This will activate the new configuration WITHOUT adding it to the bootloader."
    log_info "If anything goes wrong, a reboot will restore the previous configuration."
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "sudo nixos-rebuild test --flake $FLAKE_DIR#$HOST"
        return 0
    fi

    # Request sudo upfront
    sudo -v

    if ! sudo nixos-rebuild test --flake "$FLAKE_DIR#$HOST" --show-trace; then
        log_error "Test activation FAILED"
        echo ""
        echo "  The configuration could not be activated."
        echo "  Your system is still running the previous configuration."
        echo "  If you're stuck, reboot to restore the previous state."
        echo ""
        exit 1
    fi

    log_success "Test activation succeeded"
}

step_healthcheck() {
    log_step "Step 5: Running post-activation health check"

    local healthcheck_script="$SCRIPT_DIR/healthcheck.sh"

    if [[ ! -x "$healthcheck_script" ]]; then
        log_warning "Healthcheck script not found: $healthcheck_script"
        return 0
    fi

    local healthcheck_args=""
    if [[ "$VERBOSE" == "true" ]]; then
        healthcheck_args="--verbose"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$healthcheck_script $healthcheck_args"
        return 0
    fi

    if ! "$healthcheck_script" $healthcheck_args; then
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            log_error "Health check FAILED - system may be unstable"
            echo ""
            echo "  The configuration activated but health checks failed."
            echo "  Consider rebooting to restore the previous configuration."
            echo ""
            read -p "Abort and recommend reboot? [Y/n] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                log_info "Reboot recommended to restore previous configuration"
                exit 1
            fi
        fi
    fi

    log_success "Health check passed"
}

step_commit_to_boot() {
    log_step "Step 6: Committing configuration to bootloader"

    log_info "Running: nixos-rebuild boot --flake .#$HOST"
    log_info "This will add the new configuration to the bootloader."
    log_info "The new configuration will become the default on next boot."
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "sudo nixos-rebuild boot --flake $FLAKE_DIR#$HOST"
        return 0
    fi

    # Request sudo upfront (should still be cached)
    sudo -v

    if ! sudo nixos-rebuild boot --flake "$FLAKE_DIR#$HOST"; then
        log_error "Boot commit FAILED"
        echo ""
        echo "  Could not add configuration to bootloader."
        echo "  The current session is running the new configuration,"
        echo "  but it will NOT be default on reboot."
        echo ""
        exit 1
    fi

    log_success "Configuration committed to bootloader"
}

step_git_commit() {
    log_step "Step 7: Committing changes to git"

    cd "$FLAKE_DIR"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "git add flake.lock && git commit -m 'chore(laptop): update flake inputs $DATE'"
        return 0
    fi

    if ! git diff --quiet flake.lock 2>/dev/null; then
        run_cmd "git add flake.lock"
        run_cmd "git commit -m 'chore(laptop): update flake inputs $DATE'"
        log_success "Changes committed to git"
    else
        log_info "No changes to commit"
    fi
}

step_prompt_reboot() {
    log_step "Step 8: Update complete"

    echo ""
    echo -e "${GREEN}${BOLD}=========================================${NC}"
    echo -e "${GREEN}${BOLD}  Safe Update Complete!${NC}"
    echo -e "${GREEN}${BOLD}=========================================${NC}"
    echo ""
    echo "  The new configuration has been:"
    echo "    - Tested and activated"
    echo "    - Health-checked"
    echo "    - Committed to bootloader"
    echo "    - Committed to git (branch: $BRANCH_NAME)"
    echo ""
    echo "  Reboot to fully switch to the new configuration."
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    if [[ "$AUTO_REBOOT" == "true" ]]; then
        log_info "Auto-reboot enabled. Rebooting in 5 seconds..."
        sleep 5
        sudo reboot
    else
        read -p "Reboot now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo reboot
        else
            log_info "Reboot when ready with: sudo reboot"
        fi
    fi
}

#######################################
# Main
#######################################

show_help() {
    cat << EOF
NixOS Laptop Safe Update Workflow

Usage: $0 [options]

Options:
  --inputs INPUTS   Update only specific inputs (comma-separated)
                    Example: --inputs nixpkgs,nixpkgs-unstable
  --skip-branch     Don't create a git branch
  --auto-reboot     Reboot automatically after success
  --dry-run         Show what would be done without executing
  --verbose         Show detailed output
  --help            Show this help

Workflow:
  1. Create git branch: laptop/update-YYYY-MM-DD
  2. Update flake inputs
  3. Run preflight checks
  4. Test activation (nixos-rebuild test)
  5. Run health check
  6. Commit to boot (nixos-rebuild boot)
  7. Commit to git
  8. Prompt for reboot

This workflow ensures:
  - Configuration is tested before committing to boot
  - A reboot restores the previous configuration if test fails
  - Health checks verify the system is stable
  - Git tracks all changes for rollback
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --inputs) INPUTS="$2"; shift 2 ;;
            --skip-branch) SKIP_BRANCH=true; shift ;;
            --auto-reboot) AUTO_REBOOT=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --verbose|-v) VERBOSE=true; shift ;;
            --help|-h) show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done

    echo ""
    echo -e "${BOLD}=========================================${NC}"
    echo -e "${BOLD}  NixOS Laptop Safe Update${NC}"
    echo -e "${BOLD}=========================================${NC}"
    echo ""
    echo "  Host: $HOST"
    echo "  Date: $DATE"
    if [[ -n "$INPUTS" ]]; then
        echo "  Inputs: $INPUTS"
    else
        echo "  Inputs: all"
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  Mode: ${YELLOW}DRY-RUN${NC}"
    fi
    echo ""

    # Execute workflow
    step_create_branch
    step_update_inputs
    step_preflight
    step_test_activation
    step_healthcheck
    step_commit_to_boot
    step_git_commit
    step_prompt_reboot
}

main "$@"
