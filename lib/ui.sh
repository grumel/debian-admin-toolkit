#!/usr/bin/env bash
#
# lib/ui.sh - Terminal user interface for the Debian Admin Toolkit.
#
# All dialogs are provided as ui_* wrapper functions. The primary backend is
# whiptail; a plain-text fallback keeps the toolkit usable on minimal systems
# (e.g. over a serial console or in containers without whiptail).
#
# This file is sourced, never executed directly.

# Guard against double sourcing.
[[ -n "${_DAT_UI_SH:-}" ]] && return 0
_DAT_UI_SH=1

# Active backend after ui_init: "whiptail" or "text".
DAT_UI_ACTIVE=""

# Dialog dimensions, recalculated by ui_init from the terminal size.
_DAT_UI_HEIGHT=20
_DAT_UI_WIDTH=74
_DAT_UI_LIST_HEIGHT=12

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

# ui_init - Select the UI backend based on DAT_UI_BACKEND and availability.
ui_init() {
    case "${DAT_UI_BACKEND}" in
        whiptail)
            DAT_UI_ACTIVE="whiptail"
            ;;
        text)
            DAT_UI_ACTIVE="text"
            ;;
        *)  # auto
            if has_cmd whiptail && [[ -t 0 && -t 1 ]]; then
                DAT_UI_ACTIVE="whiptail"
            else
                DAT_UI_ACTIVE="text"
            fi
            ;;
    esac

    # Size dialogs relative to the terminal, within sane bounds.
    if [[ -t 1 ]] && has_cmd tput; then
        local rows cols
        rows="$(tput lines 2>/dev/null || printf '24')"
        cols="$(tput cols 2>/dev/null || printf '80')"
        _DAT_UI_HEIGHT=$(( rows - 4 ));  (( _DAT_UI_HEIGHT > 30 )) && _DAT_UI_HEIGHT=30
        (( _DAT_UI_HEIGHT < 12 )) && _DAT_UI_HEIGHT=12
        _DAT_UI_WIDTH=$(( cols - 6 ));   (( _DAT_UI_WIDTH > 100 )) && _DAT_UI_WIDTH=100
        (( _DAT_UI_WIDTH < 60 )) && _DAT_UI_WIDTH=60
        _DAT_UI_LIST_HEIGHT=$(( _DAT_UI_HEIGHT - 8 ))
    fi

    log_debug "UI backend: ${DAT_UI_ACTIVE} (${_DAT_UI_WIDTH}x${_DAT_UI_HEIGHT})"
}

# ---------------------------------------------------------------------------
# Dialogs
# ---------------------------------------------------------------------------

# ui_msgbox <title> <text> - Show an informational message.
ui_msgbox() {
    local title="$1"
    local text="$2"

    if [[ "${DAT_UI_ACTIVE}" == "whiptail" ]]; then
        whiptail --title "${title}" --msgbox "${text}" \
            "${_DAT_UI_HEIGHT}" "${_DAT_UI_WIDTH}"
    else
        printf '\n== %s ==\n%s\n' "${title}" "${text}"
    fi
}

# ui_yesno <title> <question> - Ask a yes/no question.
# Returns 0 for yes, 1 for no.
ui_yesno() {
    local title="$1"
    local question="$2"

    if [[ "${DAT_UI_ACTIVE}" == "whiptail" ]]; then
        whiptail --title "${title}" --yesno "${question}" \
            "${_DAT_UI_HEIGHT}" "${_DAT_UI_WIDTH}"
    else
        local answer
        while true; do
            # On EOF (no interactive input) default to "no" instead of looping.
            if ! read -r -p "${question} [y/n] " answer; then
                printf '\n' >&2
                return 1
            fi
            case "${answer}" in
                y|Y|yes) return 0 ;;
                n|N|no)  return 1 ;;
            esac
        done
    fi
}

# ui_menu <title> <prompt> <tag> <label> [<tag> <label> ...]
# Show a selection menu. Prints the chosen tag on stdout.
# Returns 1 when the user cancels.
ui_menu() {
    local title="$1"
    local prompt="$2"
    shift 2

    if [[ "${DAT_UI_ACTIVE}" == "whiptail" ]]; then
        whiptail --title "${title}" --menu "${prompt}" \
            "${_DAT_UI_HEIGHT}" "${_DAT_UI_WIDTH}" "${_DAT_UI_LIST_HEIGHT}" \
            "$@" 3>&1 1>&2 2>&3
        return $?
    fi

    # Text fallback: numbered menu.
    local -a tags=()
    local -a labels=()
    while (( $# >= 2 )); do
        tags+=("$1")
        labels+=("$2")
        shift 2
    done

    printf '\n== %s ==\n%s\n' "${title}" "${prompt}" >&2
    local i
    for i in "${!tags[@]}"; do
        printf '  %2d) %s\n' "$(( i + 1 ))" "${labels[${i}]}" >&2
    done
    printf '   q) Cancel\n' >&2

    local choice
    while true; do
        # On EOF (no interactive input) treat it as a cancel to avoid looping.
        if ! read -r -p "Selection: " choice; then
            printf '\n' >&2
            return 1
        fi
        if [[ "${choice}" == "q" ]]; then
            return 1
        fi
        # Accept either the position number or the tag itself.
        if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#tags[@]} )); then
            printf '%s' "${tags[$(( choice - 1 ))]}"
            return 0
        fi
        local t
        for t in "${tags[@]}"; do
            if [[ "${t}" == "${choice}" ]]; then
                printf '%s' "${t}"
                return 0
            fi
        done
        printf 'Invalid selection.\n' >&2
    done
}

# ui_show_text <title> <text> - Display multi-line text in a scrollable box.
ui_show_text() {
    local title="$1"
    local text="$2"

    if [[ "${DAT_UI_ACTIVE}" == "whiptail" ]]; then
        local tmpfile
        tmpfile="$(dat_tmpdir)/textbox.txt"
        printf '%s\n' "${text}" > "${tmpfile}"
        whiptail --title "${title}" --scrolltext --textbox "${tmpfile}" \
            "${_DAT_UI_HEIGHT}" "${_DAT_UI_WIDTH}"
        rm -f "${tmpfile}"
    else
        printf '\n== %s ==\n%s\n' "${title}" "${text}"
    fi
}

# ui_show_cmd <title> <command...> - Run a command, capture its output and
# display it. A failing command is reported inside the dialog instead of
# aborting the toolkit.
ui_show_cmd() {
    local title="$1"
    shift

    local output
    if output="$("$@" 2>&1)"; then
        ui_show_text "${title}" "${output}"
    else
        ui_show_text "${title}" "Command failed: $*

${output}"
    fi
}
