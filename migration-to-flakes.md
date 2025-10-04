# Migration Plan: Traditional NixOS to Flake-based Configuration

## Current Situation
- Your system is using traditional `/etc/nixos/configuration.nix`
- The repository uses a flake-based modular configuration
- You're now on the `host/laptop` branch which has the laptop-specific configuration

## Steps to Migrate

### 1. Enable Flakes on Your System
Add this to your current `/etc/nixos/configuration.nix`:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

### 2. Test the Flake Configuration
From the repository directory:
```bash
# Build the laptop configuration without switching
sudo nixos-rebuild build --flake .#laptop

# If successful, switch to it
sudo nixos-rebuild switch --flake .#laptop
```

### 3. Make the Flake Configuration Permanent
Once you've switched successfully, update the system to use the flake by default:
```bash
# Link the flake configuration
sudo rm -rf /etc/nixos
sudo ln -s /home/notroot/NixOS /etc/nixos
```

## Important Notes
- The flake configuration includes all your previous settings in a modular way
- Your hardware configuration will be preserved
- The automatic maintenance settings we discussed earlier are already included in the modules

## Maintenance Commands with Flakes
After migration, use these commands:
```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#laptop

# Garbage collection (same as before)
sudo nix-collect-garbage -d
```