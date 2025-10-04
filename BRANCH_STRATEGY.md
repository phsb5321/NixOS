# Branch Strategy and Workflow

## 🌳 Branch Structure

### **Protected Branches**

#### `main` 🔒
- **Purpose**: Production-ready, stable configuration
- **Protection**: ✅ Requires PR approval before merge
- **Access**: No direct pushes allowed
- **Merges from**: `develop` via Pull Request only

#### `develop` 🔧  
- **Purpose**: Integration branch for new features and shared changes
- **Use case**: Changes that affect multiple hosts or shared modules
- **Merges to**: `main` via Pull Request

### **Host-Specific Branches**

#### `host/default` 🖥️
- **Purpose**: Desktop system specific changes (AMD GPU, gaming setup)
- **Configuration**: `hosts/default/configuration.nix`
- **Use case**: Desktop-only features, AMD GPU tweaks, performance optimizations
- **Merges to**: `develop` via Pull Request

#### `host/laptop` 💻
- **Purpose**: Laptop system specific changes (NVIDIA GPU, mobile optimizations)  
- **Configuration**: `hosts/laptop/configuration.nix`
- **Use case**: Laptop-only features, NVIDIA GPU configs, power management
- **Merges to**: `develop` via Pull Request

## 🔄 Workflow

### For Host-Specific Changes:
1. Switch to appropriate host branch: `git checkout host/default` or `git checkout host/laptop`
2. Make changes specific to that host
3. Test on the target system: `sudo nixos-rebuild switch --flake .#<host>`
4. Commit and push: `git push origin host/<hostname>`
5. Create PR to `develop`

### For Shared Changes:
1. Switch to develop: `git checkout develop`
2. Make changes to shared modules (`modules/`, `hosts/shared/`)
3. Test on both systems if possible
4. Commit and push: `git push origin develop`
5. Create PR to `main`

### For Emergency Fixes:
1. Create hotfix branch from `main`: `git checkout -b hotfix/description main`
2. Make minimal fix
3. Create PR directly to `main`
4. After merge, also merge `main` back to `develop` and host branches

## ✅ Benefits

- **🛡️ Isolation**: Host-specific changes don't break other systems
- **🔒 Protection**: Main branch requires review before changes
- **🔄 Clean History**: Structured approach to configuration management
- **🚀 Safe Deployment**: Test on host branches before merging to main
- **⚡ Parallel Development**: Work on multiple hosts simultaneously

## 📝 Examples

```bash
# Working on desktop-specific gaming features
git checkout host/default
# Edit hosts/default/configuration.nix
sudo nixos-rebuild switch --flake .#default
git commit -m "feat(desktop): add new gaming optimizations"
git push origin host/default
# Create PR: host/default → develop

# Working on laptop power management
git checkout host/laptop  
# Edit hosts/laptop/configuration.nix
sudo nixos-rebuild switch --flake .#laptop
git commit -m "feat(laptop): improve battery life settings"
git push origin host/laptop
# Create PR: host/laptop → develop

# Working on shared modules (fonts, packages, etc.)
git checkout develop
# Edit modules/core/ or modules/packages/
git commit -m "feat(core): add new shared fonts"
git push origin develop
# Create PR: develop → main
```

## 🔧 Current Status

- ✅ Main branch protection enabled (requires PR approval)
- ✅ Host-specific branches created and pushed
- ✅ Clean module structure (removed hardware abstraction, flatpak, etc.)
- ✅ Simplified GPU configurations per host
