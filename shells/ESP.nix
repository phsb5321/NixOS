{pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/nixpkgs-unstable.tar.gz") {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    arduino-ide
    arduino-cli
    platformio
    python3
    python3Packages.pyserial
    esptool
    git
    # optional programmer for ESP32, uncomment if needed
    pkgs.avrdude
  ];

  shellHook = ''
    # Setup for Arduino IDE
    export PATH="$PATH:$HOME/.arduino15/packages/esp32/tools/xtensa-esp32-elf-gcc/1.22.0-97-gc752ad5-5.2.0/bin"
    export ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS="https://dl.espressif.com/dl/package_esp32_index.json"

    # Setup for PlatformIO: set the core directory to be inside the project
    export PLATFORMIO_CORE_DIR=$PWD/.platformio

    # Print success messages
    echo "ESP32 development environment with Arduino IDE and PlatformIO is ready!"
    echo "Arduino IDE: Remember to install the ESP32 board support package."
    echo "PlatformIO: Core directory is set to $PLATFORMIO_CORE_DIR"
  '';
}
