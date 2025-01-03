#!/usr/bin/env bash

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Script meta information
readonly SCRIPT_VERSION="2.1.0"
readonly SCRIPT_NAME=$(basename "$0")

# Configuration
readonly FLAKE_DIR="$HOME/NixOS"
readonly LOG_DIR="$HOME/.local/share/nixos-rebuild/logs"
readonly STATE_DIR="$HOME/.local/share/nixos-rebuild/state"
readonly CACHE_DIR="$HOME/.cache/nixos-rebuild"

# Format duration in a human-readable way
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local remaining_seconds=$((seconds % 60))

    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $remaining_seconds
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $remaining_seconds
    else
        printf "%ds" $remaining_seconds
    fi
}

# Format timestamp for display
format_timestamp() {
    date '+%H:%M:%S'
}

# Format log message with consistent spacing
format_log_message() {
    local level=$1
    local duration=$2
    local message=$3
    local timestamp=$(format_timestamp)
    local duration_str=""

    if [[ -n "$duration" ]]; then
        duration_str=" ($(format_duration "$duration"))"
    fi

    printf "%-8s %-7s %-50s%s\n" "[$timestamp]" "[$level]" "$message" "$duration_str"
}

# Enhanced progress tracking
declare -A operation_times
track_operation() {
    local operation=$1
    operation_times[$operation]=$(date +%s)
}

end_operation() {
    local operation=$1
    local end_time=$(date +%s)
    local start_time=${operation_times[$operation]}
    local duration=$((end_time - start_time))
    echo $duration
}

# Function to list available hosts
list_available_hosts() {
    local hosts_dir="$FLAKE_DIR/hosts"
    if [[ -d "$hosts_dir" ]]; then
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                basename "$host"
            fi
        done
    fi
}

# Function to verify if a host exists
verify_host() {
    local host=$1
    if [[ ! -d "$FLAKE_DIR/hosts/$host" ]]; then
        format_log_message "ERROR" "" "Host '$host' not found in $FLAKE_DIR/hosts/"
        echo "Available hosts:"
        list_available_hosts | sed 's/^/  /'
        exit 1
    fi
}

# Usage information
usage() {
    cat <<EOF
${BOLD}NixOS Rebuild Script v${SCRIPT_VERSION}${RESET}

${BOLD}Usage:${RESET}
    $SCRIPT_NAME [OPTIONS] <host>

${BOLD}Options:${RESET}
    -h, --help              Show this help message
    -v, --version           Show script version
    -d, --debug            Enable debug mode
    -n, --dry-run          Perform a dry run without making changes
    -f, --force            Skip all confirmation prompts
    -l, --log-level LEVEL  Set log level (DEBUG|INFO|WARN|ERROR)
    -k, --keep GENS        Number of generations to keep (default: 5)
    --no-update            Skip flake updates
    --no-optimize          Skip store optimization
    --no-format           Skip nix file formatting
    --no-push             Skip git push
    --rollback            Rollback to the previous generation

${BOLD}Available Hosts:${RESET}
$(list_available_hosts | sed 's/^/    /')

${BOLD}Environment Variables:${RESET}
    LOG_LEVEL     Set logging level (default: INFO)
    NIXOS_DEBUG   Enable extra debugging (1=enabled)
EOF
}

# Enhanced execution handling with timing and formatting
execute() {
    local cmd_name=$1
    shift
    local cmd=("$@")

    track_operation "$cmd_name"

    # Create a unique temp file for this operation
    local temp_log="${CACHE_DIR}/temp_${RANDOM}.log"
    mkdir -p "$(dirname "$temp_log")"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        format_log_message "DRY-RUN" "" "Would execute: ${cmd[*]}"
        return 0
    fi

    # Execute with progress indication
    if gum spin --spinner dot --title "$(format_timestamp) Running $cmd_name..." -- \
        "${cmd[@]}" > "$temp_log" 2>&1; then
        local duration=$(end_operation "$cmd_name")
        format_log_message "SUCCESS" "$duration" "$cmd_name completed"
        cat "$temp_log" >> "$LOG_FILE"
    else
        local exit_code=$?
        format_log_message "ERROR" "" "$cmd_name failed with exit code $exit_code"
        echo "Last 50 lines of output:"
        tail -n 50 "$temp_log" | sed 's/^/    /'
        cat "$temp_log" >> "$LOG_FILE"
        rm -f "$temp_log"
        return $exit_code
    fi
    rm -f "$temp_log"
}

# Pretty print section headers
print_section() {
    local title=$1
    gum style \
        --border double \
        --align center \
        --width 60 \
        --margin "1 2" \
        --padding "1 2" \
        "$title"
}

# Main rebuild process with timing
main() {
    local host=$1
    local start_time=$(date +%s)

    # Print initial banner
    print_section "NixOS Rebuild v${SCRIPT_VERSION}\nHost: ${host}\nMode: $(if [[ $DRY_RUN == true ]]; then echo "Dry Run"; else echo "Normal"; fi)"

    cd "$FLAKE_DIR"

    # Handle rollback if requested
    if [[ $ROLLBACK == true ]]; then
        print_section "Rolling Back System"
        execute "Rollback" sudo nixos-rebuild rollback --flake ".#${host}"
        return $?
    fi

    # Update phase
    if [[ $SKIP_UPDATE == false ]]; then
        print_section "Update Phase"
        execute "Update Channels" sudo nix-channel --update
        execute "Update Flake" nix flake update
    fi

    # Cleanup phase
    print_section "Cleanup Phase"
    execute "Garbage Collection" sudo nix-collect-garbage --delete-older-than "${KEEP_GENERATIONS}d"

    if [[ $SKIP_OPTIMIZE == false ]]; then
        execute "Store Optimization" sudo nix-store --optimize
    fi

    # Format phase
    if [[ $SKIP_FORMAT == false ]]; then
        print_section "Format Phase"
        execute "Format Files" alejandra .
    fi

    # Build phase
    print_section "Build Phase"
    rebuild_cmd=(sudo nixos-rebuild switch --flake ".#${host}")
    if [[ $DRY_RUN == true ]]; then
        rebuild_cmd+=(--dry-run)
    fi

    if ! execute "NixOS Rebuild" "${rebuild_cmd[@]}"; then
        format_log_message "ERROR" "" "Build failed! Check the logs at $LOG_FILE"
        return 1
    fi

    execute "Boot Cleanup" sudo /run/current-system/bin/switch-to-configuration boot

    # Commit phase
    if [[ $DRY_RUN == false ]]; then
        print_section "Commit Phase"
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
    print_section "🎉 NixOS Update Complete! 🎉\n\nHost: ${host}\nTotal Time: $(format_duration $total_duration)\nLog: ${LOG_FILE}"

    format_log_message "INFO" "" "System update complete! You may need to restart for all changes to take effect."
}

# Parse command line arguments and call main
parse_args_and_run() {
    TEMP=$(getopt -o hvdnfl:k: --long help,version,debug,dry-run,force,log-level:,keep:,no-update,no-optimize,no-format,no-push,rollback -n "$SCRIPT_NAME" -- "$@")
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
    LOG_LEVEL=${LOG_LEVEL:-INFO}

    # Parse options
    while true; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--version) echo "$SCRIPT_NAME version $SCRIPT_VERSION"; exit 0 ;;
            -d|--debug) LOG_LEVEL=DEBUG; set -x; shift ;;
            -n|--dry-run) DRY_RUN=true; shift ;;
            -f|--force) FORCE=true; shift ;;
            -l|--log-level) LOG_LEVEL=$2; shift 2 ;;
            -k|--keep) KEEP_GENERATIONS=$2; shift 2 ;;
            --no-update) SKIP_UPDATE=true; shift ;;
            --no-optimize) SKIP_OPTIMIZE=true; shift ;;
            --no-format) SKIP_FORMAT=true; shift ;;
            --no-push) SKIP_PUSH=true; shift ;;
            --rollback) ROLLBACK=true; shift ;;
            --) shift; break ;;
            *) format_log_message "ERROR" "" "Invalid option: $1"; usage; exit 1 ;;
        esac
    done

    # Verify host argument
    if [[ $# -ne 1 ]]; then
        format_log_message "ERROR" "" "Host argument is required"
        usage
        exit 1
    fi

    HOST=$1
    verify_host "$HOST"

    # Setup logging
    mkdir -p "$LOG_DIR" "$STATE_DIR" "$CACHE_DIR"
    LOG_FILE="${LOG_DIR}/nixos-rebuild-${HOST}-$(date '+%Y%m%d_%H%M%S').log"
    touch "$LOG_FILE"

    # Run main process
    main "$HOST"
}

# Start script execution
parse_args_and_run "$@"
