#!/usr/bin/env bash
# Script to enable essential GNOME extensions for laptop configuration
# Run this after logging into GNOME to activate the extensions

set -e

echo "🔧 GNOME Extensions Activation Script for Laptop"
echo "=============================================="

# Check if we're in a GNOME session
if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
    echo "❌ This script requires a GNOME session. Current desktop: $XDG_CURRENT_DESKTOP"
    exit 1
fi

# Check if gnome-extensions command is available
if ! command -v gnome-extensions &> /dev/null; then
    echo "❌ gnome-extensions command not found. Please install gnome-shell-extensions."
    exit 1
fi

echo "📋 Enabling core extensions..."

# Core requested extensions
echo "  🎯 Enabling Caffeine..."
gnome-extensions enable caffeine@patapon.info || echo "    ⚠️  Caffeine not found"

echo "  📊 Enabling Vitals..."
gnome-extensions enable Vitals@CoreCoding.com || echo "    ⚠️  Vitals not found"

echo "  🪟 Enabling Forge (tiling)..."
gnome-extensions enable forge@jmmaranan.com || echo "    ⚠️  Forge not found"

echo "  📋 Enabling Arc Menu..."
gnome-extensions enable arc-menu@linxgem33.com || echo "    ⚠️  Arc Menu not found"

echo "  🔍 Enabling Fuzzy App Search..."
gnome-extensions enable fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com || echo "    ⚠️  Fuzzy App Search not found"

echo "  🚀 Enabling Launch New Instance..."
gnome-extensions enable launch-new-instance@gnome-shell-extensions.gcampax.github.com || echo "    ⚠️  Launch New Instance not found"

echo "  🎯 Enabling Auto Move Windows..."
gnome-extensions enable auto-move-windows@gnome-shell-extensions.gcampax.github.com || echo "    ⚠️  Auto Move Windows not found"

echo "  📋 Enabling Clipboard Indicator..."
gnome-extensions enable clipboard-indicator@tudmotu.com || echo "    ⚠️  Clipboard Indicator not found"

echo "  🐱 Enabling RunCat (the running cat!)..."
gnome-extensions enable runcat@kolesnikov.se || echo "    ⚠️  RunCat not found"

echo ""
echo "🛠️  Enabling productivity extensions..."

echo "  🎨 Enabling Dash to Dock..."
gnome-extensions enable dash-to-dock@micxgx.gmail.com || echo "    ⚠️  Dash to Dock not found"

echo "  📱 Enabling GSConnect..."
gnome-extensions enable gsconnect@andyholmes.github.io || echo "    ⚠️  GSConnect not found"

echo "  📊 Enabling TopHat..."
gnome-extensions enable tophat@fflewddur.github.io || echo "    ⚠️  TopHat not found"

echo "  🔊 Enabling Sound Output Device Chooser..."
gnome-extensions enable sound-output-device-chooser@kgshank.net || echo "    ⚠️  Sound Output Device Chooser not found"

echo "  🔋 Enabling Battery Time..."
gnome-extensions enable battery-time@typeof.pw || echo "    ⚠️  Battery Time not found"

echo "  🎨 Enabling User Themes..."
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || echo "    ⚠️  User Themes not found"

echo "  ⚙️  Enabling Just Perfection..."
gnome-extensions enable just-perfection-desktop@just-perfection || echo "    ⚠️  Just Perfection not found"

echo "  🖱️  Enabling Panel Workspace Scroll..."
gnome-extensions enable panel-workspace-scroll@polymorphicshade.github.io || echo "    ⚠️  Panel Workspace Scroll not found"

echo ""
echo "✅ Extension activation complete!"
echo ""
echo "📝 Notes:"
echo "  • Some extensions may require logout/login to fully activate"
echo "  • Use 'Extension Manager' app to configure individual extensions"
echo "  • Use 'GNOME Tweaks' for basic extension management"
echo "  • RunCat (the cat) will appear in your top bar and run faster with higher CPU usage!"
echo ""
echo "🔧 To configure extensions:"
echo "  • Caffeine: Click the coffee cup icon in top bar"
echo "  • Vitals: Configure in Extension Manager"
echo "  • Forge: Use Super+W to toggle tiling mode"
echo "  • Arc Menu: Click the applications button (replaces Activities)"
echo "  • Clipboard Indicator: Access via top bar clipboard icon"
echo ""
echo "🐱 Fun fact: The RunCat shows CPU usage - the faster it runs, the higher your CPU usage!"
