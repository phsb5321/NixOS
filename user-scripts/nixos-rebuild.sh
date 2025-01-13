#!/usr/bin/env bash

#######################################
# NixOS Rebuild Script
# Version: 4.1.0
#
# A self-contained script for managing NixOS rebuilds
# with improved permission handling and error recovery
#######################################

set -euo pipefail
IFS=$'\n\t'

#######################################
# Configuration
#######################################
readonly SCRIPT_VERSION="4.1.0"
readonly SCRIPT_NAME=$(basename "$0")
readonly FLAKE_DIR="$HOME/NixOS"
readonly LOG_DIR="$HOME/.local/share/nixos-rebuild/logs"
readonly STATE_DIR="$HOME/.local/share/nixos-rebuild/state"
readonly CACHE_DIR="$HOME/.cache/nixos-rebuild"
readonly LOCK_FILE="$HOME/.local/share/nixos-rebuild/rebuild.lock"
readonly DEFAULT_KEEP_GENERATIONS=7

# Color definitions for gum
declare -A COLORS=(
    ["primary"]="212"
    ["error"]="196"
    ["warning"]="214"
    ["success"]="84"
    ["info"]="39"
)

#######################################
# Error handling
#######################################
trap 'cleanup' EXIT
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_trace=$5

    log "Error occurred in ${SCRIPT_NAME}" "error"
    log "Exit code: ${exit_code}" "error"
    log "Line number: ${line_no}" "error"
    log "Last command: ${last_command}" "error"
    log "Function trace: ${func_trace}" "error"

    if [[ -f "${LOG_FILE:-}" ]]; then
        log "Check log file for details: $LOG_FILE" "info"
    fi

    cleanup
    exit "$exit_code"
}

cleanup() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
}

#######################################
# Utility functions
#######################################
die() {
    log "$1" "error"
    exit 1
}

# Enhanced permission checker
check_sudo_access() {
    # First try without password
    if sudo -n true 2>/dev/null; then
        return 0
    fi

    # If that fails, ask for password with gum
    local password
    echo "Sudo access is required for system operations."
    password=$(gum input --password --prompt "Password for $USER: ")

    # Verify the password
    if echo "$password" | sudo -S true >/dev/null 2>&1; then
        # Keep sudo alive
        sudo -v
        return 0
    else
        die "Incorrect password or sudo access denied"
    fi
}

ensure_directories() {
    local user_dirs=(
        "$LOG_DIR"
        "$STATE_DIR"
        "$CACHE_DIR"
        "${LOCK_FILE%/*}" # Lock file directory
    )

    for dir in "${user_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chmod 700 "$dir"
        fi
    done
}

check_requirements() {
    local -a required=("gum" "nix" "git" "alejandra")
    local missing=()

    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        die "Missing required tools: ${missing[*]}"
    fi
}

#######################################
# Logging functions
#######################################
log() {
    local msg=$1
    local level=${2:-info}
    local color="${COLORS[$level]:-39}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to file if LOG_FILE is defined
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$timestamp] $msg" >>"$LOG_FILE"
    fi

    # Log to console with color using gum
    gum style --foreground "$color" "[$timestamp] $msg"
}

setup_logging() {
    ensure_directories
    LOG_FILE="${LOG_DIR}/nixos-rebuild-${host:-system}-$(date '+%Y%m%d_%H%M%S').log"
    touch "$LOG_FILE"
}

#######################################
# Command execution
#######################################
execute() {
    local name=$1
    shift
    local cmd=("$@")
    local max_retries=3
    local retry_count=0
    local exit_code
    local error_log
    local temp_error
    temp_error=$(mktemp)

    while ((retry_count < max_retries)); do
        if [[ "${DRY_RUN:-false}" == true ]]; then
            log "Would execute: ${cmd[*]}" "info"
            rm -f "$temp_error"
            return 0
        fi

        log "Executing: $name (attempt $((retry_count + 1))/${max_retries})" "info"

        # Execute command and capture both stdout and stderr
        if { sudo "${cmd[@]}" 2> >(tee "$temp_error" >&2) >>"$LOG_FILE"; }; then
            log "✓ $name" "success"
            rm -f "$temp_error"
            return 0
        else
            exit_code=$?
            error_log=$(cat "$temp_error")
            retry_count=$((retry_count + 1))

            # Log the error details
            log "Command failed with exit code $exit_code" "error"
            log "Error output:" "error"
            echo "$error_log" | while IFS= read -r line; do
                log "  $line" "error"
            done >>"$LOG_FILE"

            if ((retry_count < max_retries)); then
                log "Retrying in 5 seconds..." "warning"
                sleep 5
                # Refresh sudo timestamp
                sudo -v
            else
                log "✗ $name failed after $max_retries attempts" "error"
                log "Last error message:" "error"
                echo "$error_log" | while IFS= read -r line; do
                    log "  $line" "error"
                done
                rm -f "$temp_error"
                return $exit_code
            fi
        fi
    done
}

#######################################
# System operations
#######################################
verify_flake_directory() {
    if [[ ! -d "$FLAKE_DIR" ]]; then
        die "Flake directory not found: $FLAKE_DIR"
    fi
    if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
        die "No flake.nix found in $FLAKE_DIR"
    fi
}

list_hosts() {
    local hosts_dir="$FLAKE_DIR/hosts"
    if [[ -d "$hosts_dir" ]]; then
        log "Available hosts:" "info"
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                log "• $(basename "$host")" "primary"
            fi
        done
    fi
}

verify_host() {
    local host=$1
    if [[ ! -d "$FLAKE_DIR/hosts/$host" ]]; then
        log "Host '$host' not found." "error"
        list_hosts
        exit 1
    fi
}

rebuild_system() {
    local host=$1
    cd "$FLAKE_DIR" || die "Could not change to flake directory"

    # Create lock file
    echo "$$" >"$LOCK_FILE"

    if [[ "${ROLLBACK:-false}" == true ]]; then
        execute "Rolling back system" nixos-rebuild rollback --flake ".#${host}"
        return
    fi

    if [[ "${SKIP_UPDATE:-false}" != true ]]; then
        log "Updating system..." "info"
        execute "Update channels" nix-channel --update
        execute "Update flake" nix flake update
    fi

    execute "Collecting garbage" nix-collect-garbage --delete-older-than "${KEEP_GENERATIONS:-$DEFAULT_KEEP_GENERATIONS}d"

    if [[ "${SKIP_OPTIMIZE:-false}" != true ]]; then
        execute "Optimizing store" nix-store --optimize
    fi

    if [[ "${SKIP_FORMAT:-false}" != true ]]; then
        execute "Formatting files" alejandra .
    fi

    local rebuild_cmd=(nixos-rebuild switch --flake ".#${host}")
    [[ "${DRY_RUN:-false}" == true ]] && rebuild_cmd+=(--dry-run)

    execute "Rebuilding system" "${rebuild_cmd[@]}"
    execute "Cleaning boot" /run/current-system/bin/switch-to-configuration boot

    if [[ "${DRY_RUN:-false}" != true && "${SKIP_PUSH:-false}" != true ]]; then
        local gen
        gen=$(nixos-rebuild --flake ".#${host}" list-generations | grep current)

        # Split git operations for better error handling
        log "Performing git operations..." "info"

        # Check git status
        if ! git status &>/dev/null; then
            log "Not a git repository or git command failed" "error"
            return 1
        fi

        # Check for changes
        if ! git diff-index --quiet HEAD --; then
            # Stage changes
            if ! git add .; then
                log "Failed to stage changes" "error"
                return 1
            fi

            # Commit changes
            if ! git commit -m "rebuild(${host}): ${gen}"; then
                log "Failed to commit changes" "error"
                return 1
            fi

            # Push changes
            if ! git push; then
                log "Failed to push changes" "error"
                log "You may need to pull changes first or check your remote configuration" "info"
                return 1
            fi
        else
            log "No changes to commit" "info"
        fi
    fi

    maintenance
}

maintenance() {
    log "Performing system maintenance..." "info"

    # Clean journal
    execute "Vacuum journals" journalctl --vacuum-time=7d

    # Clean temporary files
    execute "Cleaning temporary files" bash -c "find /tmp -mindepth 1 -delete 2>/dev/null || true"

    # Rotate logs
    if [[ -d "$LOG_DIR" ]]; then
        find "$LOG_DIR" -type f -mtime +30 -delete
    fi
}

#######################################
# Main script
#######################################
main() {
    local host=""
    DRY_RUN=false
    ROLLBACK=false
    SKIP_UPDATE=false
    SKIP_OPTIMIZE=false
    SKIP_FORMAT=false
    SKIP_PUSH=false
    KEEP_GENERATIONS=$DEFAULT_KEEP_GENERATIONS

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -n | --dry-run) DRY_RUN=true ;;
        --rollback) ROLLBACK=true ;;
        --no-update) SKIP_UPDATE=true ;;
        --no-optimize) SKIP_OPTIMIZE=true ;;
        --no-format) SKIP_FORMAT=true ;;
        --no-push) SKIP_PUSH=true ;;
        -k | --keep)
            shift
            KEEP_GENERATIONS=$1
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        -l | --list)
            list_hosts
            exit 0
            ;;
        *)
            if [[ -z "$host" ]]; then
                host=$1
            else
                die "Unknown option: $1"
            fi
            ;;
        esac
        shift
    done

    if [[ -z "$host" ]]; then
        die "No host specified. Use -l or --list to see available hosts."
    fi

    # Check for another running instance
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            die "Another instance is running (PID: $pid)"
        else
            rm -f "$LOCK_FILE"
        fi
    fi

    # Verify environment
    verify_flake_directory
    verify_host "$host"

    # Setup logging
    setup_logging

    # Check sudo access before proceeding
    check_sudo_access

    # Check if running in dry-run mode
    if [[ $DRY_RUN == true ]]; then
        log "Running in dry-run mode - no changes will be made" "warning"
    fi

    # Confirm rebuild
    if [[ $DRY_RUN == false ]]; then
        if ! gum confirm "Ready to rebuild $host. Continue?"; then
            log "Operation cancelled" "info"
            exit 0
        fi
    fi

    # Perform rebuild
    rebuild_system "$host"
}

show_help() {
    cat <<EOF
NixOS Rebuild Script v${SCRIPT_VERSION}

Usage: $SCRIPT_NAME [options] <host>

Options:
  -n, --dry-run       Dry run mode
  --rollback          Rollback to previous generation
  --no-update         Skip system updates
  --no-optimize       Skip store optimization
  --no-format         Skip file formatting
  --no-push           Skip git push
  -k, --keep DAYS     Keep generations for specified days (default: $DEFAULT_KEEP_GENERATIONS)
  -l, --list          List available hosts
  -h, --help          Show this help message

Available hosts:
$(for h in "$FLAKE_DIR"/hosts/*/; do echo "  $(basename "$h")"; done)
EOF
}

# Run main function if script is executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_requirements
    main "$@"
fi
