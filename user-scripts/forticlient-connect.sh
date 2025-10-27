#!/usr/bin/env bash

# FortiClient VPN Connection Script
# This script provides an easy interface for connecting to FortiVPN

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="/etc/openfortivpn/config"
USER_CONFIG_FILE="$HOME/.config/forticlient/config"

# Functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     FortiClient VPN Connection       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_vpn_status() {
    if pgrep -x "openfortivpn" > /dev/null; then
        return 0
    else
        return 1
    fi
}

connect_vpn() {
    if check_vpn_status; then
        print_warning "VPN is already connected"
        return 0
    fi

    print_status "Connecting to FortiVPN..."

    # Check if user config exists, otherwise use system config
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        CONFIG_TO_USE="$USER_CONFIG_FILE"
        print_status "Using user configuration"
    elif [[ -f "$CONFIG_FILE" ]]; then
        CONFIG_TO_USE="$CONFIG_FILE"
        print_status "Using system configuration"
    else
        print_error "No configuration file found!"
        echo "Please create a configuration file at:"
        echo "  System: $CONFIG_FILE"
        echo "  User: $USER_CONFIG_FILE"
        exit 1
    fi

    # Start VPN connection
    if command -v pkexec &> /dev/null; then
        pkexec openfortivpn -c "$CONFIG_TO_USE"
    else
        sudo openfortivpn -c "$CONFIG_TO_USE"
    fi
}

disconnect_vpn() {
    if ! check_vpn_status; then
        print_warning "VPN is not connected"
        return 0
    fi

    print_status "Disconnecting from FortiVPN..."
    if command -v pkexec &> /dev/null; then
        pkexec pkill openfortivpn
    else
        sudo pkill openfortivpn
    fi

    print_status "VPN disconnected"
}

show_status() {
    echo -e "${BLUE}VPN Status:${NC}"
    if check_vpn_status; then
        print_status "Connected"
        echo
        echo -e "${BLUE}Connection Details:${NC}"
        ps aux | grep "[o]penfortivpn" | head -1
        echo
        echo -e "${BLUE}Network Routes:${NC}"
        ip route | grep -E "ppp|tun" | head -5
    else
        print_error "Not connected"
    fi
}

create_config() {
    print_status "Creating FortiVPN configuration..."

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$USER_CONFIG_FILE")"

    # Prompt for server details
    read -p "Enter VPN server hostname or IP: " vpn_host
    read -p "Enter VPN port (default 443): " vpn_port
    vpn_port=${vpn_port:-443}
    read -p "Enter realm (leave empty if none): " vpn_realm
    read -p "Enter username: " vpn_username

    # Create configuration
    cat > "$USER_CONFIG_FILE" << EOF
# FortiVPN Configuration
host = $vpn_host
port = $vpn_port
username = $vpn_username
${vpn_realm:+realm = $vpn_realm}

# Security settings
set-dns = 1
set-routes = 1
half-internet-routes = 0
persistent = 5

# Uncomment and set if you have the certificate hash
# trusted-cert = sha256:xxxxxx
EOF

    chmod 600 "$USER_CONFIG_FILE"
    print_status "Configuration saved to $USER_CONFIG_FILE"
}

show_help() {
    print_header
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  connect    - Connect to FortiVPN"
    echo "  disconnect - Disconnect from FortiVPN"
    echo "  status     - Show VPN connection status"
    echo "  config     - Create or edit VPN configuration"
    echo "  help       - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 connect    # Connect to VPN"
    echo "  $0 status     # Check connection status"
    echo "  $0 disconnect # Disconnect from VPN"
}

# Main script
print_header

case "${1:-help}" in
    connect|c)
        connect_vpn
        ;;
    disconnect|d)
        disconnect_vpn
        ;;
    status|s)
        show_status
        ;;
    config|configure)
        create_config
        ;;
    help|h|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac