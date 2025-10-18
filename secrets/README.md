# Secrets Management with sops-nix

This directory contains encrypted secrets managed by [sops-nix](https://github.com/Mic92/sops-nix).

## Overview

Secrets are encrypted using age encryption and stored in this directory. They are decrypted at build/activation time and made available to services securely.

## Prerequisites

1. **age key pair**: Each host needs an age key pair
2. **sops**: Install sops for encrypting/decrypting secrets

```bash
# Install age and sops
nix-shell -p age sops

# Generate age key (if not already done)
age-keygen -o ~/.config/sops/age/keys.txt

# View your public key
age-keygen -y ~/.config/sops/age/keys.txt
```

## Directory Structure

```
secrets/
├── .sops.yaml           # sops configuration (key mapping)
├── default.yaml         # Secrets for default (desktop) host
├── laptop.yaml          # Secrets for laptop host
├── shared.yaml          # Shared secrets across all hosts
├── example.yaml.enc     # Example encrypted secret file
└── README.md            # This file
```

## Initial Setup

### 1. Generate Host Keys

On each host, generate an age key derived from the host's SSH key:

```bash
# On the host machine
sudo mkdir -p /var/lib/sops-nix
sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -o /var/lib/sops-nix/key.txt

# View the public key (needed for .sops.yaml)
sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key
```

### 2. Configure .sops.yaml

Create `.sops.yaml` with your host public keys:

```yaml
keys:
  # Admin user key (for editing secrets locally)
  - &admin_key age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  # Host keys (from ssh-to-age output)
  - &host_default age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &host_laptop age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

creation_rules:
  # Default host secrets
  - path_regex: secrets/default\.yaml$
    key_groups:
      - age:
          - *admin_key
          - *host_default

  # Laptop host secrets
  - path_regex: secrets/laptop\.yaml$
    key_groups:
      - age:
          - *admin_key
          - *host_laptop

  # Shared secrets
  - path_regex: secrets/shared\.yaml$
    key_groups:
      - age:
          - *admin_key
          - *host_default
          - *host_laptop
```

### 3. Create Secret Files

```bash
# Create and edit a secret file
sops secrets/default.yaml

# Add secrets in YAML format:
# example_password: "my-secret-password"
# api_key: "my-api-key"
```

## Usage in NixOS Configuration

### Enable sops-nix Module

In your host configuration:

```nix
{
  # Import sops secrets
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops
  sops = {
    defaultSopsFile = ./secrets/default.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Define secrets to decrypt
      example_password = {
        # Secret will be available at /run/secrets/example_password
      };

      api_key = {
        owner = "myservice";
        mode = "0400";
      };
    };
  };
}
```

### Use Secrets in Services

```nix
{
  systemd.services.myservice = {
    script = ''
      export API_KEY=$(cat ${config.sops.secrets.api_key.path})
      # Use API_KEY in your service
    '';
  };
}
```

## Common Operations

### Edit Secrets

```bash
# Edit existing secret file
sops secrets/default.yaml

# Create new secret file
sops secrets/new-secret.yaml
```

### View Decrypted Secrets

```bash
# View decrypted content (requires your age key)
sops -d secrets/default.yaml
```

### Rotate Keys

When adding/removing hosts or admin keys:

1. Update `.sops.yaml` with new keys
2. Re-encrypt all secrets with new keys:

```bash
# Update keys for all secret files
sops updatekeys secrets/default.yaml
sops updatekeys secrets/laptop.yaml
sops updatekeys secrets/shared.yaml
```

## Security Best Practices

1. **Never commit unencrypted secrets**: Always use sops to edit
2. **Protect age keys**: Keep `~/.config/sops/age/keys.txt` secure
3. **Host keys**: Store in `/var/lib/sops-nix/key.txt` on each host
4. **Permissions**: Secrets are readable only by specified owners
5. **Git tracking**: Only commit `.sops.yaml` and encrypted `.yaml` files

## Example Secret File

```yaml
# secrets/default.yaml (encrypted)
# Edit with: sops secrets/default.yaml

# WiFi passwords
wifi_password: "my-wifi-password"

# API keys
github_token: "ghp_xxxxxxxxxxxx"
openai_api_key: "sk-xxxxxxxxxxxx"

# Service passwords
database_password: "secure-db-password"
nextcloud_admin_password: "admin-password"

# SSH keys (for deployment)
deploy_ssh_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

## Integration with Dotfiles

Secrets can be used with chezmoi for dotfiles:

```nix
{
  sops.secrets.chezmoi_env = {
    path = "/home/notroot/.config/chezmoi/env";
    owner = "notroot";
  };
}
```

Then in chezmoi templates:

```bash
# ~/.local/share/chezmoi/.chezmoi.toml.tmpl
[data]
  github_token = "{{ env "GITHUB_TOKEN" }}"
```

## Troubleshooting

### "no key could decrypt the data"

- Ensure your age key is in `~/.config/sops/age/keys.txt`
- Check that the secret file was encrypted with your public key
- Verify `.sops.yaml` includes your key in the creation rules

### "permission denied" when accessing secrets

- Check the `owner` and `mode` settings in sops.secrets configuration
- Ensure the service user has read access to the secret file

### Secrets not decrypted at boot

- Verify `age.keyFile` points to the correct location
- Ensure the host key exists at the specified path
- Check that the secret file includes the host's public key

## References

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [sops Documentation](https://github.com/mozilla/sops)
- [age Encryption](https://age-encryption.org/)
