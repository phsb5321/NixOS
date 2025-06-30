# /home/notroot/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
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

  # Laptop-specific configuration
  # Override hostname for laptop
  modules.networking.hostName = "nixos-laptop";
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

    # NVIDIA driver package (use production version)
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # Enable PRIME for hybrid graphics (Optimus) - use NVIDIA as primary
    prime = {
      # Enable sync mode - NVIDIA GPU drives the display
      sync.enable = true;
      
      # Disable offload mode since we're using sync
      offload.enable = false;

      # Specify the Intel and NVIDIA GPU BUS IDs
      # You may need to adjust these based on your specific laptop
      # Run `sudo lshw -c display` to find your actual BUS IDs
      intelBusId = "PCI:0:2:0"; # Common Intel integrated graphics BUS ID
      nvidiaBusId = "PCI:1:0:0"; # Common NVIDIA discrete graphics BUS ID
    };
  };

  # NVIDIA container toolkit for containerized applications
  hardware.nvidia-container-toolkit.enable = true;

  # Configure X server video drivers - use NVIDIA as primary GPU
  services.xserver.videoDrivers = ["nvidia"];

  # Wayland-first configuration with X server for compatibility
  # X server enables XWayland automatically
  # GDM and GNOME will prefer Wayland but support X11 apps through XWayland

  services.dbus = {
    enable = true;
    packages = [pkgs.dconf];
  };
  # Laptop-specific PAM services
  security.pam.services = {
    login.enableGnomeKeyring = true;
  };

  # Laptop-specific environment configuration (NVIDIA primary)
  environment = {
    sessionVariables = {
      LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.pipewire}/lib";
      SHELL = "${pkgs.zsh}/bin/zsh";

      # NVIDIA as primary GPU configuration
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia"; # Use NVIDIA for video acceleration
      VDPAU_DRIVER = "nvidia";

      # Scaling settings
      GDK_SCALE = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      # NVIDIA optimizations
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "/tmp/gl_cache";
      __GL_SYNC_TO_VBLANK = "1";

      # Steam optimizations
      STEAM_RUNTIME_HEAVY = "1";
      STEAM_FRAME_FORCE_CLOSE = "1";

      # Vulkan optimizations for NVIDIA
      DXVK_HUD = "fps,memory,gpuload";
      DXVK_ASYNC = "1";
      VKD3D_CONFIG = "dxr11";
    };

    systemPackages = with pkgs; [
      # Laptop-specific packages for NixOS 25.05
      linux-firmware
      wayland
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      mesa-demos
      lshw
      xorg.xrandr
      xorg.xinput

      # Verification tools for Intel graphics
      libva-utils # vainfo command
      vulkan-tools # vulkaninfo
      glxinfo

      # Gaming-specific tools for laptop with NVIDIA Optimus
      corectrl # GPU monitoring and control
      btop # System monitoring
      intel-gpu-tools # Intel GPU debugging and monitoring (integrated GPU)
      mesa-demos # Mesa utilities (glxinfo, glxgears, etc.)

      # NVIDIA-specific tools
      # Note: nvidia-offload script is provided by hardware.nvidia.prime.offload
    ];
  };

  # XDG Portal configuration for laptop (GNOME handles this automatically)
  # Note: GNOME module configures XDG portals properly

  # Laptop-specific boot configuration for NVIDIA Optimus
  boot = {
    # Remove NVIDIA modules from blacklist to enable NVIDIA GPU
    blacklistedKernelModules = [
      "nouveau" # Keep nouveau blacklisted (conflicts with proprietary driver)
    ];

    # Hybrid graphics optimizations for NixOS 25.05 with gaming enhancements
    kernelParams = [
      # Intel graphics optimizations (still used for power saving)
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_hd_vgaarb=1"
      "i915.enable_dc=2"
      "i915.enable_guc=3" # Enable GuC and HuC firmware loading
      "i915.enable_huc=1"
      "i915.fastboot=1" # Enable fastboot
      "i915.semaphores=1" # Enable semaphores for better performance
      "mitigations=off" # Disable CPU mitigations for better gaming performance
      "split_lock_detect=off" # Disable split lock detection for gaming
      # WiFi-specific parameters to handle hard block issues
      "rfkill.default_state=1"
      "iwlwifi.power_save=0"
      "iwlwifi.11n_disable=0"
      "iwlwifi.uapsd_disable=3"
      # ACPI and hardware parameters for Clevo/Avell laptops
      "acpi_osi=\"Windows 2020\""
      "pci=noaer"
      # More aggressive rfkill workarounds
      "rfkill.master_switch_mode=2"
      "acpi_enforce_resources=lax"
      # Try to prevent ACPI from managing WiFi rfkill
      "acpi_backlight=vendor"
      # Gaming performance optimizations
      "processor.max_cstate=1" # Reduce CPU sleep states for lower latency
      "intel_idle.max_cstate=0" # Disable deeper C-states for gaming
      # Uncomment if needed for specific Intel GPUs (12th Gen Alder Lake example)
      # "i915.force_probe=46a8"
    ];

    kernelModules = ["i915" "iwlwifi"];
    initrd.kernelModules = ["i915"];

    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # Laptop-specific programs
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Enable Docker for development
  virtualisation.docker.enable = true;

  # Enable Tailscale for laptop
  services.tailscale.enable = true;

  # Custom VS Code configuration to fix Electron warnings
  nixpkgs.overlays = [
    (final: prev: {
      vscode = prev.vscode.overrideAttrs (oldAttrs: {
        # Replace the default wrapper to avoid problematic flags
        postFixup =
          (oldAttrs.postFixup or "")
          + ''
                      # Create a new wrapper that ignores NIXOS_OZONE_WL and uses proper flags
                      rm $out/bin/code
                      cat > $out/bin/code << EOF
            #!${final.bash}/bin/bash
            exec -a "\$0" "$out/bin/.code-wrapped" \\
              --ozone-platform=wayland \\
              "\$@"
            EOF
                      chmod +x $out/bin/code
          '';
      });
    })
  ];
}
