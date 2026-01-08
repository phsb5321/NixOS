#!/usr/bin/env bash
# playwright-docker.sh
# Docker fallback for running Playwright tests when Nix-native execution fails
# Uses official Microsoft Playwright Docker images
#
# Usage: playwright-docker.sh [test|shell|run|pull|version] [args...]

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"
PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-v1.57.0}"
PLAYWRIGHT_IMAGE="mcr.microsoft.com/playwright:${PLAYWRIGHT_VERSION}-noble"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
Playwright Docker Fallback v${VERSION}

Usage: ${SCRIPT_NAME} <command> [args...]

Commands:
    test [args]     Run 'npx playwright test' inside Docker container
    shell           Open interactive shell in Playwright container
    run <cmd>       Run arbitrary command in Playwright container
    pull            Pull the latest Playwright Docker image
    version         Show Playwright image version

Options:
    --help, -h      Show this help message
    --image <tag>   Use specific Playwright image tag

Environment Variables:
    PLAYWRIGHT_VERSION  Docker image version (default: v1.57.0)

Docker Flags Used:
    --ipc=host      Required for Chromium memory management
    --init          Proper signal handling, prevents zombie processes
    -v \$(pwd):/work  Mount current directory as /work

Examples:
    ${SCRIPT_NAME} test                    # Run all Playwright tests
    ${SCRIPT_NAME} test --project=firefox  # Run Firefox tests only
    ${SCRIPT_NAME} test --headed           # Run with visible browser (needs X11)
    ${SCRIPT_NAME} shell                   # Interactive debugging
    ${SCRIPT_NAME} run npx playwright show-report

Notes:
    - Use 'hostmachine' instead of 'localhost' to access host services
    - Firefox and WebKit work reliably in Docker (unlike Nix-native)
    - Current directory is mounted as /work in the container
EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}" >&2
        echo "" >&2
        echo "Docker is required for the Playwright fallback." >&2
        echo "Install Docker with one of these methods:" >&2
        echo "" >&2
        echo "  NixOS: Add to configuration.nix:" >&2
        echo "    virtualisation.docker.enable = true;" >&2
        echo "" >&2
        echo "  Then rebuild: sudo nixos-rebuild switch" >&2
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}" >&2
        echo "" >&2
        echo "Start the Docker service:" >&2
        echo "  sudo systemctl start docker" >&2
        exit 1
    fi
}

# Build common docker run arguments
get_docker_args() {
    local args=(
        "--rm"
        "--ipc=host"
        "--init"
        "-v" "$(pwd):/work"
        "-w" "/work"
        "--add-host=hostmachine:host-gateway"
    )
    
    # Pass through environment variables if set
    if [ -n "${CI:-}" ]; then
        args+=("-e" "CI=${CI}")
    fi
    
    # Add TTY if interactive
    if [ -t 0 ] && [ -t 1 ]; then
        args+=("-it")
    fi
    
    echo "${args[@]}"
}

cmd_test() {
    check_docker
    echo -e "${BLUE}Running Playwright tests in Docker...${NC}"
    echo "Image: ${PLAYWRIGHT_IMAGE}"
    echo "Working directory: $(pwd)"
    echo ""
    
    local docker_args
    docker_args=$(get_docker_args)
    
    # shellcheck disable=SC2086
    docker run ${docker_args} \
        "${PLAYWRIGHT_IMAGE}" \
        npx playwright test "$@"
}

cmd_shell() {
    check_docker
    echo -e "${BLUE}Opening interactive shell in Playwright container...${NC}"
    echo "Image: ${PLAYWRIGHT_IMAGE}"
    echo "Working directory mounted as /work"
    echo ""
    echo "Tips:"
    echo "  - Access host services via 'hostmachine' instead of 'localhost'"
    echo "  - Run 'npx playwright test' to execute tests"
    echo "  - Exit with 'exit' or Ctrl+D"
    echo ""
    
    local docker_args
    docker_args=$(get_docker_args)
    
    # shellcheck disable=SC2086
    docker run ${docker_args} \
        "${PLAYWRIGHT_IMAGE}" \
        /bin/bash
}

cmd_run() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: No command specified${NC}" >&2
        echo "Usage: ${SCRIPT_NAME} run <command> [args...]" >&2
        exit 1
    fi
    
    check_docker
    echo -e "${BLUE}Running command in Playwright container...${NC}"
    
    local docker_args
    docker_args=$(get_docker_args)
    
    # shellcheck disable=SC2086
    docker run ${docker_args} \
        "${PLAYWRIGHT_IMAGE}" \
        "$@"
}

cmd_pull() {
    check_docker
    echo -e "${BLUE}Pulling Playwright Docker image...${NC}"
    echo "Image: ${PLAYWRIGHT_IMAGE}"
    echo ""
    
    docker pull "${PLAYWRIGHT_IMAGE}"
    
    echo ""
    echo -e "${GREEN}Image pulled successfully!${NC}"
}

cmd_version() {
    echo "Playwright Docker Fallback v${VERSION}"
    echo "Default image: ${PLAYWRIGHT_IMAGE}"
    echo ""
    
    if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        echo "Checking for local image..."
        if docker image inspect "${PLAYWRIGHT_IMAGE}" &> /dev/null; then
            echo -e "${GREEN}Image available locally${NC}"
            docker image inspect "${PLAYWRIGHT_IMAGE}" --format '{{.RepoTags}} - Created: {{.Created}}'
        else
            echo -e "${YELLOW}Image not pulled yet. Run '${SCRIPT_NAME} pull' to download.${NC}"
        fi
    else
        echo -e "${YELLOW}Docker not available - cannot check local image${NC}"
    fi
}

# Main entry point
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        test)
            cmd_test "$@"
            ;;
        shell)
            cmd_shell
            ;;
        run)
            cmd_run "$@"
            ;;
        pull)
            cmd_pull
            ;;
        version)
            cmd_version
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown command: ${command}${NC}" >&2
            echo "Run '${SCRIPT_NAME} --help' for usage information." >&2
            exit 1
            ;;
    esac
}

main "$@"
