# FortiClient VPN Setup Guide

## Overview
FortiClient VPN has been configured for the laptop host using OpenFortiVPN, an open-source SSL VPN client that provides compatibility with FortiGate VPN servers.

## Components Installed

### 1. OpenFortiVPN Client
- Command-line VPN client: `openfortivpn`
- Web authentication support: `openfortivpn-webview` (for SAML/SSO)

### 2. NetworkManager Integration
- GUI support via NetworkManager applet
- FortiSSL VPN plugin for NetworkManager
- Accessible through GNOME Settings → Network → VPN

### 3. Helper Script
Location: `~/NixOS/user-scripts/forticlient-connect.sh`

## Configuration

### Initial Setup

1. **Configure VPN Server Details**:
   ```bash
   # Run the configuration wizard
   ./user-scripts/forticlient-connect.sh config
   ```
   This will prompt for:
   - VPN server hostname/IP
   - Port (default: 443)
   - Realm (if applicable)
   - Username

2. **Alternative: Edit NixOS Configuration**:
   Edit `~/NixOS/hosts/laptop/configuration.nix`:
   ```nix
   modules.hardware.forticlient = {
     enable = true;
     autoStart = false;  # Set to true for auto-connect on boot

     serverConfig = {
       host = "vpn.example.com";
       port = 443;
       realm = "";  # Optional
     };

     # Optional: Add trusted certificate
     trustedCert = "sha256:certificate_hash_here";
   };
   ```
   Then rebuild: `./user-scripts/nixswitch`

## Usage

### Command Line (Helper Script)

```bash
# Connect to VPN
./user-scripts/forticlient-connect.sh connect

# Check connection status
./user-scripts/forticlient-connect.sh status

# Disconnect from VPN
./user-scripts/forticlient-connect.sh disconnect

# Show help
./user-scripts/forticlient-connect.sh help
```

### GUI (NetworkManager)

1. Open GNOME Settings → Network
2. Click "+" next to VPN
3. Select "Fortinet SSL VPN"
4. Enter connection details:
   - Gateway: Your VPN server address
   - Username: Your VPN username
   - Password: Can be saved or entered each time
5. Click "Add" to save the connection
6. Toggle VPN on/off from the network menu in the top bar

### Direct OpenFortiVPN Command

```bash
# Connect with password prompt
sudo openfortivpn vpn.example.com:443 -u username

# Connect with configuration file
sudo openfortivpn -c /etc/openfortivpn/config
```

## Troubleshooting

### Certificate Issues

If you encounter certificate trust errors:

1. **Get the certificate hash**:
   ```bash
   openfortivpn vpn.example.com:443 --no-routes --no-dns
   ```
   The error message will show the certificate hash.

2. **Add to configuration**:
   - For user config: Add to `~/.config/forticlient/config`
   - For system config: Add `trustedCert` in NixOS configuration

### Connection Issues

1. **Check VPN status**:
   ```bash
   ./user-scripts/forticlient-connect.sh status
   ```

2. **View logs**:
   ```bash
   journalctl -u openfortivpn -f  # If using systemd service
   sudo openfortivpn -v vpn.example.com  # Verbose mode
   ```

3. **Test connectivity**:
   ```bash
   ping vpn.example.com
   telnet vpn.example.com 443
   ```

### NetworkManager Issues

1. **Restart NetworkManager**:
   ```bash
   sudo systemctl restart NetworkManager
   ```

2. **Check plugin installation**:
   ```bash
   ls /run/current-system/sw/lib/NetworkManager/VPN/
   ```

## Security Notes

1. **Configuration File Permissions**:
   - User config: `~/.config/forticlient/config` (mode 0600)
   - System config: `/etc/openfortivpn/config` (mode 0600)

2. **Password Storage**:
   - Avoid storing passwords in configuration files
   - Use NetworkManager keyring for GUI connections
   - Enter password interactively for CLI connections

3. **DNS and Routes**:
   - VPN automatically configures DNS and routes
   - Original network settings restored on disconnect

## Advanced Configuration

### Split Tunneling
To route only specific traffic through VPN, edit configuration:
```
half-internet-routes = 1
```

### Persistent Connection
For automatic reconnection on network changes:
```
persistent = 5  # Retry interval in seconds
```

### Custom Routes
Add specific routes in the configuration file:
```
set-routes = 1
route = 10.0.0.0/8
route = 192.168.0.0/16
```

## Common Commands Reference

| Action | Command |
|--------|---------|
| Quick connect | `./user-scripts/forticlient-connect.sh connect` |
| Quick status | `./user-scripts/forticlient-connect.sh status` |
| GUI connect | Use GNOME network menu |
| Manual connect | `sudo openfortivpn vpn.example.com -u username` |
| View active VPN | `ip route \| grep ppp` |
| Check DNS | `resolvectl status` |

## Support

For issues specific to:
- OpenFortiVPN: https://github.com/adrienverge/openfortivpn
- NetworkManager plugin: https://github.com/GNOME/NetworkManager-fortisslvpn
- NixOS configuration: Check `~/NixOS/modules/hardware/forticlient.nix`