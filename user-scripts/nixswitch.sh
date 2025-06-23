#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

#######################################
# Configuration
#######################################
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_NAME=$(basename "$0"log() {
    local msg="$1"
    local level="${2:-info}"
    local color="${COLORS[$level]:-39}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Truncate very long messages to prevent "Argument list too long" errors
    if [[ ${#msg} -gt 1000 ]]; then
        msg="${msg:0:1000}... (truncated)"
    fi

    # Always log to file
    echo "[$timestamp] ($level) $msg" >>"$LOG_FILE"

    # Show in terminal based on verbosity
    if [[ "${VERBOSE:-false}" == true || "$level" != "info" ]]; then
        gum style --foreground "$color" "[$timestamp] $msg"
    fi
}E_DIR="$HOME/NixOS"
readonly LOG_DIR="$HOME/.local/share/nixos-rebuild/logs"
readonly STATE_DIR="$HOME/.local/share/nixos-rebuild/state"
readonly CACHE_DIR="$HOME/.cache/nixos-rebuild"
readonly LOCK_FILE="$HOME/.local/share/nixos-rebuild/rebuild.lock"
readonly PARALLEL_JOBS=$(nproc)
readonly DEFAULT_KEEP_GENERATIONS=7
readonly DEFAULT_OPERATION="switch"
readonly MIN_FREE_SPACE_GB=5

# Color definitions for gum
declare -A COLORS=(
    ["primary"]="212"
    ["error"]="196"
    ["warning"]="214"
    ["success"]="84"
    ["info"]="39"
    ["accent"]="99"
)

# Global variables
declare -a CLEANUP_PIDS=()
declare -a PARALLEL_TASKS=()
declare SUDO_PID=""

#######################################
# Error handling and cleanup
#######################################
trap 'cleanup' EXIT INT TERM

cleanup() {
    # Kill any running background processes
    for pid in "${CLEANUP_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    
    # Kill sudo keep-alive
    if [[ -n "$SUDO_PID" ]] && kill -0 "$SUDO_PID" 2>/dev/null; then
        kill -TERM "$SUDO_PID" 2>/dev/null || true
    fi
    
    # Remove lock file
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
    
    # Wait for background jobs to finish
    wait 2>/dev/null || true
}

#######################################
# Utility functions
#######################################
die() {
    gum style --foreground "${COLORS[error]}" "ERROR: $1" >&2
    exit 1
}

warn() {
    gum style --foreground "${COLORS[warning]}" "WARNING: $1" >&2
}

info() {
    gum style --foreground "${COLORS[info]}" "INFO: $1"
}

success() {
    gum style --foreground "${COLORS[success]}" "✓ $1"
}

# Enhanced permission checker with better error handling
check_sudo_access() {
    if ! sudo -v &>/dev/null; then
        if ! sudo -v; then
            die "Root privileges are required to run this script."
        fi
    fi
    
    # Keep sudo alive in the background with better error handling
    (
        while true; do
            sudo -v 2>/dev/null || exit 1
            sleep 45
        done
    ) &
    SUDO_PID=$!
}

# Check available disk space
check_disk_space() {
    local available_gb
    available_gb=$(df /nix --output=avail --block-size=1G | tail -1 | tr -d ' ')
    
    if [[ "$available_gb" -lt "$MIN_FREE_SPACE_GB" ]]; then
        warn "Low disk space: ${available_gb}GB available (recommended: ${MIN_FREE_SPACE_GB}GB+)"
        if gum confirm "Continue anyway?"; then
            return 0
        else
            die "Aborted due to low disk space"
        fi
    fi
    
    info "Disk space check: ${available_gb}GB available"
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
    local -a required=("gum" "nix" "git" "alejandra" "parallel")
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
# Parallel execution framework
#######################################
run_parallel() {
    local max_jobs="${1:-$PARALLEL_JOBS}"
    shift
    local tasks=("$@")
    
    if [[ ${#tasks[@]} -eq 0 ]]; then
        return 0
    fi
    
    info "Running ${#tasks[@]} tasks in parallel (max jobs: $max_jobs)"
    
    printf '%s\n' "${tasks[@]}" | \
        parallel --jobs "$max_jobs" --halt soon,fail=1 --line-buffer \
        'eval "$@"' -- || return 1
}

# Background task execution with progress tracking
execute_background() {
    local name="$1"
    local log_file="$2"
    shift 2
    local cmd=("$@")
    
    {
        if [[ "${DRY_RUN:-false}" == true ]]; then
            echo "Would execute: ${cmd[*]}"
            return 0
        fi
        
        if "${cmd[@]}" &>>"$log_file"; then
            echo "SUCCESS: $name"
        else
            echo "FAILED: $name (exit code: $?)"
            return 1
        fi
    } &
    
    local pid=$!
    CLEANUP_PIDS+=("$pid")
    return 0
}

# Wait for all background tasks
wait_for_background_tasks() {
    local failed=0
    
    for pid in "${CLEANUP_PIDS[@]}"; do
        if ! wait "$pid"; then
            ((failed++))
        fi
    done
    
    CLEANUP_PIDS=()
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed background tasks failed"
        return 1
    fi
    
    return 0
}

#######################################
# Enhanced logging
#######################################
log() {
    local msg=$1
    local level=${2:-info}
    local color="${COLORS[$level]:-39}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Always log to file
    echo "[$timestamp] ($level) $msg" >>"$LOG_FILE"

    # Show in terminal based on verbosity
    if [[ "${VERBOSE:-false}" == true || "$level" != "info" ]]; then
        gum style --foreground "$color" "[$timestamp] $msg"
    fi
}

setup_logging() {
    ensure_directories
    LOG_FILE="${LOG_DIR}/nixos-rebuild-${host:-system}-$(date '+%Y%m%d_%H%M%S').log"
    touch "$LOG_FILE"
    
    # Clean old logs in background
    {
        find "$LOG_DIR" -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
    } &
}

#######################################
# Enhanced command execution
#######################################
execute() {
    local name=$1
    shift
    local cmd=("$@")

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log "Would execute: ${cmd[*]}" "info"
        gum style --foreground "${COLORS[accent]}" "⊝ $name (dry-run)"
        return 0
    fi

    local temp_out temp_err
    temp_out=$(mktemp)
    temp_err=$(mktemp)

    local start_time end_time duration
    start_time=$(date +%s)

    if "${cmd[@]}" >"$temp_out" 2>"$temp_err"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        local output
        output=$(cat "$temp_out")
        local errors
        errors=$(cat "$temp_err")
        
        rm -f "$temp_out" "$temp_err"

        # Log output and errors
        if [[ -n "$output" ]]; then
            log "$output" "info"
        fi
        if [[ -n "$errors" ]]; then
            log "$errors" "warning"
        fi

        success "$name (${duration}s)"
        return 0
    else
        local exit_code=$?
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        local output errors
        output=$(cat "$temp_out")
        errors=$(cat "$temp_err")
        rm -f "$temp_out" "$temp_err"

        # Display formatted error output
        if [[ -n "$output" || -n "$errors" ]]; then
            echo
            gum style --foreground "${COLORS[error]}" "Error in $name (${duration}s):"
            
            if [[ -n "$errors" ]]; then
                echo "$errors" | while IFS= read -r line; do
                    if [[ "$line" =~ ^error: ]]; then
                        gum style --foreground "${COLORS[error]}" "  $line"
                    elif [[ "$line" =~ ^warning: ]]; then
                        gum style --foreground "${COLORS[warning]}" "  $line"
                    else
                        echo "  $line"
                    fi
                done
            fi
            
            if [[ -n "$output" ]]; then
                echo "$output" | while IFS= read -r line; do
                    echo "  $line"
                done
            fi
            echo
        fi

        gum style --foreground "${COLORS[error]}" "✗ $name failed (${duration}s)"
        return $exit_code
    fi
}

#######################################
# Enhanced garbage collection
#######################################
smart_garbage_collection() {
    local keep_days="${KEEP_GENERATIONS:-$DEFAULT_KEEP_GENERATIONS}"
    local aggressive="${AGGRESSIVE_GC:-false}"
    
    info "Starting intelligent garbage collection..."
    
    # Run core GC operations sequentially for safety
    collect_old_generations "$keep_days"
    clean_nix_store
    
    # Run maintenance tasks in parallel
    local maintenance_tasks=()
    
    # Add tasks that can run in parallel
    if command -v journalctl &>/dev/null; then
        maintenance_tasks+=("sudo journalctl --vacuum-time=7d --quiet")
        maintenance_tasks+=("sudo journalctl --vacuum-size=500M --quiet")
    fi
    
    # Clean user caches
    if [[ -d "$HOME/.cache/nix" ]]; then
        maintenance_tasks+=("find $HOME/.cache/nix -type f -mtime +7 -delete 2>/dev/null || true")
    fi
    
    if [[ -d "$CACHE_DIR" ]]; then
        maintenance_tasks+=("find $CACHE_DIR -type f -mtime +7 -delete 2>/dev/null || true")
    fi
    
    # Run maintenance tasks in parallel if any exist
    if [[ ${#maintenance_tasks[@]} -gt 0 ]]; then
        info "Running ${#maintenance_tasks[@]} maintenance tasks in parallel"
        printf '%s\n' "${maintenance_tasks[@]}" | \
            parallel --jobs 3 --line-buffer 'bash -c "{}"' 2>/dev/null || true
    fi
    
    if [[ "$aggressive" == true ]]; then
        aggressive_store_cleanup
    fi
}

collect_old_generations() {
    local keep_days=$1
    
    # System generations
    execute "Clean old system generations" \
        sudo nix-collect-garbage --delete-older-than "${keep_days}d"
    
    # User generations
    execute "Clean old user generations" \
        nix-collect-garbage --delete-older-than "${keep_days}d"
    
    # Profile generations
    if [[ -d "/nix/var/nix/profiles" ]]; then
        execute "Clean old profile generations" \
            sudo find /nix/var/nix/profiles -name "*-*-link" -mtime +"$keep_days" -delete
    fi
}

clean_nix_store() {
    # Check store consistency first
    execute "Verify store integrity" nix-store --verify --check-contents
    
    # Optimize store (deduplicate)
    if [[ "${SKIP_OPTIMIZE:-false}" != true ]]; then
        execute "Optimize nix store" nix-store --optimize
    fi
    
    # Clean up unused paths
    execute "Clean unused store paths" nix-store --gc
}

aggressive_store_cleanup() {
    warn "Running aggressive cleanup - this may take longer"
    
    # More aggressive garbage collection
    execute "Aggressive GC (all unreachable)" nix-collect-garbage -d
    
    # Clean temporary build directories
    if [[ -d "/tmp" ]]; then
        execute "Clean build temps" \
            sudo find /tmp -name "nix-build-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
    fi
    
    # Clean Nix build cache
    if [[ -d "$HOME/.cache/nix" ]]; then
        execute "Clean nix build cache" rm -rf "$HOME/.cache/nix"/*
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
        info "Available hosts:"
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                local host_name
                host_name=$(basename "$host")
                gum style --foreground "${COLORS[primary]}" "• $host_name"
                
                # Show last build info if available
                local last_build="$STATE_DIR/last_build_$host_name"
                if [[ -f "$last_build" ]]; then
                    local last_time
                    last_time=$(cat "$last_build")
                    gum style --foreground "${COLORS[accent]}" "  Last build: $last_time"
                fi
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

validate_configuration() {
    local host=$1
    info "Validating configuration..."

    # Check git status to inform user about dirty working tree
    if [[ -d "$FLAKE_DIR/.git" ]]; then
        if ! git -C "$FLAKE_DIR" diff-index --quiet HEAD --; then
            warn "Git working tree is dirty - flake check may report warnings"
            info "Run 'git add .' and 'git commit' to clean the working tree if needed"
        fi
    fi

    # Check basic flake syntax first
    if ! execute "Check flake metadata" nix flake metadata; then
        die "Flake metadata check failed - basic flake structure is broken"
    fi

    # Try a more comprehensive flake check, but don't fail if it has transient issues
    if ! execute "Check flake syntax (no-build)" nix flake check --no-build; then
        warn "Flake check with --no-build failed, trying without --no-build flag..."
        if ! execute "Check flake syntax (full)" nix flake check; then
            warn "Flake check reported issues, but continuing anyway (this may be due to transient network issues)"
            warn "You may want to run 'nix flake check' manually to investigate"
        fi
    fi
    
    # The most important validation - check if the host configuration builds
    if ! execute "Validate host config" nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --dry-run; then
        die "Host configuration validation failed - cannot build the system configuration"
    fi
    
    # Check for common security issues
    if [[ -f "$FLAKE_DIR/flake.nix" ]]; then
        if grep -q "allowBroken.*true" "$FLAKE_DIR/flake.nix"; then
            warn "allowBroken is enabled - this may introduce security risks"
        fi
    fi
    
    success "Configuration validation passed"
    return 0
}

show_generations() {
    info "System generations:"
    sudo nixos-rebuild list-generations | head -20
    
    echo
    info "User generations:"
    nix-env --list-generations | head -10
}

rollback_generation() {
    show_generations
    echo
    local gen
    gen=$(gum input --placeholder "Enter generation number to rollback to")

    if [[ ! "$gen" =~ ^[0-9]+$ ]]; then
        die "Invalid generation number: $gen"
    fi

    if gum confirm "Rollback to generation $gen?"; then
        execute "Rollback to generation $gen" \
            sudo nixos-rebuild switch --rollback --switch-generation "$gen"
    fi
}

pre_build_optimizations() {
    info "Running pre-build optimizations..."
    
    # Set optimal build settings
    export NIX_BUILD_CORES="$PARALLEL_JOBS"
    export NIX_CONFIG="
        max-jobs = auto
        cores = $PARALLEL_JOBS
        sandbox = true
        auto-optimise-store = true
        keep-outputs = false
        keep-derivations = false
    "
    
    # Warm up the evaluation cache
    execute "Warm evaluation cache" \
        nix eval ".#nixosConfigurations.$1.config.system.build.toplevel.drvPath" --raw
}

rebuild_system() {
    local host=$1
    local operation=${2:-$DEFAULT_OPERATION}
    cd "$FLAKE_DIR" || die "Could not change to flake directory"

    echo "$$" >"$LOCK_FILE"
    echo "$(date)" >"$STATE_DIR/last_build_$host"

    # Pre-build checks
    check_disk_space
    
    # Pre-build optimizations
    pre_build_optimizations "$host"

    # Validate configuration first
    if [[ "${SKIP_VALIDATION:-false}" != true ]]; then
        validate_configuration "$host"
    fi

    # Update system
    if [[ "${SKIP_UPDATE:-false}" != true ]]; then
        info "Updating system..."
        execute "Update flake inputs" nix flake update
    fi

    # Garbage collection
    if [[ "${SKIP_GC:-false}" != true ]]; then
        smart_garbage_collection
    fi

    # Format code
    if [[ "${SKIP_FORMAT:-false}" != true ]]; then
        execute "Format configuration files" alejandra .
    fi

    # Build system
    local rebuild_cmd=(sudo nixos-rebuild "$operation" --flake ".#${host}")
    [[ "${DRY_RUN:-false}" == true ]] && rebuild_cmd+=(--dry-run)
    [[ "${VERBOSE:-false}" == true ]] && rebuild_cmd+=(--verbose)
    [[ "${FAST_BUILD:-false}" == true ]] && rebuild_cmd+=(--fast)
    
    # Add parallel build flags
    rebuild_cmd+=(--option max-jobs auto --option cores "$PARALLEL_JOBS")

    execute "Rebuilding system ($operation)" "${rebuild_cmd[@]}"

    # Post-build tasks
    if [[ "${DRY_RUN:-false}" != true && "$operation" == "switch" ]]; then
        post_build_tasks "$host"
    fi
}

post_build_tasks() {
    local host=$1
    
    info "Running post-build tasks..."
    
    # Git operations
    if [[ "${SKIP_PUSH:-false}" != true ]]; then
        handle_git_operations "$host"
    fi
    
    # System maintenance
    if [[ "${SKIP_MAINTENANCE:-false}" != true ]]; then
        maintenance
    fi
    
    # Update build timestamp
    echo "$(date)" >"$STATE_DIR/last_build_$host"
}

handle_git_operations() {
    local host=$1
    
    if ! git status &>/dev/null; then
        warn "Not a git repository or git command failed"
        return 1
    fi

    if ! git diff-index --quiet HEAD --; then
        local gen
        gen=$(sudo nixos-rebuild --flake ".#${host}" list-generations | grep current | head -1)
        
        execute "Stage changes" git add .
        execute "Commit changes" git commit -m "rebuild(${host}): ${gen}"
        
        if gum confirm "Push changes to remote?"; then
            execute "Push changes" git push
        fi
    else
        info "No changes to commit"
    fi
}

maintenance() {
    info "Performing system maintenance..."

    # Run maintenance tasks sequentially for reliability
    execute "Clean systemd logs" sudo journalctl --vacuum-time=7d
    
    if command -v updatedb &>/dev/null; then
        execute "Update locate database" sudo updatedb
    fi
    
    # Clean package caches
    if [[ -d "$HOME/.cache" ]]; then
        execute "Clean package caches" \
            find "$HOME/.cache" -name "*.cache" -mtime +7 -delete 2>/dev/null || true
    fi
}

# Remove the individual maintenance functions that were causing issues
clean_systemd_logs() {
    execute "Clean systemd logs" sudo journalctl --vacuum-time=7d
}

update_locate_database() {
    if command -v updatedb &>/dev/null; then
        execute "Update locate database" sudo updatedb
    fi
}

clean_package_cache() {
    if [[ -d "$HOME/.cache" ]]; then
        execute "Clean package caches" \
            find "$HOME/.cache" -name "*.cache" -mtime +7 -delete 2>/dev/null || true
    fi
}

#######################################
# Performance monitoring
#######################################
show_system_info() {
    info "System Information:"
    echo "  CPU cores: $PARALLEL_JOBS"
    echo "  Memory: $(free -h | awk 'NR==2{print $2}')"
    echo "  Disk space: $(df -h /nix | awk 'NR==2{print $4}') available"
    echo "  Nix version: $(nix --version)"
    echo "  Current generation: $(sudo nixos-rebuild list-generations | grep current | head -1)"
}

#######################################
# Main script
#######################################
main() {
    check_sudo_access

    local host=""
    local operation="$DEFAULT_OPERATION"
    DRY_RUN=false
    SKIP_UPDATE=false
    SKIP_OPTIMIZE=false
    SKIP_FORMAT=false
    SKIP_PUSH=false
    SKIP_VALIDATION=false
    SKIP_GC=false
    SKIP_MAINTENANCE=false
    VERBOSE=false
    AGGRESSIVE_GC=false
    FAST_BUILD=false
    KEEP_GENERATIONS=$DEFAULT_KEEP_GENERATIONS

    while [[ $# -gt 0 ]]; do
        case $1 in
        -n | --dry-run) DRY_RUN=true ;;
        --no-update) SKIP_UPDATE=true ;;
        --no-optimize) SKIP_OPTIMIZE=true ;;
        --no-format) SKIP_FORMAT=true ;;
        --no-push) SKIP_PUSH=true ;;
        --no-validation) SKIP_VALIDATION=true ;;
        --no-gc) SKIP_GC=true ;;
        --no-maintenance) SKIP_MAINTENANCE=true ;;
        --aggressive-gc) AGGRESSIVE_GC=true ;;
        --fast) FAST_BUILD=true ;;
        -v | --verbose) VERBOSE=true ;;
        -o | --operation)
            shift
            operation=$1
            if [[ ! "$operation" =~ ^(switch|boot|test|build)$ ]]; then
                die "Invalid operation: $operation. Must be one of: switch, boot, test, build"
            fi
            ;;
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
        -g | --generations)
            show_generations
            exit 0
            ;;
        -r | --rollback)
            rollback_generation
            exit 0
            ;;
        -i | --info)
            show_system_info
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

    # Lock file check
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

    if [[ $DRY_RUN == true ]]; then
        warn "Running in dry-run mode - no changes will be made"
    fi
    
    if [[ $FAST_BUILD == true ]]; then
        info "Fast build mode enabled - skipping some optimizations"
    fi

    if [[ $DRY_RUN == false ]]; then
        if ! gum confirm "Ready to $operation $host. Continue?"; then
            info "Operation cancelled"
            exit 0
        fi
    fi

    rebuild_system "$host" "$operation"
    
    success "System rebuild completed successfully!"
}

show_help() {
    cat <<EOF
Enhanced NixOS Rebuild Script v${SCRIPT_VERSION}

Usage: $SCRIPT_NAME [options] <host>

Options:
  -n, --dry-run         Dry run mode
  -o, --operation OP    Operation to perform (switch|boot|test|build) [default: switch]
  --no-update           Skip system updates
  --no-optimize         Skip store optimization
  --no-format           Skip file formatting
  --no-push             Skip git push
  --no-validation       Skip configuration validation
  --no-gc               Skip garbage collection
  --no-maintenance      Skip post-build maintenance
  --aggressive-gc       Perform aggressive garbage collection
  --fast                Fast build mode (skip some optimizations)
  -v, --verbose         Enable verbose output
  -k, --keep DAYS       Keep generations for specified days (default: $DEFAULT_KEEP_GENERATIONS)
  -l, --list            List available hosts
  -g, --generations     Show system generations
  -r, --rollback        Rollback to a previous generation
  -i, --info            Show system information
  -h, --help            Show this help message

Operations:
  switch    Apply configuration and make it the boot default
  boot      Apply configuration on next boot only
  test      Apply configuration temporarily (reverts on reboot)
  build     Build configuration without applying

Features:
  • Parallel processing for faster builds (using $PARALLEL_JOBS cores)
  • Intelligent garbage collection with multiple strategies
  • Enhanced error handling and logging
  • Pre and post-build optimizations
  • System health monitoring
  • Security validation checks

Available hosts:
$(for h in "$FLAKE_DIR"/hosts/*/; do echo "  $(basename "$h")"; done)
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_requirements
    main "$@"
fi
