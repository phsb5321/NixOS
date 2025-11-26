# WiFi Password Security Fix - Quick Guide

This guide will help you move the hardcoded WiFi password to encrypted secrets and remove it from Git history.

## What I've Done

1. ✅ Updated the WiFi module (`modules/networking/wifi.nix`) to support `pskFile` for reading passwords from secret files
2. ✅ Updated laptop configuration (`hosts/laptop/configuration.nix`) to use sops-nix for WiFi password
3. ✅ Created automated cleanup script to remove password from Git history

## What You Need to Do

### Step 1: Generate Encryption Keys

```bash
cd /home/notroot/NixOS

# Generate personal age key for editing secrets
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# View your personal public key (save this)
age-keygen -y ~/.config/sops/age/keys.txt
```

**Save the output** - it will look like: `age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

```bash
# Generate host age key from SSH key
sudo mkdir -p /var/lib/sops-nix
sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -o /var/lib/sops-nix/key.txt

# Get the host public key (save this too)
sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key
```

**Save this output too** - another `age1...` key.

### Step 2: Configure SOPS

Edit the template file I created:

```bash
cd /home/notroot/NixOS/secrets
nano .sops.yaml.template
```

Replace:
- `YOUR_PERSONAL_PUBLIC_KEY_HERE` with your personal age public key from Step 1
- `YOUR_LAPTOP_HOST_PUBLIC_KEY_HERE` with the laptop host public key from Step 1

Then rename it:

```bash
mv .sops.yaml.template .sops.yaml
```

### Step 3: Create Encrypted WiFi Password

```bash
cd /home/notroot/NixOS

# Create and edit the encrypted secret file
sops secrets/laptop.yaml
```

In your editor, add:

```yaml
# WiFi passwords for laptop
wifi_live_tim_4122_psk: "123"
```

**Replace "123" with your actual WiFi password**.

Save and exit. SOPS will encrypt it automatically.

### Step 4: Commit the Secure Configuration

```bash
cd /home/notroot/NixOS

# Stage all the changes
git add .

# Commit (the password is now in encrypted form only)
git commit -m "feat(laptop): move WiFi password to encrypted secrets

- Add pskFile support to WiFi module for reading secrets
- Configure sops-nix for laptop host
- Move WiFi password to encrypted secrets/laptop.yaml
- Remove hardcoded password from configuration

Fixes: Hardcoded WiFi password in version control"
```

### Step 5: Test the Configuration

Before cleaning history, make sure the new configuration works:

```bash
# Build but don't activate (safe test)
sudo nixos-rebuild test --flake .#laptop

# If that works, activate it
sudo nixos-rebuild switch --flake .#laptop

# Check that WiFi connects
# Check that the secret file exists
sudo ls -l /run/secrets/
```

If WiFi works, proceed to Step 6. If not, debug the issue first.

### Step 6: Remove Password from Git History

Run the automated cleanup script:

```bash
cd /home/notroot/NixOS
./remove-wifi-password-from-history.sh
```

The script will:
- Check if password exists in current files (should be gone)
- Find all commits containing the password
- Create a backup branch automatically
- Replace the password with "123" in ALL commits
- Verify the cleanup was successful

**Follow the prompts carefully!**

### Step 7: Force Push to Remote

⚠️ **WARNING**: This rewrites history on the remote repository!

```bash
# Push the cleaned history
git push origin host/laptop --force
```

### Step 8: Update Other Clones (if any)

If you have this repository cloned elsewhere:

```bash
# On other machines
git fetch origin
git reset --hard origin/host/laptop
```

## Verification

Check that everything is secure:

```bash
# 1. Password should NOT be in current files
grep -r "123" /home/notroot/NixOS/ 2>/dev/null
# Should return nothing

# 2. Password should NOT be in git history
git log --all --full-history -S "123"
# Should return nothing

# 3. Encrypted secret should exist and be readable
sops -d secrets/laptop.yaml
# Should show your WiFi password

# 4. WiFi should work
nmcli device wifi list
nmcli connection show
```

## Troubleshooting

### "no key could decrypt the data"

- Make sure your personal key is in `~/.config/sops/age/keys.txt`
- Check that `.sops.yaml` has the correct public keys
- Try `sops updatekeys secrets/laptop.yaml` to re-encrypt with current keys

### "secret not found at boot"

- Verify host key exists: `sudo ls -l /var/lib/sops-nix/key.txt`
- Check sops configuration in laptop configuration.nix
- Rebuild with verbose: `sudo nixos-rebuild switch --flake .#laptop --show-trace`

### WiFi doesn't connect

- Check the secret path: `sudo ls -l /run/secrets/wifi_live_tim_4122_psk`
- View systemd service: `systemctl status wifi-secret-LIVE-TIM-4122`
- Check NetworkManager: `sudo nmcli connection show`

### Need to restore original history

```bash
# The cleanup script creates a backup branch
git branch  # Find the backup branch (backup-before-history-cleanup-*)
git reset --hard backup-before-history-cleanup-YYYYMMDD-HHMMSS
```

## Files Changed

- `modules/networking/wifi.nix` - Added `pskFile` support for secrets
- `hosts/laptop/configuration.nix` - Configured sops-nix and WiFi secret
- `secrets/.sops.yaml` - Encryption key configuration (create from template)
- `secrets/laptop.yaml` - Encrypted WiFi password (you need to create this)

## Security Notes

- ✅ The password is now encrypted at rest (in Git)
- ✅ The password is only decrypted at system activation time
- ✅ The secret file has restricted permissions (0400, root only)
- ✅ The password is removed from all Git history
- ✅ Template shows "123" as placeholder in cleaned commits

The old commits with the real password are completely removed from history.
