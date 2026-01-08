#!/usr/bin/env bash
# Shader Cache Validation Script
# Part of 003-gaming-optimization
# Verifies RADV GPL/NGGC configuration and shader cache status

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Shader Cache Validation ==="
echo ""

# Check RADV_PERFTEST environment variable
echo "1. Checking RADV_PERFTEST configuration..."
if [ -n "${RADV_PERFTEST:-}" ]; then
    echo -e "${GREEN}✓${NC} RADV_PERFTEST is set: $RADV_PERFTEST"

    # Check for GPL
    if [[ "$RADV_PERFTEST" == *"gpl"* ]]; then
        echo -e "${GREEN}  ✓${NC} Graphics Pipeline Library (GPL) enabled"
    else
        echo -e "${YELLOW}  ⚠${NC} Graphics Pipeline Library (GPL) NOT enabled"
    fi

    # Check for NGGC
    if [[ "$RADV_PERFTEST" == *"nggc"* ]]; then
        echo -e "${GREEN}  ✓${NC} Next-Gen Geometry Culling (NGGC) enabled"
    else
        echo -e "${YELLOW}  ⚠${NC} Next-Gen Geometry Culling (NGGC) NOT enabled"
    fi
else
    echo -e "${RED}✗${NC} RADV_PERFTEST is not set"
    echo "  Expected: RADV_PERFTEST=gpl,nggc"
fi
echo ""

# Check Mesa shader cache directory
echo "2. Checking Mesa shader cache directory..."
MESA_CACHE="$HOME/.cache/mesa_shader_cache"
if [ -d "$MESA_CACHE" ]; then
    CACHE_SIZE=$(du -sh "$MESA_CACHE" 2>/dev/null | cut -f1)
    CACHE_FILES=$(find "$MESA_CACHE" -type f 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} Mesa shader cache exists: $MESA_CACHE"
    echo "  Size: $CACHE_SIZE"
    echo "  Files: $CACHE_FILES shader(s)"
else
    echo -e "${YELLOW}⚠${NC} Mesa shader cache directory not found"
    echo "  Expected: $MESA_CACHE"
    echo "  Note: Cache will be created on first game launch"
fi
echo ""

# Check Steam shader cache directory
echo "3. Checking Steam shader cache directory..."
STEAM_CACHE="$HOME/.local/share/Steam/steamapps/shadercache"
if [ -d "$STEAM_CACHE" ]; then
    STEAM_SIZE=$(du -sh "$STEAM_CACHE" 2>/dev/null | cut -f1)
    GAME_CACHES=$(find "$STEAM_CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} Steam shader cache exists: $STEAM_CACHE"
    echo "  Size: $STEAM_SIZE"
    echo "  Games with caches: $GAME_CACHES"
else
    echo -e "${YELLOW}⚠${NC} Steam shader cache directory not found"
    echo "  Expected: $STEAM_CACHE"
    echo "  Note: Requires Steam to be installed and run at least once"
fi
echo ""

# Check Vulkan driver
echo "4. Checking Vulkan driver..."
if command -v vulkaninfo &> /dev/null; then
    DRIVER_NAME=$(vulkaninfo 2>/dev/null | grep -m1 "driverName" | awk '{print $3}')
    DRIVER_INFO=$(vulkaninfo 2>/dev/null | grep -m1 "driverInfo" | awk '{print $3}')

    if [[ "$DRIVER_NAME" == *"radv"* ]] || [[ "$DRIVER_NAME" == *"RADV"* ]]; then
        echo -e "${GREEN}✓${NC} RADV driver active"
        echo "  Driver: $DRIVER_NAME"
        echo "  Version: $DRIVER_INFO"
    else
        echo -e "${YELLOW}⚠${NC} Non-RADV driver detected: $DRIVER_NAME"
        echo "  Expected: RADV for AMD GPUs"
    fi
else
    echo -e "${YELLOW}⚠${NC} vulkaninfo command not found"
    echo "  Install vulkan-tools to verify driver status"
fi
echo ""

# Check VK_EXT_graphics_pipeline_library support
echo "5. Checking VK_EXT_graphics_pipeline_library support..."
if command -v vulkaninfo &> /dev/null; then
    if vulkaninfo 2>/dev/null | grep -q "VK_EXT_graphics_pipeline_library"; then
        echo -e "${GREEN}✓${NC} VK_EXT_graphics_pipeline_library supported"
        echo "  GPL feature can be used for compile-time shader processing"
    else
        echo -e "${RED}✗${NC} VK_EXT_graphics_pipeline_library NOT supported"
        echo "  GPL feature may not work properly"
    fi
else
    echo -e "${YELLOW}⚠${NC} Cannot verify GPL support (vulkaninfo not found)"
fi
echo ""

# Summary
echo "=== Summary ==="
WARNINGS=0

# Count warnings
if [ -z "${RADV_PERFTEST:-}" ]; then ((WARNINGS++)); fi
if [ ! -d "$MESA_CACHE" ]; then ((WARNINGS++)); fi
if [ ! -d "$STEAM_CACHE" ]; then ((WARNINGS++)); fi

if [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Shader cache configuration looks good!${NC}"
else
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s) - see details above${NC}"
fi
echo ""

# Recommendations
echo "=== Recommendations ==="
echo "• Enable shader pre-caching in Steam:"
echo "  Steam → Settings → Shader Pre-Caching → 'Allow background processing of Vulkan shaders'"
echo ""
echo "• Launch a Proton game to populate shader caches"
echo "• Monitor shader compilation with MangoHud frame time graph"
echo ""
