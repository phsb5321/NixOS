---
applyTo: '**'
description: "Comprehensive system performance analysis and optimization"
---

# System Performance Optimization

Perform a comprehensive performance analysis and optimization workflow:

## Performance Analysis Phase
1. **Resource Monitoring**: 
   - Check current CPU, memory, and I/O usage with `htop`, `iotop`
   - Analyze disk space with `df -h` and `du -sh`
   - Review system journal for errors: `journalctl -p err -b`

2. **Bottleneck Identification**:
   - Profile running processes and resource consumption
   - Identify I/O wait issues and memory pressure
   - Check for swap usage and filesystem performance

3. **NixOS-Specific Analysis**:
   - Nix store size and optimization opportunities
   - Generation cleanup potential
   - Service resource consumption

## Optimization Implementation
1. **Kernel Parameters**:
   - Analyze current sysctl settings
   - Recommend gaming/desktop optimizations
   - Suggest memory management improvements

2. **Filesystem Optimizations**:
   - Check mount options (noatime, compression)
   - SSD-specific optimizations
   - Filesystem fragmentation analysis

3. **System Configuration**:
   - CPU governor optimization
   - Power management settings
   - Service optimization opportunities

## Performance Validation
1. **Benchmark Before/After**:
   - System responsiveness tests
   - Boot time measurement
   - Application launch speed

2. **Monitoring Setup**:
   - Configure performance monitoring
   - Set up alerting for resource issues
   - Create performance baselines

## Arguments Support
- `$ARGUMENTS` can specify focus areas: `cpu`, `memory`, `io`, `gaming`, `power`
- Default: comprehensive analysis of all areas

## Example Usage
```bash
# Full system optimization
/optimize-performance

# Focus on gaming performance
/optimize-performance gaming

# I/O specific optimization
/optimize-performance io
```

Execute this workflow autonomously, providing performance metrics and specific recommendations.