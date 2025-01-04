#!/usr/bin/env bash

set -euo pipefail

# Configuration
SCRIPT_VERSION="3.1.0"
FLAKE_DIR="$HOME/NixOS"
LOG_DIR="$HOME/.local/share/nixos-rebuild/logs"
STATE_DIR="$HOME/.local/share/nixos-rebuild/state"
CACHE_DIR="$HOME/.cache/nixos-rebuild"

declare -A COLORS=(
    ["primary"]="212"
    ["error"]="196"
    ["warning"]="214"
    ["success"]="84"
    ["info"]="39"
)

# Check required tools
check_requirements() {
    local -a required=("gum" "nix" "git" "alejandra")
    local missing=()

    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        gum style --foreground "${COLORS[error]}" "Missing: ${missing[*]}"
        exit 1
    fi
}

# Clean logging function
log() {
    local msg=$1
    local color=${2:-${COLORS[info]}}
    gum style --foreground "$color" "$msg"
}

# Execute command with status
execute() {
    local name=$1
    shift
    local cmd=("$@")

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log "Would execute: ${cmd[*]}"
        return 0
    fi

    if gum spin --spinner dot --title "$name" -- "${cmd[@]}" &> "$LOG_FILE"; then
        log "✓ $name" "${COLORS[success]}"
    else
        log "✗ $name failed" "${COLORS[error]}"
        return 1
    fi
}

# Show available hosts
list_hosts() {
    local hosts_dir="$FLAKE_DIR/hosts"
    if [[ -d "$hosts_dir" ]]; then
        log "Available hosts:"
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                log "• $(basename "$host")" "${COLORS[primary]}"
            fi
        done
    fi
}

# Verify host exists
verify_host() {
    local host=$1
    if [[ ! -d "$FLAKE_DIR/hosts/$host" ]]; then
        log "Host '$host' not found." "${COLORS[error]}"
        list_hosts
        exit 1
    fi
}

# Main rebuild process
rebuild_system() {
    local host=$1
    cd "$FLAKE_DIR"

    # Initialize logging
    mkdir -p "$LOG_DIR" "$STATE_DIR" "$CACHE_DIR"
    LOG_FILE="${LOG_DIR}/nixos-rebuild-${host}-$(date '+%Y%m%d_%H%M%S').log"

    if [[ "${ROLLBACK:-false}" == true ]]; then
        execute "Rolling back system" sudo nixos-rebuild rollback --flake ".#${host}"
        return
    fi

    if [[ "${SKIP_UPDATE:-false}" != true ]]; then
        log "Updating system..."
        execute "Update channels" sudo nix-channel --update
        execute "Update flake" nix flake update
    fi

    execute "Collecting garbage" sudo nix-collect-garbage --delete-older-than "${KEEP_GENERATIONS:-5}d"

    if [[ "${SKIP_OPTIMIZE:-false}" != true ]]; then
        execute "Optimizing store" sudo nix-store --optimize
    fi

    if [[ "${SKIP_FORMAT:-false}" != true ]]; then
        execute "Formatting files" alejandra .
    fi

    local rebuild_cmd=(sudo nixos-rebuild switch --flake ".#${host}")
    [[ "${DRY_RUN:-false}" == true ]] && rebuild_cmd+=(--dry-run)

    execute "Rebuilding system" "${rebuild_cmd[@]}"
    execute "Cleaning boot" sudo /run/current-system/bin/switch-to-configuration boot

    if [[ "${DRY_RUN:-false}" != true && "${SKIP_PUSH:-false}" != true ]]; then
        gen=$(nixos-rebuild --flake ".#${host}" list-generations | grep current)
        execute "Git operations" git add . && git commit -m "rebuild(${host}): ${gen}" && git push
    fi
}

# Parse arguments
main() {
    local host=""
    DRY_RUN=false
    ROLLBACK=false
    SKIP_UPDATE=false
    SKIP_OPTIMIZE=false
    SKIP_FORMAT=false
    SKIP_PUSH=false
    KEEP_GENERATIONS=5

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--dry-run) DRY_RUN=true ;;
            --rollback) ROLLBACK=true ;;
            --no-update) SKIP_UPDATE=true ;;
            --no-optimize) SKIP_OPTIMIZE=true ;;
            --no-format) SKIP_FORMAT=true ;;
            --no-push) SKIP_PUSH=true ;;
            -k|--keep) shift; KEEP_GENERATIONS=$1 ;;
            -h|--help)
                log "Usage: nixos-rebuild [options] <host>"
                log "Options:"
                log "  -n, --dry-run      Dry run mode"
                log "  --rollback         Rollback system"
                log "  --no-update        Skip updates"
                log "  --no-optimize      Skip optimization"
                log "  --no-format        Skip formatting"
                log "  --no-push          Skip git push"
                log "  -k, --keep DAYS    Keep generations for DAYS days"
                list_hosts
                exit 0
                ;;
            *)
                if [[ -z "$host" ]]; then
                    host=$1
                else
                    log "Unknown option: $1" "${COLORS[error]}"
                    exit 1
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$host" ]]; then
        log "No host specified" "${COLORS[error]}"
        list_hosts
        exit 1
    fi

    verify_host "$host"

    if [[ $DRY_RUN == true ]]; then
        log "Dry run mode - no changes will be made" "${COLORS[warning]}"
    fi

    if [[ $DRY_RUN == false ]]; then
        if ! gum confirm "Ready to rebuild $host. Continue?"; then
            log "Operation cancelled"
            exit 0
        fi
    fi

    rebuild_system "$host"
}

check_requirements
main "$@"
