# Sample Configuration for GUI Dependencies Module

## Add to your NixOS configuration file

```nix
# In your configuration.nix (e.g., hosts/default/configuration.nix)
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
    ../shared/common.nix
  ];

  # ... your existing configuration ...

  # Enable GUI application dependencies for development
  modules.core.guiAppDeps = {
    enable = true;
    
    # Enable web testing dependencies (Cypress, Playwright, etc.)
    web = {
      enable = true;
      extraPackages = with pkgs; [
        # Add any additional web testing packages here
      ];
    };
    
    # Enable Electron application dependencies if needed
    electron = {
      enable = false;  # Set to true if you develop Electron apps
    };
    
    # Add any additional GUI packages
    extraPackages = with pkgs; [
      # Add any additional GUI packages here
    ];
  };

  # ... rest of your configuration ...
}
```

## After Adding the Configuration

1. **Rebuild your system**:

   ```bash
   sudo nixos-rebuild switch
   ```

2. **Test the JavaScript shell**:

   ```bash
   nix-shell ~/NixOS/shells/JavaScript.nix
   ```

3. **Test Cypress**:

   ```bash
   cd /tmp
   mkdir test-project && cd test-project
   npm init -y
   npm install --save-dev cypress
   npx cypress open
   ```

## Module Options

### `modules.core.guiAppDeps.enable`

- **Type**: boolean
- **Default**: false
- **Description**: Enable GUI application dependencies module

### `modules.core.guiAppDeps.web.enable`

- **Type**: boolean
- **Default**: false
- **Description**: Enable web testing and browser automation dependencies

### `modules.core.guiAppDeps.electron.enable`

- **Type**: boolean
- **Default**: false
- **Description**: Enable Electron application dependencies

### `modules.core.guiAppDeps.extraPackages`

- **Type**: list of packages
- **Default**: []
- **Description**: Additional GUI application packages to install

### `modules.core.guiAppDeps.web.extraPackages`

- **Type**: list of packages
- **Default**: []
- **Description**: Additional web testing packages to install
