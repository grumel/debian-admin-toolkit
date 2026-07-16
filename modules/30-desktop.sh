#!/usr/bin/env bash
# DAT-MODULE
# Id: desktop
# Name: Desktop
# Description: Desktop environment, themes, fonts, cursor, animations, dark mode
# Entry: module_desktop_main
#
# modules/30-desktop.sh - Desktop environment inspection and tweaks
# (roadmap phase 4).
#
# This module operates on the *current user's* session settings, never on
# system-wide configuration. Changes (dark mode, animations) are applied only
# when the operator explicitly selects them and are fully reversible from the
# same menu. Supported backends: GNOME (gsettings), KDE Plasma and XFCE are
# detected and reported; unknown environments still get read-only info.

# --- Environment detection ----------------------------------------------------

# desk_detect - Print a normalized desktop id: gnome | kde | xfce | other.
desk_detect() {
    local xdg="${XDG_CURRENT_DESKTOP,,}"

    case "${xdg}" in
        *gnome*|*unity*|*cinnamon*) printf 'gnome' ;;
        *kde*|*plasma*)             printf 'kde' ;;
        *xfce*)                     printf 'xfce' ;;
        *)
            # Fall back to running processes when the variable is unset.
            if pgrep -x gnome-shell >/dev/null 2>&1; then printf 'gnome'
            elif pgrep -x plasmashell >/dev/null 2>&1; then printf 'kde'
            elif pgrep -x xfwm4 >/dev/null 2>&1; then printf 'xfce'
            else printf 'other'
            fi
            ;;
    esac
}

# desk_info - Read-only overview of the current desktop session.
desk_info() {
    printf 'Detected environment: %s\n' "$(desk_detect)"
    printf 'XDG_CURRENT_DESKTOP:  %s\n' "${XDG_CURRENT_DESKTOP:-unset}"
    printf 'XDG_SESSION_TYPE:     %s\n' "${XDG_SESSION_TYPE:-unset}"
    printf 'XDG_SESSION_DESKTOP:  %s\n' "${XDG_SESSION_DESKTOP:-unset}"
    printf 'Display server:       %s\n' "${WAYLAND_DISPLAY:+Wayland}${DISPLAY:+ X11(${DISPLAY})}"

    if has_cmd gnome-shell; then
        printf 'GNOME Shell version:  %s\n' "$(gnome-shell --version 2>/dev/null)"
    fi
    if has_cmd plasmashell; then
        printf 'Plasma version:       %s\n' "$(plasmashell --version 2>/dev/null)"
    fi
    if has_cmd xfce4-session; then
        printf 'XFCE session:         %s\n' "$(xfce4-session --version 2>/dev/null | head -n 1)"
    fi
}

# --- Themes, fonts, cursor ----------------------------------------------------

# desk_appearance - Report current theme/font/cursor settings where possible.
desk_appearance() {
    local desktop
    desktop="$(desk_detect)"

    case "${desktop}" in
        gnome)
            if has_cmd gsettings; then
                printf '== GNOME interface settings ==\n'
                local key
                for key in gtk-theme icon-theme cursor-theme cursor-size \
                           font-name document-font-name monospace-font-name \
                           color-scheme enable-animations; do
                    printf '%-20s %s\n' "${key}:" \
                        "$(gsettings get org.gnome.desktop.interface "${key}" 2>/dev/null || printf 'n/a')"
                done
            else
                printf 'gsettings is not available.\n'
            fi
            ;;
        xfce)
            if has_cmd xfconf-query; then
                printf '== XFCE appearance ==\n'
                printf 'Theme:       %s\n' "$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null || printf 'n/a')"
                printf 'Icon theme:  %s\n' "$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null || printf 'n/a')"
                printf 'Font:        %s\n' "$(xfconf-query -c xsettings -p /Gtk/FontName 2>/dev/null || printf 'n/a')"
            else
                printf 'xfconf-query is not available.\n'
            fi
            ;;
        kde)
            printf 'KDE Plasma detected.\n'
            printf 'Look & feel is managed via System Settings or "plasma-apply-*"\n'
            printf 'tools (plasma-apply-colorscheme, plasma-apply-lookandfeel).\n'
            has_cmd plasma-apply-colorscheme && \
                printf '\nplasma-apply-colorscheme is available.\n'
            ;;
        *)
            printf 'No supported desktop environment detected.\n'
            printf 'Installed GTK theme directories:\n'
            if [[ -d /usr/share/themes ]]; then
                find /usr/share/themes -maxdepth 1 -mindepth 1 -type d \
                    -printf '  %f\n' 2>/dev/null | sort | head -n 20
            else
                printf '  none\n'
            fi
            ;;
    esac
}

# --- Dark mode ----------------------------------------------------------------

# _gnome_color_scheme <prefer-dark|default> - Set GNOME color scheme and,
# for GTK3 apps, a matching dark GTK theme heuristic is left to the user.
_gnome_set_dark() {
    local mode="$1"  # dark | light
    if ! has_cmd gsettings; then
        ui_msgbox "Dark mode" "gsettings is not available; cannot change GNOME settings."
        return 0
    fi

    if [[ "${mode}" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'default'
    fi
    ui_msgbox "Dark mode" "GNOME color scheme set to: ${mode}."
}

# desk_dark_mode - Toggle dark/light mode for the supported environment.
desk_dark_mode() {
    local desktop
    desktop="$(desk_detect)"

    case "${desktop}" in
        gnome)
            local choice
            choice="$(ui_menu "Dark mode" "Choose the GNOME color scheme:" \
                "dark"  "Prefer dark" \
                "light" "Default (light)" \
                "back"  "Cancel")" || return 0
            case "${choice}" in
                dark)  _gnome_set_dark dark ;;
                light) _gnome_set_dark light ;;
            esac
            ;;
        kde)
            if has_cmd plasma-apply-colorscheme; then
                ui_show_cmd "Dark mode (KDE)" plasma-apply-colorscheme BreezeDark
            else
                ui_msgbox "Dark mode" "Use System Settings > Colors, or install the Plasma tools."
            fi
            ;;
        *)
            ui_msgbox "Dark mode" "Automatic dark mode is only supported on GNOME (and KDE with plasma tools) so far."
            ;;
    esac
}

# --- Animations ---------------------------------------------------------------

# desk_animations - Enable or disable GNOME animations (affects perceived speed).
desk_animations() {
    if [[ "$(desk_detect)" != "gnome" ]] || ! has_cmd gsettings; then
        ui_msgbox "Animations" "Toggling animations is currently supported on GNOME only."
        return 0
    fi

    local current choice
    current="$(gsettings get org.gnome.desktop.interface enable-animations 2>/dev/null)"
    choice="$(ui_menu "Animations" "GNOME animations are currently: ${current}" \
        "on"   "Enable animations" \
        "off"  "Disable animations (faster)" \
        "back" "Cancel")" || return 0

    case "${choice}" in
        on)  gsettings set org.gnome.desktop.interface enable-animations true
             ui_msgbox "Animations" "Animations enabled." ;;
        off) gsettings set org.gnome.desktop.interface enable-animations false
             ui_msgbox "Animations" "Animations disabled." ;;
    esac
}

# --- Fonts --------------------------------------------------------------------

# desk_fonts - List installed font families (read-only).
desk_fonts() {
    if has_cmd fc-list; then
        printf '== Installed font families (%s total) ==\n' \
            "$(fc-list : family 2>/dev/null | sort -u | wc -l)"
        fc-list : family 2>/dev/null | sort -u
    else
        printf 'fontconfig (fc-list) is not installed.\nInstall it with: sudo apt install fontconfig\n'
    fi
}

# --- Report and menu ----------------------------------------------------------

# _desktop_show <title> <collector> - Run a collector and display its output.
_desktop_show() {
    local title="$1"
    local collector="$2"
    local output

    log_debug "desktop: collecting '${collector}'"
    output="$("${collector}" 2>&1)" || true
    ui_show_text "${title}" "${output:-No data available.}"
}

# module_desktop_main - Entry point: submenu over desktop topics.
module_desktop_main() {
    local choice

    while true; do
        if ! choice="$(ui_menu "Desktop" "Select a topic:" \
            "info"       "Desktop environment info" \
            "appearance" "Theme, icons, cursor, fonts" \
            "fonts"      "Installed fonts" \
            "dark"       "Dark mode" \
            "animations" "Animations" \
            "back"       "Back to main menu")"; then
            return 0
        fi

        case "${choice}" in
            info)       _desktop_show "Desktop info" desk_info ;;
            appearance) _desktop_show "Appearance" desk_appearance ;;
            fonts)      _desktop_show "Installed fonts" desk_fonts ;;
            dark)       desk_dark_mode ;;
            animations) desk_animations ;;
            back)       return 0 ;;
        esac
    done
}
