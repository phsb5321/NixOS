#!/usr/bin/env bash

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Script meta information
readonly SCRIPT_VERSION="3.0.0"
readonly SCRIPT_NAME=$(basename "$0")

# Configuration
readonly FLAKE_DIR="$HOME/NixOS"
readonly LOG_DIR="$HOME/.local/share/nixos-rebuild/logs"
readonly STATE_DIR="$HOME/.local/share/nixos-rebuild/state"
readonly CACHE_DIR="$HOME/.cache/nixos-rebuild"

# Emojis for different operations
declare -A EMOJIS=(
    ["UPDATE"]="📦"
    ["BUILD"]="🔨"
    ["INSTALL"]="📥"
    ["CLEAN"]="🧹"
    ["FORMAT"]="✨"
    ["ERROR"]="❌"
    ["SUCCESS"]="✅"
    ["WARNING"]="⚠️"
    ["INFO"]="ℹ️"
    ["DEBUG"]="🔍"
    ["COMMIT"]="📝"
    ["PUSH"]="🚀"
    ["ROLLBACK"]="⏮️"
    ["START"]="🎬"
    ["END"]="🏁"
    ["CONFIG"]="⚙️"
    ["TIME"]="⏱️"
)

# Theme colors using gum
declare -A COLORS=(
    ["primary"]="212"    # Light blue
    ["secondary"]="213"  # Light purple
    ["success"]="78"     # Light green
    ["error"]="197"      # Light red
    ["warning"]="214"    # Light orange
    ["info"]="75"        # Sky blue
    ["dim"]="242"        # Gray
)

# Check for required commands
check_requirements() {
    local -a required_commands=("gum" "nix" "git" "alejandra")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -ne 0 ]; then
        gum style --foreground "${COLORS[error]}" \
            "${EMOJIS[ERROR]} Missing required commands: ${missing_commands[*]}"
        exit 1
    fi
}

# Formatted logging with emojis and colors
log() {
    local level=$1
    local message=$2
    local emoji=${EMOJIS[$level]}
    local timestamp=$(date '+%H:%M:%S')
    local color="${COLORS[info]}"

    case $level in
        "ERROR") color="${COLORS[error]}" ;;
        "WARNING") color="${COLORS[warning]}" ;;
        "SUCCESS") color="${COLORS[success]}" ;;
        "INFO") color="${COLORS[info]}" ;;
        "DEBUG") color="${COLORS[dim]}" ;;
    esac

    gum style \
        --foreground "$color" \
        "[$timestamp] $emoji $message"
}

# Pretty print section header
print_section() {
    local title=$1
    local subtitle=${2:-}

    gum style \
        --border double \
        --border-foreground "${COLORS[secondary]}" \
        --align center \
        --width 70 \
        --margin "1 2" \
        --padding "1 2" \
        "$(gum style --foreground "${COLORS[primary]}" "$title")" \
        "$([ -n "$subtitle" ] && gum style --foreground "${COLORS[dim]}" "$subtitle")"
}

# Function to list available hosts with pretty formatting
list_available_hosts() {
    local hosts_dir="$FLAKE_DIR/hosts"
    if [[ -d "$hosts_dir" ]]; then
        echo
        gum style --foreground "${COLORS[primary]}" "📂 Available Hosts:"
        echo
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                local host_name=$(basename "$host")
                gum style --foreground "${COLORS[secondary]}" "   • $host_name"
            fi
        done
        echo
    fi
}

# Enhanced verification with pretty output
verify_host() {
    local host=$1
    if [[ ! -d "$FLAKE_DIR/hosts/$host" ]]; then
        log "ERROR" "Host '$host' not found!"
        list_available_hosts
        exit 1
    fi
}

# Format duration for display
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local remaining_seconds=$((seconds % 60))

    if [[ $hours -gt 0 ]]; then
        printf "${EMOJIS[TIME]} %dh %dm %ds" $hours $minutes $remaining_seconds
    elif [[ $minutes -gt 0 ]]; then
        printf "${EMOJIS[TIME]} %dm %ds" $minutes $remaining_seconds
    else
        printf "${EMOJIS[TIME]} %ds" $remaining_seconds
    fi
}

# Enhanced execution with spinner and timing
execute() {
    local cmd_name=$1
    shift
    local cmd=("$@")
    local start_time=$(date +%s)

    # Create unique temp file for this operation
    local temp_log="${CACHE_DIR}/temp_${RANDOM}.log"
    mkdir -p "$(dirname "$temp_log")"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log "INFO" "Would execute: ${cmd[*]}"
        return 0
    fi

    # Show progress with spinner
    if gum spin --spinner minidot --title "$(gum style --foreground "${COLORS[primary]}" "$cmd_name")" -- \
        "${cmd[@]}" > "$temp_log" 2>&1; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log "SUCCESS" "$cmd_name completed $(format_duration $duration)"
        cat "$temp_log" >> "$LOG_FILE"
    else
        local exit_code=$?
        log "ERROR" "$cmd_name failed!"
        echo
        gum style --foreground "${COLORS[error]}" "Last 10 lines of output:"
        tail -n 10 "$temp_log" | gum format
        cat "$temp_log" >> "$LOG_FILE"
        rm -f "$temp_log"
        return $exit_code
    fi
    rm -f "$temp_log"
}

# Pretty help message
show_help() {
    print_section "NixOS Rebuild v${SCRIPT_VERSION}" "A beautiful system rebuild experience"

    gum style --foreground "${COLORS[primary]}" "\nUsage:"
    echo "  $SCRIPT_NAME [OPTIONS] <host>"

    gum style --foreground "${COLORS[primary]}" "\nOptions:"
    gum style "  -h, --help              $(gum style --foreground "${COLORS[dim]}" "Show this help message")"
    gum style "  -v, --version           $(gum style --foreground "${COLORS[dim]}" "Show script version")"
    gum style "  -d, --debug             $(gum style --foreground "${COLORS[dim]}" "Enable debug mode")"
    gum style "  -n, --dry-run           $(gum style --foreground "${COLORS[dim]}" "Perform a dry run")"
    gum style "  -f, --force             $(gum style --foreground "${COLORS[dim]}" "Skip confirmations")"
    gum style "  -k, --keep GENS         $(gum style --foreground "${COLORS[dim]}" "Generations to keep")"
    gum style "  --no-update             $(gum style --foreground "${COLORS[dim]}" "Skip flake updates")"
    gum style "  --no-optimize           $(gum style --foreground "${COLORS[dim]}" "Skip optimization")"
    gum style "  --no-format             $(gum style --foreground "${COLORS[dim]}" "Skip formatting")"
    gum style "  --no-push               $(gum style --foreground "${COLORS[dim]}" "Skip git push")"
    gum style "  --rollback              $(gum style --foreground "${COLORS[dim]}" "Rollback system")"

    list_available_hosts
}

# Main rebuild process
main() {
    local host=$1
    local start_time=$(date +%s)

    # Print welcome banner
    print_section \
        "${EMOJIS[START]} NixOS Rebuild v${SCRIPT_VERSION}" \
        "Host: $host | Mode: $(if [[ $DRY_RUN == true ]]; then echo "Dry Run ${EMOJIS[DEBUG]}"; else echo "Normal ${EMOJIS[CONFIG]}"; fi)"

    cd "$FLAKE_DIR"

    # Handle rollback
    if [[ $ROLLBACK == true ]]; then
        print_section "${EMOJIS[ROLLBACK]} Rolling Back System"
        execute "System Rollback" sudo nixos-rebuild rollback --flake ".#${host}"
        return $?
    fi

    # Update phase
    if [[ $SKIP_UPDATE == false ]]; then
        print_section "${EMOJIS[UPDATE]} Update Phase"
        execute "Update Channels" sudo nix-channel --update
        execute "Update Flake" nix flake update
    fi

    # Cleanup phase
    print_section "${EMOJIS[CLEAN]} Cleanup Phase"
    execute "Garbage Collection" sudo nix-collect-garbage --delete-older-than "${KEEP_GENERATIONS}d"

    if [[ $SKIP_OPTIMIZE == false ]]; then
        execute "Store Optimization" sudo nix-store --optimize
    fi

    # Format phase
    if [[ $SKIP_FORMAT == false ]]; then
        print_section "${EMOJIS[FORMAT]} Format Phase"
        execute "Format Files" alejandra .
    fi

    # Build phase
    print_section "${EMOJIS[BUILD]} Build Phase"
    rebuild_cmd=(sudo nixos-rebuild switch --flake ".#${host}")
    if [[ $DRY_RUN == true ]]; then
        rebuild_cmd+=(--dry-run)
    fi

    if ! execute "NixOS Rebuild" "${rebuild_cmd[@]}"; then
        log "ERROR" "Build failed! Check the logs at $LOG_FILE"
        return 1
    fi

    execute "Boot Cleanup" sudo /run/current-system/bin/switch-to-configuration boot

    # Commit phase
    if [[ $DRY_RUN == false ]]; then
        print_section "${EMOJIS[COMMIT]} Commit Phase"
        gen=$(nixos-rebuild --flake ".#${host}" list-generations | grep current)

        execute "Git Add" git add .
        execute "Git Commit" git commit -m "rebuild(${host}): ${gen}"

        if [[ $SKIP_PUSH == false ]]; then
            execute "Git Push" git push
        fi
    fi

    # Calculate total duration
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    # Final success message
    print_section \
        "${EMOJIS[END]} NixOS Update Complete!" \
        "\nHost: ${host}\nTotal Time: $(format_duration $total_duration)\nLog: ${LOG_FILE}"

    log "SUCCESS" "System update complete! You may need to restart for all changes to take effect."
}

# Parse arguments and run
parse_args_and_run() {
    # Check requirements first
    check_requirements

    # Parse options
    TEMP=$(getopt -o hvdnfk: --long help,version,debug,dry-run,force,keep:,no-update,no-optimize,no-format,no-push,rollback -n "$SCRIPT_NAME" -- "$@")
    eval set -- "$TEMP"

    # Default values
    DRY_RUN=false
    FORCE=false
    KEEP_GENERATIONS=5
    SKIP_UPDATE=false
    SKIP_OPTIMIZE=false
    SKIP_FORMAT=false
    SKIP_PUSH=false
    ROLLBACK=false

    while true; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version)
                print_section "NixOS Rebuild" "Version ${SCRIPT_VERSION}"
                exit 0
                ;;
            -d|--debug) set -x; shift ;;
            -n|--dry-run) DRY_RUN=true; shift ;;
            -f|--force) FORCE=true; shift ;;
            -k|--keep) KEEP_GENERATIONS=$2; shift 2 ;;
            --no-update) SKIP_UPDATE=true; shift ;;
            --no-optimize) SKIP_OPTIMIZE=true; shift ;;
            --no-format) SKIP_FORMAT=true; shift ;;
            --no-push) SKIP_PUSH=true; shift ;;
            --rollback) ROLLBACK=true; shift ;;
            --) shift; break ;;
            *) log "ERROR" "Invalid option: $1"; show_help; exit 1 ;;
        esac
    done

    # Verify host argument
    if [[ $# -ne 1 ]]; then
        log "ERROR" "Host argument is required"
        show_help
        exit 1
    fi

    HOST=$1
    verify_host "$HOST"

    # Setup logging
    mkdir -p "$LOG_DIR" "$STATE_DIR" "$CACHE_DIR"
    LOG_FILE="${LOG_DIR}/nixos-rebuild-${HOST}-$(date '+%Y%m%d_%H%M%S').log"
    touch "$LOG_FILE"

    # Ask for confirmation if not forced
    if [[ $FORCE == false && $DRY_RUN == false ]]; then
        echo
        if ! gum confirm --default=false \
            --affirmative="$(gum style --foreground "${COLORS[success]}" "Yes, proceed")" \
            --negative="$(gum style --foreground "${COLORS[error]}" "No, cancel")" \
            "$(gum style --foreground "${COLORS[primary]}" "Ready to rebuild ${HOST}. Continue?")"; then
            log "INFO" "Operation cancelled by user"
            exit 0
        fi
    fi

    # Run main process
    main "$HOST"
}

# Start script execution
parse_args_and_run "$@"
