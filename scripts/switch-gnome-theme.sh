#!/usr/bin/env bash
# GNOME Theme Switcher Script
# Allows easy switching between different beautiful themes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Theme definitions
declare -A GTK_THEMES=(
    ["1"]="Arc-Dark"
    ["2"]="Orchis-Dark"
    ["3"]="WhiteSur-Dark"
    ["4"]="Nordic-darker"
    ["5"]="Graphite-dark"
    ["6"]="Catppuccin-Mocha"
    ["7"]="Yaru-dark"
    ["8"]="Materia-dark"
    ["9"]="Pop-dark"
    ["10"]="Adwaita-dark"
)

declare -A ICON_THEMES=(
    ["1"]="Papirus-Dark"
    ["2"]="Tela-dark"
    ["3"]="WhiteSur-dark"
    ["4"]="Nordzy-dark"
    ["5"]="Fluent-dark"
    ["6"]="Numix"
    ["7"]="Adwaita"
)

declare -A CURSOR_THEMES=(
    ["1"]="Bibata-Modern-Ice"
    ["2"]="Nordzy-cursors"
    ["3"]="Catppuccin-Mocha-Dark"
    ["4"]="Volantes"
    ["5"]="Adwaita"
)

declare -A SHELL_THEMES=(
    ["1"]="Arc-Dark"
    ["2"]="Orchis-Dark"
    ["3"]="WhiteSur-Dark"
    ["4"]="Nordic-darker"
    ["5"]="Graphite-dark"
    ["6"]="Yaru-dark"
    ["7"]="Materia-dark"
    ["8"]="Pop-dark"
    ["9"]="Default"
)

# Theme descriptions
declare -A GTK_DESCRIPTIONS=(
    ["1"]="🎨 Arc-Dark - Modern flat design with subtle gradients"
    ["2"]="🍎 Orchis-Dark - macOS-like elegance with rounded corners"
    ["3"]="💎 WhiteSur-Dark - Premium macOS Big Sur inspired theme"
    ["4"]="❄️ Nordic-darker - Minimalist Nordic design philosophy"
    ["5"]="📱 Graphite-dark - Google Material Design inspired"
    ["6"]="🌸 Catppuccin-Mocha - Soothing pastel colors"
    ["7"]="🧡 Yaru-dark - Ubuntu's modern design language"
    ["8"]="🔷 Materia-dark - Material Design with personality"
    ["9"]="🎵 Pop-dark - System76's vibrant design"
    ["10"]="⚫ Adwaita-dark - GNOME's default modern theme"
)

declare -A ICON_DESCRIPTIONS=(
    ["1"]="📦 Papirus-Dark - Material Design inspired icons"
    ["2"]="🟢 Tela-dark - Rounded modern icons with vibrant colors"
    ["3"]="🍎 WhiteSur-dark - macOS Big Sur style icons"
    ["4"]="❄️ Nordzy-dark - Nordic-themed minimalist icons"
    ["5"]="💠 Fluent-dark - Microsoft Fluent Design icons"
    ["6"]="🔶 Numix - Flat circular icons with subtle shadows"
    ["7"]="⚫ Adwaita - GNOME's default icon set"
)

declare -A CURSOR_DESCRIPTIONS=(
    ["1"]="🖱️ Bibata-Modern-Ice - Modern animated cursors"
    ["2"]="❄️ Nordzy-cursors - Nordic style minimalist cursors"
    ["3"]="🌸 Catppuccin-Mocha-Dark - Pastel themed cursors"
    ["4"]="✨ Volantes - Elegant and sophisticated cursors"
    ["5"]="⚫ Adwaita - GNOME's default cursor theme"
)

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a GNOME session
check_gnome_session() {
    if [ "${XDG_CURRENT_DESKTOP:-}" != "GNOME" ]; then
        log_error "Not running in a GNOME session. Current desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
        exit 1
    fi
}

# Display current theme settings
show_current_themes() {
    echo -e "${CYAN}Current Theme Configuration:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    local icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    local cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
    local shell_theme=$(gsettings get org.gnome.shell.extensions.user-theme name 2>/dev/null | tr -d "'")
    local color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
    local accent_color=$(gsettings get org.gnome.desktop.interface accent-color 2>/dev/null | tr -d "'")

    echo -e "🎨 GTK Theme:     ${GREEN}${gtk_theme}${NC}"
    echo -e "🎭 Icon Theme:    ${GREEN}${icon_theme}${NC}"
    echo -e "🖱️  Cursor Theme:  ${GREEN}${cursor_theme}${NC}"
    echo -e "🐚 Shell Theme:   ${GREEN}${shell_theme:-Default}${NC}"
    echo -e "🌓 Color Scheme:  ${GREEN}${color_scheme}${NC}"
    echo -e "🌈 Accent Color:  ${GREEN}${accent_color}${NC}"
    echo ""
}

# Display theme menu
show_theme_menu() {
    local theme_type="$1"
    local -n themes_ref="$2"
    local -n descriptions_ref="$3"

    echo -e "${PURPLE}Available ${theme_type} Themes:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for key in $(printf '%s\n' "${!themes_ref[@]}" | sort -n); do
        echo -e "${key}. ${descriptions_ref[$key]}"
    done
    echo ""
}

# Apply GTK theme
apply_gtk_theme() {
    local choice="$1"
    local theme="${GTK_THEMES[$choice]}"

    log_info "Applying GTK theme: $theme"
    gsettings set org.gnome.desktop.interface gtk-theme "$theme"
    gsettings set org.gnome.desktop.wm.preferences theme "$theme"

    # Update environment variable for new applications
    export GTK_THEME="$theme"

    log_success "GTK theme applied: $theme"
}

# Apply icon theme
apply_icon_theme() {
    local choice="$1"
    local theme="${ICON_THEMES[$choice]}"

    log_info "Applying icon theme: $theme"
    gsettings set org.gnome.desktop.interface icon-theme "$theme"

    log_success "Icon theme applied: $theme"
}

# Apply cursor theme
apply_cursor_theme() {
    local choice="$1"
    local theme="${CURSOR_THEMES[$choice]}"

    log_info "Applying cursor theme: $theme"
    gsettings set org.gnome.desktop.interface cursor-theme "$theme"

    # Update environment variable
    export XCURSOR_THEME="$theme"

    log_success "Cursor theme applied: $theme"
}

# Apply shell theme
apply_shell_theme() {
    local choice="$1"
    local theme="${SHELL_THEMES[$choice]}"

    log_info "Applying shell theme: $theme"

    # Check if user-theme extension is enabled
    if ! gnome-extensions list --enabled | grep -q "user-theme"; then
        log_warning "User Theme extension is not enabled. Enabling it now..."
        gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || {
            log_error "Failed to enable User Theme extension. Please enable it manually."
            return 1
        }
        sleep 2
    fi

    if [ "$theme" = "Default" ]; then
        gsettings reset org.gnome.shell.extensions.user-theme name
    else
        gsettings set org.gnome.shell.extensions.user-theme name "$theme"
    fi

    log_success "Shell theme applied: $theme"
    log_info "You may need to restart GNOME Shell (Alt+F2, type 'r', press Enter) to see shell theme changes"
}

# Apply preset theme combinations
apply_preset() {
    local preset="$1"

    case "$preset" in
        1) # Arc Theme Suite
            log_info "Applying Arc Theme Suite (Modern & Clean)"
            apply_gtk_theme "1"
            apply_icon_theme "1"
            apply_cursor_theme "1"
            apply_shell_theme "1"
            ;;
        2) # macOS-like Theme Suite
            log_info "Applying macOS-like Theme Suite (Elegant & Polished)"
            apply_gtk_theme "3"
            apply_icon_theme "3"
            apply_cursor_theme "4"
            apply_shell_theme "3"
            ;;
        3) # Nordic Theme Suite
            log_info "Applying Nordic Theme Suite (Minimalist & Clean)"
            apply_gtk_theme "4"
            apply_icon_theme "4"
            apply_cursor_theme "2"
            apply_shell_theme "4"
            ;;
        4) # Catppuccin Theme Suite
            log_info "Applying Catppuccin Theme Suite (Pastel & Cozy)"
            apply_gtk_theme "6"
            apply_icon_theme "1"
            apply_cursor_theme "3"
            apply_shell_theme "5"
            ;;
        5) # Material Design Suite
            log_info "Applying Material Design Suite (Modern & Vibrant)"
            apply_gtk_theme "5"
            apply_icon_theme "1"
            apply_cursor_theme "1"
            apply_shell_theme "5"
            ;;
        *)
            log_error "Invalid preset choice"
            return 1
            ;;
    esac

    log_success "Preset theme applied successfully!"
}

# Change accent color
change_accent_color() {
    echo -e "${PURPLE}Available Accent Colors:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. 🔵 Blue (Default)"
    echo "2. 🟢 Green"
    echo "3. 🟡 Yellow"
    echo "4. 🟠 Orange"
    echo "5. 🔴 Red"
    echo "6. 🟣 Purple"
    echo "7. 🩷 Pink"
    echo "8. ⚫ Slate"
    echo ""

    read -p "Choose accent color (1-8): " accent_choice

    case "$accent_choice" in
        1) gsettings set org.gnome.desktop.interface accent-color 'blue' ;;
        2) gsettings set org.gnome.desktop.interface accent-color 'green' ;;
        3) gsettings set org.gnome.desktop.interface accent-color 'yellow' ;;
        4) gsettings set org.gnome.desktop.interface accent-color 'orange' ;;
        5) gsettings set org.gnome.desktop.interface accent-color 'red' ;;
        6) gsettings set org.gnome.desktop.interface accent-color 'purple' ;;
        7) gsettings set org.gnome.desktop.interface accent-color 'pink' ;;
        8) gsettings set org.gnome.desktop.interface accent-color 'slate' ;;
        *) log_error "Invalid choice"; return 1 ;;
    esac

    log_success "Accent color changed successfully!"
}

# Main menu
show_main_menu() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           🎨 GNOME Theme Switcher 🎨                        ║"
    echo "║                     Make your GNOME desktop beautiful!                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    show_current_themes

    echo -e "${CYAN}What would you like to do?${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. 🎨 Change GTK Theme (Application theme)"
    echo "2. 🎭 Change Icon Theme"
    echo "3. 🖱️  Change Cursor Theme"
    echo "4. 🐚 Change Shell Theme (GNOME Shell appearance)"
    echo "5. 🌈 Change Accent Color"
    echo ""
    echo "6. ✨ Apply Theme Preset (Complete theme suites)"
    echo "7. 🔄 Reset to Defaults"
    echo "8. 📋 Show Available Themes"
    echo "9. 🚪 Exit"
    echo ""
}

# Show available themes
show_available_themes() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           📋 Available Themes                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    show_theme_menu "GTK" GTK_THEMES GTK_DESCRIPTIONS
    show_theme_menu "Icon" ICON_THEMES ICON_DESCRIPTIONS
    show_theme_menu "Cursor" CURSOR_THEMES CURSOR_DESCRIPTIONS

    echo ""
    read -p "Press Enter to return to main menu..."
}

# Show preset themes
show_preset_menu() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           ✨ Theme Presets                                  ║"
    echo "║                    Complete coordinated theme suites                        ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${PURPLE}Available Theme Presets:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. 🎨 Arc Suite - Modern flat design with Papirus icons"
    echo "2. 🍎 macOS Suite - WhiteSur theme with macOS-style icons"
    echo "3. ❄️ Nordic Suite - Minimalist Nordic design philosophy"
    echo "4. 🌸 Catppuccin Suite - Soothing pastel colors"
    echo "5. 📱 Material Suite - Google Material Design inspired"
    echo "6. 🔙 Back to main menu"
    echo ""

    read -p "Choose a preset (1-6): " preset_choice

    if [ "$preset_choice" = "6" ]; then
        return 0
    elif [[ "$preset_choice" =~ ^[1-5]$ ]]; then
        apply_preset "$preset_choice"
        echo ""
        read -p "Press Enter to continue..."
    else
        log_error "Invalid choice"
        read -p "Press Enter to continue..."
    fi
}

# Reset to defaults
reset_to_defaults() {
    log_info "Resetting to default themes..."

    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface accent-color 'blue'
    gsettings reset org.gnome.shell.extensions.user-theme name

    log_success "Reset to default themes completed!"
    read -p "Press Enter to continue..."
}

# Main execution loop
main() {
    check_gnome_session

    while true; do
        show_main_menu
        read -p "Enter your choice (1-9): " choice

        case "$choice" in
            1) # GTK Theme
                clear
                show_theme_menu "GTK" GTK_THEMES GTK_DESCRIPTIONS
                read -p "Choose GTK theme (1-${#GTK_THEMES[@]}): " gtk_choice
                if [[ "$gtk_choice" =~ ^[1-9]$|^10$ ]] && [ -n "${GTK_THEMES[$gtk_choice]:-}" ]; then
                    apply_gtk_theme "$gtk_choice"
                    read -p "Press Enter to continue..."
                else
                    log_error "Invalid choice"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) # Icon Theme
                clear
                show_theme_menu "Icon" ICON_THEMES ICON_DESCRIPTIONS
                read -p "Choose icon theme (1-${#ICON_THEMES[@]}): " icon_choice
                if [[ "$icon_choice" =~ ^[1-7]$ ]] && [ -n "${ICON_THEMES[$icon_choice]:-}" ]; then
                    apply_icon_theme "$icon_choice"
                    read -p "Press Enter to continue..."
                else
                    log_error "Invalid choice"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) # Cursor Theme
                clear
                show_theme_menu "Cursor" CURSOR_THEMES CURSOR_DESCRIPTIONS
                read -p "Choose cursor theme (1-${#CURSOR_THEMES[@]}): " cursor_choice
                if [[ "$cursor_choice" =~ ^[1-5]$ ]] && [ -n "${CURSOR_THEMES[$cursor_choice]:-}" ]; then
                    apply_cursor_theme "$cursor_choice"
                    read -p "Press Enter to continue..."
                else
                    log_error "Invalid choice"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) # Shell Theme
                clear
                show_theme_menu "Shell" SHELL_THEMES GTK_DESCRIPTIONS
                read -p "Choose shell theme (1-${#SHELL_THEMES[@]}): " shell_choice
                if [[ "$shell_choice" =~ ^[1-9]$ ]] && [ -n "${SHELL_THEMES[$shell_choice]:-}" ]; then
                    apply_shell_theme "$shell_choice"
                    read -p "Press Enter to continue..."
                else
                    log_error "Invalid choice"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5) # Accent Color
                clear
                change_accent_color
                read -p "Press Enter to continue..."
                ;;
            6) # Presets
                show_preset_menu
                ;;
            7) # Reset
                clear
                reset_to_defaults
                ;;
            8) # Show available themes
                show_available_themes
                ;;
            9) # Exit
                echo ""
                log_success "Thanks for using GNOME Theme Switcher! 🎨"
                echo ""
                break
                ;;
            *)
                log_error "Invalid choice. Please enter a number between 1-9."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the script
main "$@"
