#!/usr/bin/env bash
# Gaming CPU Optimization Validation Script
# Part of 003-gaming-optimization
# Verifies Intel p-state disable and GameMode configuration

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Gaming CPU Optimization Validation ==="
echo ""

# Check if Intel p-state is disabled via kernel parameters
echo "1. Checking Intel p-state driver status..."
KERNEL_PARAMS=$(cat /proc/cmdline)
if [[ "$KERNEL_PARAMS" == *"intel_pstate=disable"* ]]; then
    echo -e "${GREEN}✓${NC} intel_pstate=disable kernel parameter is set"
else
    echo -e "${RED}✗${NC} intel_pstate=disable kernel parameter NOT found"
    echo "  Current kernel parameters: $KERNEL_PARAMS"
fi
echo ""

# Check CPU frequency scaling driver
echo "2. Checking CPU frequency scaling driver..."
CPU_DRIVER=""
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver; do
    if [ -f "$cpu" ]; then
        CPU_DRIVER=$(cat "$cpu" | head -1)
        break
    fi
done

if [ -n "$CPU_DRIVER" ]; then
    if [[ "$CPU_DRIVER" == "acpi-cpufreq" ]]; then
        echo -e "${GREEN}✓${NC} CPU driver: $CPU_DRIVER (correct - intel_pstate is disabled)"
    elif [[ "$CPU_DRIVER" == "intel_pstate" ]]; then
        echo -e "${RED}✗${NC} CPU driver: $CPU_DRIVER (should be acpi-cpufreq when disabled)"
        echo "  Kernel parameter may not be applied - check boot configuration"
    else
        echo -e "${YELLOW}⚠${NC} CPU driver: $CPU_DRIVER (unexpected driver)"
    fi
else
    echo -e "${RED}✗${NC} Could not detect CPU frequency scaling driver"
    echo "  Check if cpufreq is enabled in kernel"
fi
echo ""

# Check CPU governor
echo "3. Checking CPU governor..."
CPU_GOVERNOR=""
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
        CPU_GOVERNOR=$(cat "$cpu" | head -1)
        break
    fi
done

if [ -n "$CPU_GOVERNOR" ]; then
    if [[ "$CPU_GOVERNOR" == "performance" ]]; then
        echo -e "${GREEN}✓${NC} CPU governor: $CPU_GOVERNOR (optimal for gaming)"
    elif [[ "$CPU_GOVERNOR" == "schedutil" ]] || [[ "$CPU_GOVERNOR" == "ondemand" ]]; then
        echo -e "${YELLOW}⚠${NC} CPU governor: $CPU_GOVERNOR (GameMode will switch to performance)"
    else
        echo -e "${YELLOW}⚠${NC} CPU governor: $CPU_GOVERNOR"
    fi

    # Show all CPU governors
    GOVERNORS=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "N/A")
    echo "  Available governors: $GOVERNORS"
else
    echo -e "${RED}✗${NC} Could not detect CPU governor"
fi
echo ""

# Check GameMode daemon
echo "4. Checking GameMode daemon..."
if command -v gamemoded &> /dev/null; then
    echo -e "${GREEN}✓${NC} GameMode daemon (gamemoded) is installed"

    # Check if GameMode service exists
    if systemctl --user list-unit-files | grep -q "gamemoded.service"; then
        echo -e "${GREEN}  ✓${NC} GameMode service is installed"

        # Check if GameMode is running
        if systemctl --user is-active gamemoded.service &> /dev/null; then
            echo -e "${GREEN}  ✓${NC} GameMode daemon is running"
        else
            echo -e "${YELLOW}  ⚠${NC} GameMode daemon is not running (will start when game launches)"
        fi
    else
        echo -e "${YELLOW}  ⚠${NC} GameMode service not found in systemd"
    fi
else
    echo -e "${RED}✗${NC} GameMode daemon (gamemoded) not found"
    echo "  Install gamemode package to enable CPU optimizations"
fi
echo ""

# Check GameMode configuration
echo "5. Checking GameMode configuration..."
GAMEMODE_CONFIG="/etc/gamemode.ini"
if [ -f "$GAMEMODE_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} GameMode configuration exists: $GAMEMODE_CONFIG"

    # Check for renice configuration
    if grep -q "^renice" "$GAMEMODE_CONFIG" 2>/dev/null; then
        RENICE_VAL=$(grep "^renice" "$GAMEMODE_CONFIG" | head -1 | cut -d'=' -f2 | tr -d ' ')
        echo -e "${GREEN}  ✓${NC} Process renice enabled (value: $RENICE_VAL)"
    else
        echo -e "${YELLOW}  ⚠${NC} Process renice not configured"
    fi

    # Check for soft realtime
    if grep -q "^softrealtime" "$GAMEMODE_CONFIG" 2>/dev/null; then
        REALTIME_VAL=$(grep "^softrealtime" "$GAMEMODE_CONFIG" | head -1 | cut -d'=' -f2 | tr -d ' ')
        echo -e "${GREEN}  ✓${NC} Soft realtime scheduling (value: $REALTIME_VAL)"
    else
        echo -e "${YELLOW}  ⚠${NC} Soft realtime not configured"
    fi

    # Check for inhibit screensaver
    if grep -q "^inhibit_screensaver" "$GAMEMODE_CONFIG" 2>/dev/null; then
        INHIBIT_VAL=$(grep "^inhibit_screensaver" "$GAMEMODE_CONFIG" | head -1 | cut -d'=' -f2 | tr -d ' ')
        echo -e "${GREEN}  ✓${NC} Screensaver inhibit (value: $INHIBIT_VAL)"
    else
        echo -e "${YELLOW}  ⚠${NC} Screensaver inhibit not configured"
    fi
else
    echo -e "${YELLOW}⚠${NC} GameMode configuration file not found"
    echo "  Expected: $GAMEMODE_CONFIG"
    echo "  GameMode will use default settings"
fi
echo ""

# Check CPU frequency range
echo "6. Checking CPU frequency range..."
MIN_FREQ=""
MAX_FREQ=""
CUR_FREQ=""

for cpu in /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq; do
    if [ -f "$cpu" ]; then
        MIN_FREQ=$(cat "$cpu")
        MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
        CUR_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        break
    fi
done

if [ -n "$MIN_FREQ" ]; then
    # Convert from kHz to MHz
    MIN_MHZ=$((MIN_FREQ / 1000))
    MAX_MHZ=$((MAX_FREQ / 1000))
    CUR_MHZ=$((CUR_FREQ / 1000))

    echo -e "${GREEN}✓${NC} CPU frequency information:"
    echo "  Minimum: ${MIN_MHZ} MHz"
    echo "  Maximum: ${MAX_MHZ} MHz"
    echo "  Current: ${CUR_MHZ} MHz"

    # Check if current is close to max (within 10%)
    THRESHOLD=$((MAX_MHZ * 90 / 100))
    if [ $CUR_MHZ -ge $THRESHOLD ]; then
        echo -e "${GREEN}  ✓${NC} CPU is running at high frequency"
    else
        echo -e "${YELLOW}  ⚠${NC} CPU frequency is below 90% of maximum"
        echo "  This is normal when idle - GameMode will boost during gaming"
    fi
else
    echo -e "${YELLOW}⚠${NC} Could not read CPU frequency information"
fi
echo ""

# Summary
echo "=== Summary ==="
WARNINGS=0
CRITICAL=0

# Count issues
if [[ "$KERNEL_PARAMS" != *"intel_pstate=disable"* ]]; then ((CRITICAL++)); fi
if [[ "$CPU_DRIVER" == "intel_pstate" ]]; then ((CRITICAL++)); fi
if ! command -v gamemoded &> /dev/null; then ((CRITICAL++)); fi
if [ ! -f "$GAMEMODE_CONFIG" ]; then ((WARNINGS++)); fi

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ CPU gaming optimization configuration looks good!${NC}"
elif [ $CRITICAL -eq 0 ]; then
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s) - configuration will work but may not be optimal${NC}"
else
    echo -e "${RED}✗ Found $CRITICAL critical issue(s) - please review configuration${NC}"
fi
echo ""

# Recommendations
echo "=== Recommendations ==="
echo "• GameMode will automatically:"
echo "  - Switch CPU governor to 'performance' mode"
echo "  - Increase game process priority (renice)"
echo "  - Apply soft real-time scheduling"
echo "  - Prevent screensaver from activating"
echo ""
echo "• To test GameMode manually:"
echo "  gamemoderun <game-command>"
echo ""
echo "• Monitor GameMode status while gaming:"
echo "  gamemoded -s"
echo ""
