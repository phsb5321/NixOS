# ~/NixOS/lib/utils.nix
# Utility functions for NixOS configuration
{lib}: {
  # Merge multiple attrsets with priority
  mergeWithPriority = priority: attrs:
    lib.mapAttrs (_: v: lib.mkOverride priority v) attrs;

  # Conditional package lists
  pkgsIf = condition: packages:
    if condition
    then packages
    else [];

  # Enable multiple options at once
  enableAll = options:
    lib.listToAttrs (map (opt: {
        name = opt;
        value = {enable = true;};
      })
      options);

  # Create GNOME extension list from names
  mkGnomeExtensions = extensions:
    map (ext: "${ext}@gnome-shell-extensions.gcampax.github.com") extensions;

  # Conditional package lists (alias for pkgsIf for consistency)
  # Usage: mkConditionalPackages (!cfg.minimal) [ pkgs.extra1 pkgs.extra2 ]
  mkConditionalPackages = condition: packages:
    if condition
    then packages
    else [];

  # Simplified option with common defaults
  # Usage: mkOptionDefault lib.types.str "default-value" "Description here"
  mkOptionDefault = type: default: description: {
    inherit type default description;
  };

  # Combine multiple option sets
  # Usage: mkMergedOptions [ options1 options2 options3 ]
  mkMergedOptions = optionsList:
    lib.mkMerge optionsList;
}
