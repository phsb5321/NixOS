# ~/NixOS/modules/desktop/gnome/default.nix
# GNOME desktop modules
{
  imports = [
    ./base.nix
    ./extensions.nix
    ./wayland.nix
  ];
}
