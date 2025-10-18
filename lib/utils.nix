# ~/NixOS/lib/utils.nix
# Utility functions for NixOS configuration
{ lib }:

{
  # Merge multiple attrsets with priority
  mergeWithPriority = priority: attrs:
    lib.mapAttrs (_: v: lib.mkOverride priority v) attrs;

  # Conditional package lists
  pkgsIf = condition: packages:
    if condition then packages else [];

  # Enable multiple options at once
  enableAll = options:
    lib.listToAttrs (map (opt: { name = opt; value = { enable = true; }; }) options);

  # Create GNOME extension list from names
  mkGnomeExtensions = extensions:
    map (ext: "${ext}@gnome-shell-extensions.gcampax.github.com") extensions;
}
