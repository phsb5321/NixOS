# ~/NixOS/profiles/common.nix
# Common profile - Single source of truth for user configuration and package defaults
# All hosts import this profile to get the canonical user definition and common packages
{
  config,
  lib,
  pkgs,
  ...
}: {
  # ===== USER CONFIGURATION =====
  # This is the single source of truth for users.users.notroot
  # Host-specific groups should use lib.mkAfter to extend this definition
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    # Base groups shared by all hosts
    # Host-specific groups use lib.mkAfter in their configuration
    extraGroups = lib.mkDefault [
      "networkmanager"
      "wheel"
    ];
  };

  # ===== DEFAULT SHELL =====
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # ===== COMMON PACKAGE DEFAULTS =====
  # These are development workstation defaults shared by all hosts
  # Profiles can override with lib.mkForce or hosts can override specific options
  modules.packages = {
    # Browsers - common across all workstations
    browsers = {
      enable = lib.mkDefault true;
      chrome = lib.mkDefault true;
      brave = lib.mkDefault true;
      librewolf = lib.mkDefault true;
      zen = lib.mkDefault false; # Optional, enable per-host
    };

    # Development tools - core development environment
    development = {
      enable = lib.mkDefault true;
      editors = lib.mkDefault true;
      apiTools = lib.mkDefault true;
      runtimes = lib.mkDefault true;
      compilers = lib.mkDefault true;
      languageServers = lib.mkDefault true;
      versionControl = lib.mkDefault true;
      utilities = lib.mkDefault true;
      database = lib.mkDefault true;
      containers = lib.mkDefault true;
      debugging = lib.mkDefault true;
      networking = lib.mkDefault true;
    };

    # Utilities - essential system tools
    utilities = {
      enable = lib.mkDefault true;
      diskManagement = lib.mkDefault true;
      fileSync = lib.mkDefault false; # Syncthing handled by profile
      compression = lib.mkDefault true;
      security = lib.mkDefault true;
      pdfViewer = lib.mkDefault true;
      messaging = lib.mkDefault true;
      fonts = lib.mkDefault true;
    };

    # Terminal - modern CLI environment
    terminal = {
      enable = lib.mkDefault true;
      fonts = lib.mkDefault true;
      shell = lib.mkDefault true;
      theme = lib.mkDefault true;
      modernTools = lib.mkDefault true;
      plugins = lib.mkDefault true;
      editor = lib.mkDefault true;
      applications = lib.mkDefault true;
    };

    # Audio/Video - basic audio support
    audioVideo = {
      enable = lib.mkDefault true;
      pipewire = lib.mkDefault true;
      audioEffects = lib.mkDefault true;
      audioControl = lib.mkDefault true;
      webcam = lib.mkDefault true;
    };

    # Media - core media applications
    media = {
      enable = lib.mkDefault true;
      vlc = lib.mkDefault true;
      spotify = lib.mkDefault true;
      discord = lib.mkDefault true;
      streaming = lib.mkDefault false; # Enable per-profile
      imageEditing = lib.mkDefault true;
    };

    # Gaming - disabled by default, enable per-profile
    gaming.enable = lib.mkDefault false;
  };
}
