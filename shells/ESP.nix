{pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/nixpkgs-unstable.tar.gz") {}}: let
  # Create a Python environment with necessary packages for MicroPython development
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      # Development tools
      pip
      black
      pylint
      pytest
      ipython
      setuptools
      wheel

      # ESP-specific tools
      pyserial

      # Additional utilities
      requests
      click
    ]);

  # Helper function to create a tagged package group
  mkPackageGroup = name: packages: {
    inherit name packages;
  };

  # Define package groups
  packageGroups = [
    (mkPackageGroup "MicroPython Development" [
      pythonEnv
      pkgs.thonny
      pkgs.picocom
      pkgs.esptool # Moved from Python packages to system packages
    ])
    (mkPackageGroup "Arduino & PlatformIO" [
      pkgs.arduino-ide
      pkgs.arduino-cli
      pkgs.platformio
    ])
    (mkPackageGroup "Build Tools" [
      pkgs.gcc
      pkgs.gnumake
      pkgs.cmake
      pkgs.ninja
    ])
    (mkPackageGroup "Debugging Tools" [
      pkgs.minicom
      pkgs.screen
      pkgs.usbutils
    ])
    (mkPackageGroup "Version Control" [
      pkgs.git
    ])
    (mkPackageGroup "MQTT Tools" [
      pkgs.mosquitto
    ])
  ];

  # Flatten package groups into a single list
  allPackages = builtins.concatLists (map (group: group.packages) packageGroups);
in
  pkgs.mkShell {
    buildInputs = allPackages;

    shellHook = ''
            # Create helper functions for MicroPython development
            setup_micropython_project() {
              if [ -z "$1" ]; then
                echo "Please provide a project name"
                return 1
              fi

              local project_name=$1
              mkdir -p "$project_name"/{src,lib,tests}

              # Create basic project structure
              cat > "$project_name/src/main.py" << 'EOF'
      from machine import Pin
      import time

      # Built-in LED pin (adjust for your board)
      led = Pin(2, Pin.OUT)

      def blink(delay_ms=500):
          while True:
              led.value(not led.value())
              time.sleep_ms(delay_ms)

      if __name__ == '__main__':
          try:
              blink()
          except KeyboardInterrupt:
              led.value(0)
              print("\nProgram stopped by user")
      EOF

              cat > "$project_name/src/boot.py" << 'EOF'
      # This file is executed on every boot (including wake-boot from deepsleep)
      import esp
      esp.osdebug(None)

      import gc
      gc.collect()
      EOF

              echo "Created new MicroPython project: $project_name"
              tree "$project_name"
            }

            # Function to install additional Python packages
            install_packages() {
              echo "Installing additional Python packages..."
              pip install --user rshell adafruit-ampy mpremote
              export PATH=$PATH:$HOME/.local/bin
            }

            # Function to flash MicroPython firmware
            flash_micropython() {
              local port=$1
              local firmware=$2

              if [ -z "$port" ] || [ -z "$firmware" ]; then
                echo "Usage: flash_micropython <port> <firmware_file>"
                echo "Example: flash_micropython /dev/ttyUSB0 esp32-firmware.bin"
                return 1
              fi

              echo "Erasing flash..."
              esptool --port "$port" erase_flash

              echo "Flashing MicroPython..."
              esptool --port "$port" --baud 460800 write_flash --flash_size=detect 0 "$firmware"
            }

            # First-time setup function
            setup_environment() {
              echo "Setting up MicroPython development environment..."
              install_packages
              mkdir -p .micropython/firmware
              mkdir -p .platformio

              # Create firmware directory if it doesn't exist
              if [ ! -d .micropython/firmware ]; then
                mkdir -p .micropython/firmware
                echo "Created firmware directory: .micropython/firmware"
                echo "Download MicroPython firmware from https://micropython.org/download/"
              fi

              # Add user to required groups if necessary
              for group in dialout tty plugdev; do
                if getent group $group > /dev/null; then
                  if ! groups | grep -q "\b$group\b"; then
                    echo "Note: You might need to add your user to the $group group:"
                    echo "sudo usermod -a -G $group $USER"
                  fi
                fi
              done

              echo "Environment setup complete!"
              echo "Remember to:"
              echo "1. Download MicroPython firmware for your board"
              echo "2. Ensure you have necessary permissions for USB access"
              echo "3. Log out and back in if you modified group memberships"
            }

            # Setup for Arduino IDE
            export PATH="$PATH:$HOME/.arduino15/packages/esp32/tools/xtensa-esp32-elf-gcc/1.22.0-97-gc752ad5-5.2.0/bin"
            export ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS="https://dl.espressif.com/dl/package_esp32_index.json"

            # Setup for PlatformIO
            export PLATFORMIO_CORE_DIR=$PWD/.platformio

            # Print environment information
            echo "🔧 ESP32 Development Environment Ready!"
            echo "📦 Available development environments:"
            ${builtins.concatStringsSep "\n" (map (group: "echo \"  - ${group.name}\"") packageGroups)}
            echo
            echo "🐍 MicroPython Setup:"
            echo "  1. Run 'setup_environment' to install additional tools"
            echo "  2. Create new project: setup_micropython_project <name>"
            echo "  3. Flash firmware: flash_micropython <port> <firmware>"
            echo
            echo "🛠️ Available Tools:"
            echo "  - Serial monitors: minicom, screen, picocom"
            echo "  - Code editor: thonny (MicroPython IDE)"
            echo "  - Board tool: esptool"
            echo
            echo "📝 Project Management:"
            echo "  - PlatformIO: platformio"
            echo "  - Arduino IDE: arduino-ide"
            echo
            echo "First time? Run 'setup_environment' to complete the installation"
    '';

    # Set environment variables
    MICROPY_PORT = "/dev/ttyUSB0"; # Default port, can be overridden

    # Add pkg-config to find system libraries
    nativeBuildInputs = [pkgs.pkg-config];
  }
