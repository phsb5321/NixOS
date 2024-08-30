{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    arduino
    arduino-ide
    arduino-cli
    python3
    python3Packages.pyserial
    esptool
    git
  ];

  shellHook = ''
    export PATH="$PATH:$HOME/.arduino15/packages/esp32/tools/xtensa-esp32-elf-gcc/1.22.0-97-gc752ad5-5.2.0/bin"
    export ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS="https://dl.espressif.com/dl/package_esp32_index.json"

    echo "ESP32 development environment with Arduino IDE is ready!"
    echo "Remember to install the ESP32 board support package in the Arduino IDE."
  '';
}
