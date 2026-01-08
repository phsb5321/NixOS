#!/usr/bin/env bash
# playwright-server-docker.sh
# Run Playwright Server in Docker for remote browser connections
# Allows running tests on host while browsers execute in container
#
# Usage: playwright-server-docker.sh [start|stop|status|logs|restart]

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"
PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-v1.57.0}"
PLAYWRIGHT_IMAGE="mcr.microsoft.com/playwright:${PLAYWRIGHT_VERSION}-noble"
CONTAINER_NAME="playwright-server"
DEFAULT_PORT="${PW_SERVER_PORT:-3000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
Playwright Server Docker v${VERSION}

Usage: ${SCRIPT_NAME} <command> [options]

Commands:
    start [--port N]    Start Playwright Server on specified port (default: ${DEFAULT_PORT})
    stop                Stop the running Playwright Server container
    status              Check if Playwright Server is running
    logs                Show container logs
    restart             Restart the Playwright Server

Options:
    --help, -h          Show this help message
    --port <N>          Port to expose (default: ${DEFAULT_PORT})

Environment Variables:
    PLAYWRIGHT_VERSION  Docker image version (default: v1.57.0)
    PW_SERVER_PORT      Default port (default: 3000)

Usage with Playwright Tests:
    # Start the server
    ${SCRIPT_NAME} start

    # Run tests connecting to the server
    PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:${DEFAULT_PORT}/ npx playwright test

    # Stop the server when done
    ${SCRIPT_NAME} stop

Notes:
    - Server runs in background (detached mode)
    - Use 'host.docker.internal' for localhost access from container
    - All browsers (Chromium, Firefox, WebKit) available via server
    - Server persists until explicitly stopped
EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}" >&2
        echo "" >&2
        echo "Docker is required for Playwright Server." >&2
        echo "Install Docker by adding to configuration.nix:" >&2
        echo "  virtualisation.docker.enable = true;" >&2
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}" >&2
        echo "Start with: sudo systemctl start docker" >&2
        exit 1
    fi
}

is_running() {
    docker ps --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

get_container_port() {
    docker port "${CONTAINER_NAME}" 3000 2>/dev/null | cut -d: -f2 || echo ""
}

cmd_start() {
    local port="${DEFAULT_PORT}"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port)
                port="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}" >&2
                exit 1
                ;;
        esac
    done
    
    check_docker
    
    if is_running; then
        local current_port
        current_port=$(get_container_port)
        echo -e "${YELLOW}Playwright Server is already running on port ${current_port}${NC}"
        echo ""
        echo "To connect from tests:"
        echo "  PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:${current_port}/ npx playwright test"
        echo ""
        echo "To restart: ${SCRIPT_NAME} restart"
        return 0
    fi
    
    echo -e "${BLUE}Starting Playwright Server...${NC}"
    echo "Image: ${PLAYWRIGHT_IMAGE}"
    echo "Port: ${port}"
    echo ""
    
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --rm \
        --init \
        -p "${port}:3000" \
        --add-host=host.docker.internal:host-gateway \
        --workdir /home/pwuser \
        --user pwuser \
        "${PLAYWRIGHT_IMAGE}" \
        /bin/sh -c "npx -y playwright@${PLAYWRIGHT_VERSION#v} run-server --port 3000 --host 0.0.0.0"
    
    # Wait for server to be ready
    echo "Waiting for server to start..."
    local retries=30
    while [ $retries -gt 0 ]; do
        if curl -s "http://127.0.0.1:${port}/" &>/dev/null; then
            break
        fi
        sleep 0.5
        retries=$((retries - 1))
    done
    
    if is_running; then
        echo ""
        echo -e "${GREEN}Playwright Server is running!${NC}"
        echo ""
        echo "Connect from your tests with:"
        echo "  PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:${port}/ npx playwright test"
        echo ""
        echo "Or set the environment variable:"
        echo "  export PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:${port}/"
        echo ""
        echo "Stop the server with: ${SCRIPT_NAME} stop"
    else
        echo -e "${RED}Failed to start Playwright Server${NC}" >&2
        echo "Check logs with: ${SCRIPT_NAME} logs" >&2
        exit 1
    fi
}

cmd_stop() {
    check_docker
    
    if ! is_running; then
        echo -e "${YELLOW}Playwright Server is not running${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Stopping Playwright Server...${NC}"
    docker stop "${CONTAINER_NAME}" &>/dev/null || true
    
    echo -e "${GREEN}Playwright Server stopped${NC}"
}

cmd_status() {
    check_docker
    
    if is_running; then
        local port
        port=$(get_container_port)
        echo -e "${GREEN}Playwright Server is running${NC}"
        echo ""
        echo "Container: ${CONTAINER_NAME}"
        echo "Port: ${port}"
        echo "WebSocket URL: ws://127.0.0.1:${port}/"
        echo ""
        echo "To connect from tests:"
        echo "  PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:${port}/ npx playwright test"
    else
        echo -e "${YELLOW}Playwright Server is not running${NC}"
        echo ""
        echo "Start with: ${SCRIPT_NAME} start"
    fi
}

cmd_logs() {
    check_docker
    
    if ! docker ps -a --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}No Playwright Server container found${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Playwright Server logs:${NC}"
    echo ""
    docker logs "${CONTAINER_NAME}" 2>&1
}

cmd_restart() {
    cmd_stop
    sleep 1
    cmd_start "$@"
}

# Main entry point
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        start)
            cmd_start "$@"
            ;;
        stop)
            cmd_stop
            ;;
        status)
            cmd_status
            ;;
        logs)
            cmd_logs
            ;;
        restart)
            cmd_restart "$@"
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
