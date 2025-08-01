# Branch Strategy and Workflow

## 🌳 Branch Structure

### **Protected Branches**

#### `main` 🔒
- **Purpose**: Production-ready, stable configuration
- **Protection**: 🛡️ **MAXIMUM SECURITY**
  - ✅ Requires PR approval before merge (1 reviewer minimum)
  - ✅ Requires code owner review (@phsb5321)
  - ✅ Requires approval of most recent push
  - ✅ Linear history enforced (no merge commits)
  - ✅ Conversation resolution required
  - ✅ Admin enforcement enabled
  - ❌ No force pushes allowed
  - ❌ No deletions allowed
- **Access**: No direct pushes allowed - **ZERO EXCEPTIONS**
- **Merges from**: `develop` via Pull Request only

#### `develop` 🔧  
- **Purpose**: Integration branch for new features and shared changes
- **Protection**: 🛡️ **HIGH SECURITY**
  - ✅ Requires PR approval before merge (1 reviewer minimum)
  - ✅ Conversation resolution required
  - ✅ Admin enforcement enabled
  - ❌ No force pushes allowed
  - ❌ No deletions allowed
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

- ✅ **Main branch protection enabled**: Maximum security with code owner review
- ✅ **Develop branch protection enabled**: High security with PR approval
- ✅ **CODEOWNERS file created**: Ensures @phsb5321 reviews all changes
- ✅ Host-specific branches created and pushed
- ✅ Clean module structure (removed hardware abstraction, flatpak, etc.)
- ✅ Simplified GPU configurations per host
- ✅ **GNOME extensions shared between hosts**: 21 comprehensive extensions in shared config

## ⚠️ **IMPORTANT: Workflow Compliance Required**

**The repository now enforces strict branch protection. You MUST:**

1. **Never push directly** to `main` or `develop` branches
2. **Always create feature branches** for any changes
3. **Use Pull Requests** for all merges to protected branches
4. **Get approval** from code owner (@phsb5321) for main branch changes
5. **Resolve all conversations** before merging
6. **Follow linear history** on main branch (no merge commits)
