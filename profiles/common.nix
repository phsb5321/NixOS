# ~/NixOS/profiles/common.nix
# Common profile - Single source of truth for user configuration
# All hosts import this profile to get the canonical user definition
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
}
