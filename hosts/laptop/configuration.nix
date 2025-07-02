# /home/notroot/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  systemVersion,
  bleedPkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.home-manager.nixosModules.default
    ../shared/common.nix
  ];

  # Host-specific metadata
  networking.hostName = hostname;

  # Override shared configuration as needed
  modules.networking.hostName = hostname;
  modules.home.hostName = "laptop";

  # WiFi Hardware and Firmware Configuration
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # WiFi-specific kernel modules options for Intel AX201
  boot.extraModprobeConfig = ''
    # Intel WiFi AX201 optimizations with correct parameter names
    options iwlwifi 11n_disable=0 power_save=0 uapsd_disable=3 fw_restart=1
    options iwlmvm power_scheme=1
  '';

  # Enhanced WiFi unblock service with more aggressive approach
  systemd.services.wifi-unblock = {
    description = "Unblock WiFi and reset hardware";
    after = ["network-pre.target"];
    wants = ["network-pre.target"];
    before = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = pkgs.writeShellScript "wifi-unblock-pre" ''
        # More aggressive module unloading
        ${pkgs.kmod}/bin/modprobe -r iwlmvm || true
        ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
        ${pkgs.coreutils}/bin/sleep 2

        # Try to reset PCI device
        echo "0000:00:14.3" > /sys/bus/pci/drivers/iwlwifi/unbind 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 1
        echo "0000:00:14.3" > /sys/bus/pci/drivers/iwlwifi/bind 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 1
      '';
      ExecStart = pkgs.writeShellScript "wifi-unblock-start" ''
        # Unblock all rfkill devices
        ${pkgs.util-linux}/bin/rfkill unblock all
        ${pkgs.coreutils}/bin/sleep 1

        # Load iwlwifi with new parameters
        ${pkgs.kmod}/bin/modprobe iwlwifi
        ${pkgs.coreutils}/bin/sleep 3

        # Load iwlmvm
        ${pkgs.kmod}/bin/modprobe iwlmvm
        ${pkgs.coreutils}/bin/sleep 3

        # Try to unblock again after driver loading
        ${pkgs.util-linux}/bin/rfkill unblock all
      '';
      ExecStartPost = pkgs.writeShellScript "wifi-unblock-post" ''
        ${pkgs.util-linux}/bin/rfkill unblock wifi || true
        ${pkgs.util-linux}/bin/rfkill unblock all || true

        # Force-enable the interface if it exists
        if ${pkgs.iproute2}/bin/ip link show wlo1 >/dev/null 2>&1; then
          ${pkgs.iproute2}/bin/ip link set wlo1 up || true
        fi
      '';
      RemainAfterExit = true;
    };
    wantedBy = ["multi-user.target"];
  };

  # Dynamic WiFi enablement service that detects the interface name
  systemd.services.wifi-enable = {
    description = "Enable WiFi in NetworkManager";
    after = ["NetworkManager.service" "wifi-unblock.service"];
    requires = ["NetworkManager.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "wifi-enable" ''
        # Wait for NetworkManager to be ready
        ${pkgs.coreutils}/bin/sleep 3

        # Enable WiFi radio
        ${pkgs.networkmanager}/bin/nmcli radio wifi on || true

        # Find WiFi device name dynamically
        WIFI_DEV=$(${pkgs.iproute2}/bin/ip link show | ${pkgs.gnugrep}/bin/grep -E "wl[a-z0-9]+:" | ${pkgs.coreutils}/bin/cut -d: -f2 | ${pkgs.coreutils}/bin/tr -d ' ' | ${pkgs.coreutils}/bin/head -n1)

        if [ -n "$WIFI_DEV" ]; then
          echo "Found WiFi device: $WIFI_DEV"
          ${pkgs.networkmanager}/bin/nmcli device set "$WIFI_DEV" managed yes || true
          ${pkgs.iproute2}/bin/ip link set "$WIFI_DEV" up || true
        else
          echo "No WiFi device found"
          exit 1
        fi
      '';
      RemainAfterExit = true;
    };
    wantedBy = ["multi-user.target"];
  };

  # Laptop-specific core module additions
  modules.core.extraSystemPackages = with pkgs; [
    nvtopPackages.full # Keep for monitoring
    bash # Make sure bash is in system packages
  ];

  # Laptop-specific extra packages (minimal set for laptop)
  modules.packages.extraPackages = with pkgs; [
    # Debugging tools for laptop
    glxinfo
  ];

  # Enable gaming packages for laptop
  modules.packages.gaming.enable = true;

  # Laptop-specific Python without GTK (to match original config)
  modules.packages.python.withGTK = lib.mkForce false;

  # Laptop-specific locale settings (override if needed)
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
    glibcLocales = pkgs.glibcLocales;
  };

  # Laptop-specific user configuration
  users.users.notroot = {
    initialPassword = "changeme";
    shell = "${pkgs.zsh}/bin/zsh";
    extraGroups = [
      "nvidia" # NVIDIA GPU access
    ];
  };

  # Register shells with explicit paths
  environment.shells = [
    "${pkgs.bash}/bin/bash"
    "${pkgs.zsh}/bin/zsh"
  ];

  # Laptop-specific Intel hardware configuration for NixOS 25.05
  hardware.cpu.intel.updateMicrocode = true;

  # Laptop-specific gaming optimizations for NVIDIA Optimus (hybrid graphics)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Intel graphics (for power saving and basic tasks)
      intel-media-driver # Modern driver (iHD) for Broadwell+
      intel-vaapi-driver # Legacy driver (i965) - better browser support
      vpl-gpu-rt # Intel Quick Sync Video
      libvdpau-va-gl # VDPAU support
      intel-compute-runtime # OpenCL support for Intel GPUs
      # Mesa and Vulkan (works with both Intel and NVIDIA)
      mesa # Mesa drivers with Intel support
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
      mesa
      vulkan-loader
    ];
  };

  # NVIDIA Optimus configuration for gaming laptops
  hardware.nvidia = {
    # Enable the NVIDIA driver
    modesetting.enable = true;

    # Enable power management (important for laptops)
    powerManagement.enable = true;

    # Fine-grained power management (experimental, but helps with battery)
    powerManagement.finegrained = false;

    # Use open source kernel module (newer, better for gaming)
    open = false; # Set to true if you want to try the open-source driver

    # Enable NVIDIA settings menu
    nvidiaSettings = true;

    # Select the driver package (stable for laptops)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Optimus/PRIME configuration for hybrid graphics
    prime = {
      # Sync mode for better performance but higher power consumption
      sync.enable = true;

      # Use these if you need offload mode instead:
      # offload.enable = true;
      # offload.enableOffloadCmd = true;

      # Bus IDs for Intel and NVIDIA GPUs (use lspci to find these)
      # Run: lspci | grep -E "(VGA|3D)"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Video drivers for hybrid graphics
  services.xserver.videoDrivers = ["nvidia"];

  # NVIDIA-specific environment variables
  environment.sessionVariables = {
    # NVIDIA specific
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  # Laptop-specific boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;

    # Laptop-optimized kernel parameters
    kernelParams = [
      # NVIDIA parameters for laptops
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      # Power management
      "acpi_osi=Linux"
      "pcie_aspm=force"
    ];

    # Load NVIDIA modules early
    initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  };

  # Laptop-specific power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Disable USB autosuspend for mouse/keyboard
      USB_BLACKLIST_PHONE = 1;
    };
  };

  # Laptop-specific services
  # Disable power-profiles-daemon to use TLP and auto-cpufreq instead
  services.power-profiles-daemon.enable = lib.mkForce false;

  services = {
    # Battery optimization
    auto-cpufreq.enable = true;

    # Thermal management
    thermald.enable = true;
  };

}
