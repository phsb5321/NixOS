#!/usr/bin/env bash

# fix-bluetooth-headset.sh
# This script helps troubleshoot and repair Bluetooth headphone profile switching issues
# Specifically designed for Soundcore Q30 and similar headsets with PipeWire

# Make script exit on any error
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}Bluetooth Headphone Profile Switcher${NC}"
echo "This utility helps fix profile switching for your Bluetooth headphones"
echo "Particularly useful for Soundcore Q30 and similar devices"
echo

# Check if the user has sudo privileges
if ! sudo -v &>/dev/null; then
  echo -e "${RED}You need sudo privileges to run this script.${NC}"
  exit 1
fi

# Check if PipeWire is running
if ! systemctl --user is-active pipewire >/dev/null 2>&1; then
  echo -e "${RED}PipeWire service is not running. Starting it now...${NC}"
  systemctl --user start pipewire pipewire-pulse wireplumber
fi

# Check for required tools
if ! command -v bluetoothctl &>/dev/null; then
  echo -e "${RED}bluetoothctl not found. Installing required packages...${NC}"
  sudo nix-env -iA nixos.bluez
fi

# Function to list connected Bluetooth audio devices
list_devices() {
  echo -e "${BLUE}Listing connected Bluetooth audio devices:${NC}"
  connected_devices=$(bluetoothctl devices | grep Device)

  if [ -z "$connected_devices" ]; then
    echo -e "${YELLOW}No paired Bluetooth devices found.${NC}"
    return 1
  fi

  # Display devices with numbers
  count=1
  while IFS= read -r line; do
    device_mac=$(echo "$line" | awk '{print $2}')
    device_name=$(echo "$line" | cut -d ' ' -f 3-)
    connected=$(bluetoothctl info "$device_mac" | grep "Connected: yes" || echo "")

    if [ -n "$connected" ]; then
      echo -e "$count) $device_name ${GREEN}(Connected)${NC} - $device_mac"
    else
      echo -e "$count) $device_name - $device_mac"
    fi

    count=$((count + 1))
  done <<<"$connected_devices"

  return 0
}

# Function to reset and repair a Bluetooth device
reset_device() {
  local mac_address=$1
  local device_name=$2

  echo -e "${YELLOW}Attempting to reset device: $device_name${NC}"

  # Disconnect the device
  echo "Disconnecting device..."
  bluetoothctl disconnect "$mac_address"
  sleep 2

  # Remove the device
  echo "Removing device from paired devices..."
  bluetoothctl remove "$mac_address"
  sleep 2

  # Put the controller in scanning mode
  echo "Scanning for devices..."
  bluetoothctl scan on &
  scan_pid=$!
  sleep 5
  kill $scan_pid 2>/dev/null || true

  # Pair and connect to the device
  echo "Pairing with device..."
  bluetoothctl pair "$mac_address"
  sleep 2

  echo "Trusting device..."
  bluetoothctl trust "$mac_address"
  sleep 1

  echo "Connecting to device..."
  bluetoothctl connect "$mac_address"

  echo -e "${GREEN}Device reset complete. The device should now work correctly.${NC}"
}

# Function to restart audio services
restart_audio_services() {
  echo -e "${BLUE}Restarting audio services...${NC}"

  # Restart PipeWire services
  systemctl --user stop pipewire pipewire-pulse wireplumber
  sleep 2
  systemctl --user start pipewire pipewire-pulse wireplumber

  # Restart Bluetooth service
  sudo systemctl restart bluetooth

  echo -e "${GREEN}Audio services restarted successfully.${NC}"
}

# Function to create user PipeWire configuration
create_user_config() {
  local config_dir="$HOME/.config/pipewire/pipewire-pulse.conf.d"

  echo -e "${BLUE}Creating user PipeWire configuration...${NC}"

  # Create directory if it doesn't exist
  mkdir -p "$config_dir"

  # Create configuration file for Bluetooth
  cat >"$config_dir/99-bluetooth-headset-fix.conf" <<EOF
pulse.properties = {
  # Better auto-switching for Bluetooth headphones
  bluez5.hw-offload = true
  bluez5.autoswitch-profile = true
  # Enable all roles to ensure proper functionality
  bluez5.roles = [hfp_hf hfp_ag hsp_hs hsp_ag a2dp_sink a2dp_source]
  # Enable high-quality codecs
  bluez5.enable-sbc-xq = true
  bluez5.enable-msbc = true
  # Force higher connection priority
  bluez5.headset-priority = 10
}
EOF

  echo -e "${GREEN}Configuration created at $config_dir/99-bluetooth-headset-fix.conf${NC}"
  echo "You need to restart PipeWire for changes to take effect."
}

# Main menu
show_menu() {
  echo
  echo -e "${BOLD}Please select an option:${NC}"
  echo "1) List connected Bluetooth devices"
  echo "2) Reset and repair Bluetooth device"
  echo "3) Restart audio services"
  echo "4) Create user configuration for better headset switching"
  echo "5) Exit"
  echo
  read -p "Enter your choice [1-5]: " choice

  case $choice in
  1)
    list_devices
    show_menu
    ;;
  2)
    if list_devices; then
      read -p "Enter the number of the device to reset: " device_num

      # Get the selected device
      count=1
      while IFS= read -r line; do
        if [ "$count" -eq "$device_num" ]; then
          device_mac=$(echo "$line" | awk '{print $2}')
          device_name=$(echo "$line" | cut -d ' ' -f 3-)
          reset_device "$device_mac" "$device_name"
          break
        fi
        count=$((count + 1))
      done <<<"$(bluetoothctl devices | grep Device)"
    fi
    show_menu
    ;;
  3)
    restart_audio_services
    show_menu
    ;;
  4)
    create_user_config
    read -p "Would you like to restart audio services now? (y/n): " restart
    if [[ $restart == "y" || $restart == "Y" ]]; then
      restart_audio_services
    fi
    show_menu
    ;;
  5)
    echo -e "${GREEN}Goodbye!${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice. Please select a valid option.${NC}"
    show_menu
    ;;
  esac
}

# Start the menu
show_menu
