#!/usr/bin/env bash

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

cleanup() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
}

#######################################
# Utility functions
#######################################
die() {
    gum style --foreground "${COLORS[error]}" "$1" >&2
    exit 1
}

# Enhanced permission checker
check_sudo_access() {
    if sudo -n true 2>/dev/null; then
        return 0
    fi

    local password
    echo "Sudo access is required for system operations."
    password=$(gum input --password --prompt "Password for $USER: ")

    if echo "$password" | sudo -S true >/dev/null 2>&1; then
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
        "${LOCK_FILE%/*}"
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
        if ! command -v "$cmd" &> /dev/null; then
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

    # Always log to file
    echo "[$timestamp] ($level) $msg" >> "$LOG_FILE"

    # Only show non-info messages in terminal
    if [[ "$level" != "info" ]]; then
        gum style --foreground "$color" "[$timestamp] $msg"
    fi
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

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log "Would execute: ${cmd[*]}" "info"
        return 0
    fi

    log "Executing: $name" "info"
    if output=$(sudo "${cmd[@]}" 2>&1); then
        log "$output" "info"
        gum style --foreground "${COLORS[success]}" "✓ $name"
        return 0
    else
        local exit_code=$?
        log "Command failed: $name (exit code: $exit_code)" "error"
        log "$output" "error"
        gum style --foreground "${COLORS[error]}" "✗ $name failed"
        return $exit_code
    fi
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
        gum style --foreground "${COLORS[info]}" "Available hosts:"
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                gum style --foreground "${COLORS[primary]}" "• $(basename "$host")"
            fi
        done
    fi
}

verify_host() {
    local host=$1
    if [[ ! -d "$FLAKE_DIR/hosts/$host" ]]; then
        gum style --foreground "${COLORS[error]}" "Host '$host' not found."
        list_hosts
        exit 1
    fi
}

rebuild_system() {
    local host=$1
    cd "$FLAKE_DIR" || die "Could not change to flake directory"

    echo "$$" > "$LOCK_FILE"

    if [[ "${SKIP_UPDATE:-false}" != true ]]; then
        gum style --foreground "${COLORS[info]}" "Updating system..."
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

    if [[ "${DRY_RUN:-false}" != true && "${SKIP_PUSH:-false}" != true ]]; then
        local gen
        gen=$(nixos-rebuild --flake ".#${host}" list-generations | grep current)

        if ! git status &>/dev/null; then
            log "Not a git repository or git command failed" "error"
            return 1
        fi

        if ! git diff-index --quiet HEAD --; then
            if ! git add .; then
                log "Failed to stage changes" "error"
                return 1
            fi

            if ! git commit -m "rebuild(${host}): ${gen}"; then
                log "Failed to commit changes" "error"
                return 1
            fi

            if ! git push; then
                log "Failed to push changes" "error"
                log "You may need to pull changes first" "info"
                return 1
            fi
        else
            log "No changes to commit" "info"
        fi
    fi

    maintenance
}

maintenance() {
    log "Performing non-intrusive maintenance..." "info"

    # Vacuum systemd journals
    execute "Vacuum journals" journalctl --vacuum-time=7d

    # Clean old logs
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
    SKIP_UPDATE=false
    SKIP_OPTIMIZE=false
    SKIP_FORMAT=false
    SKIP_PUSH=false
    KEEP_GENERATIONS=$DEFAULT_KEEP_GENERATIONS

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--dry-run) DRY_RUN=true ;;
            --no-update) SKIP_UPDATE=true ;;
            --no-optimize) SKIP_OPTIMIZE=true ;;
            --no-format) SKIP_FORMAT=true ;;
            --no-push) SKIP_PUSH=true ;;
            -k|--keep) shift; KEEP_GENERATIONS=$1 ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
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

    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            die "Another instance is running (PID: $pid)"
        else
            rm -f "$LOCK_FILE"
        fi
    fi

    verify_flake_directory
    verify_host "$host"
    setup_logging
    check_sudo_access

    if [[ $DRY_RUN == true ]]; then
        gum style --foreground "${COLORS[warning]}" "Running in dry-run mode - no changes will be made"
    fi

    if [[ $DRY_RUN == false ]]; then
        if ! gum confirm "Ready to rebuild $host. Continue?"; then
            gum style --foreground "${COLORS[info]}" "Operation cancelled"
            exit 0
        fi
    fi

    rebuild_system "$host"
}

show_help() {
    cat << EOF
NixOS Rebuild Script v${SCRIPT_VERSION}

Usage: $SCRIPT_NAME [options] <host>

Options:
  -n, --dry-run       Dry run mode
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_requirements
    main "$@"
fi