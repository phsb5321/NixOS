{...}: {
  # Virtualization modules aggregator
  # Imports all virtualization-related modules (libvirt, future GPU passthrough, etc.)

  imports = [
    ./libvirt.nix
  ];
}
