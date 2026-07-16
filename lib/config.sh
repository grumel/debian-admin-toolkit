#!/usr/bin/env bash
#
# lib/config.sh - Configuration loading for the Debian Admin Toolkit.
#
# Configuration files use simple KEY=VALUE lines. They are parsed, not
# sourced, so a config file can never execute code. Unknown keys are
# reported as warnings and ignored.
#
# Load order (later files override earlier ones):
#   1. <DAT_ROOT>/config/dat.conf                 shipped defaults
#   2. /etc/dat/dat.conf                          system-wide overrides
#   3. ${XDG_CONFIG_HOME:-~/.config}/dat/dat.conf per-user overrides
#
# This file is sourced, never executed directly.

# Guard against double sourcing.
[[ -n "${_DAT_CONFIG_SH:-}" ]] && return 0
_DAT_CONFIG_SH=1

# ---------------------------------------------------------------------------
# Defaults for all supported configuration keys
# ---------------------------------------------------------------------------

# These variables are consumed by lib/log.sh and lib/ui.sh.
# shellcheck disable=SC2034

# Minimum log level: debug | info | warn | error
DAT_LOG_LEVEL="${DAT_LOG_LEVEL:-info}"

# Log directory. Empty means: use the built-in default (see lib/log.sh).
DAT_LOG_DIR="${DAT_LOG_DIR:-}"

# UI backend: auto | whiptail | text
DAT_UI_BACKEND="${DAT_UI_BACKEND:-auto}"

# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

# _config_apply <key> <value> - Apply one validated key/value pair.
_config_apply() {
    local key="$1"
    local value="$2"

    case "${key}" in
        DAT_LOG_LEVEL)
            case "${value}" in
                debug|info|warn|error) DAT_LOG_LEVEL="${value}" ;;
                *) log_warn "Invalid DAT_LOG_LEVEL '${value}' ignored." ;;
            esac
            ;;
        DAT_LOG_DIR)
            DAT_LOG_DIR="${value}"
            ;;
        DAT_UI_BACKEND)
            case "${value}" in
                auto|whiptail|text) DAT_UI_BACKEND="${value}" ;;
                *) log_warn "Invalid DAT_UI_BACKEND '${value}' ignored." ;;
            esac
            ;;
        *)
            log_warn "Unknown configuration key '${key}' ignored."
            ;;
    esac
}

# _config_read_file <file> - Parse one configuration file.
_config_read_file() {
    local file="$1"
    local line key value

    [[ -r "${file}" ]] || return 0
    log_debug "Loading configuration from ${file}"

    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Strip comments and surrounding whitespace.
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "${line}" ]] && continue

        # Accept only KEY=VALUE with an uppercase key.
        if [[ "${line}" =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            # Remove optional surrounding quotes from the value.
            value="${value#\"}"
            value="${value%\"}"
            _config_apply "${key}" "${value}"
        else
            log_warn "Ignoring malformed line in ${file}: ${line}"
        fi
    done < "${file}"
}

# config_load - Load all configuration files in override order. Command line
# flags (e.g. --debug) are applied by admin.sh after this and win over files.
config_load() {
    _config_read_file "${DAT_ROOT}/config/dat.conf"
    _config_read_file "/etc/dat/dat.conf"
    _config_read_file "${XDG_CONFIG_HOME:-${HOME}/.config}/dat/dat.conf"
}
