# DNS Resolution Issue - Complete Fix Guide

## Problem Description
DNS resolution fails intermittently on the default host. This manifests as:
- Some domains resolve while others don't
- Internet connectivity works (can ping IPs) but domain names fail
- Issue occurs randomly, especially after network changes, system resume, or after running for extended periods

## Quick Fix Script (USE THIS FIRST\!)
A fix script has been created at `~/fix-dns.sh`. Run it whenever DNS issues occur:
```bash
~/fix-dns.sh
```

## Manual Fix Steps (if script doesn't work)

### Step 1: Check what's broken
```bash
# Test if DNS servers are reachable
ping -c 1 8.8.8.8

# Test direct DNS queries
dig @8.8.8.8 google.com
dig @1.1.1.1 google.com

# Check resolver status
resolvectl status
```

### Step 2: Apply the fix
```bash
# 1. Flush DNS caches
sudo resolvectl flush-caches

# 2. Restart DNS resolver
sudo systemctl restart systemd-resolved

# 3. Manually set DNS servers
INTERFACE=$(ip route | grep default | awk '{print $5}')
sudo resolvectl dns $INTERFACE 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
sudo resolvectl domain $INTERFACE "~."

# 4. Restart NetworkManager
sudo systemctl restart NetworkManager

# 5. Cycle Tailscale if using it
sudo tailscale down && sudo tailscale up
```

## Permanent Fix in NixOS Configuration

Add this to your `/home/notroot/NixOS/hosts/default/configuration.nix`:

```nix
{
  # Force proper DNS configuration
  networking = {
    # Disable DHCP DNS to prevent conflicts
    dhcpcd.extraConfig = "nohook resolv.conf";
    
    # Use specific nameservers
    nameservers = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1" ];
    
    # Fix for Tailscale conflicts
    firewall.checkReversePath = "loose";
    nftables.enable = true;
  };
  
  # Configure systemd-resolved properly
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1" ];
    extraConfig = ''
      DNSOverTLS=yes
      DNS=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
      FallbackDNS=8.8.8.8 8.8.4.4
      Domains=~.
      DNSSEC=allow-downgrade
      DNSStubListener=yes
      Cache=yes
      DNSStubListenerExtra=0.0.0.0
    '';
  };

  # Auto-restart DNS on resume from suspend
  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl restart systemd-resolved
    ${pkgs.systemd}/bin/systemctl restart NetworkManager
  '';
  
  # Create systemd timer to check DNS health
  systemd.timers.dns-health-check = {
    wantedBy = [ "timers.target" ];
    partOf = [ "dns-health-check.service" ];
    timerConfig = {
      OnCalendar = "*:0/5"; # Every 5 minutes
      Persistent = true;
    };
  };
  
  systemd.services.dns-health-check = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dns-health-check" ''
        #\!/bin/sh
        # Check if DNS is working
        if \! ${pkgs.systemd}/bin/resolvectl query google.com >/dev/null 2>&1; then
          echo "DNS failed, restarting services..."
          ${pkgs.systemd}/bin/systemctl restart systemd-resolved
          sleep 2
          ${pkgs.systemd}/bin/systemctl restart NetworkManager
        fi
      '';
    };
  };
}
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

## Root Cause Analysis

The issue is caused by multiple factors:

1. **Tailscale DNS hijacking**: Tailscale tries to manage DNS for MagicDNS features
2. **systemd-resolved conflicts**: Multiple services trying to manage /etc/resolv.conf
3. **NetworkManager interference**: NetworkManager may override DNS settings
4. **DHCP DNS**: Router/DHCP server providing broken or conflicting DNS servers

## Alternative Solutions

### Option 1: Disable Tailscale DNS
```bash
tailscale up --accept-dns=false
```

### Option 2: Use traditional resolv.conf
Disable systemd-resolved and use static DNS:
```nix
services.resolved.enable = false;
networking.resolvConf = pkgs.writeText "resolv.conf" ''
  nameserver 8.8.8.8
  nameserver 8.8.4.4
  nameserver 1.1.1.1
'';
```

### Option 3: Use NetworkManager only
Let NetworkManager handle everything:
```nix
services.resolved.enable = false;
networking.networkmanager.dns = "default";
```

## Monitoring
Check DNS health with:
```bash
# View recent DNS issues
journalctl -u systemd-resolved -n 50

# Monitor DNS queries in real-time
sudo resolvectl monitor

# Check which service is managing DNS
ls -la /etc/resolv.conf
```

## Emergency Fallback
If nothing works, bypass everything:
```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

Note: This is temporary and will be overwritten on reboot.
