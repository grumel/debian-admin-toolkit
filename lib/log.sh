#!/usr/bin/env bash
#
# lib/log.sh - Logging for the Debian Admin Toolkit.
#
# Provides leveled logging (debug/info/warn/error) to a log file and to the
# terminal. This file is sourced, never executed directly.
#
# Configuration (via config/dat.conf or environment):
#   DAT_LOG_LEVEL  minimum level written to the log file and shown on the
#                  terminal: debug | info | warn | error  (default: info)
#   DAT_LOG_DIR    directory for log files (default: <DAT_ROOT>/logs, with a
#                  fallback to the XDG state directory if not writable)

# Guard against double sourcing.
[[ -n "${_DAT_LOG_SH:-}" ]] && return 0
_DAT_LOG_SH=1

# Default level; may be overridden by config_load or the environment.
DAT_LOG_LEVEL="${DAT_LOG_LEVEL:-info}"

# Resolved absolute path of the active log file (set by log_init).
DAT_LOG_FILE=""

# Terminal colors (only used when stderr is a terminal).
readonly _DAT_COLOR_RED=$'\033[31m'
readonly _DAT_COLOR_YELLOW=$'\033[33m'
readonly _DAT_COLOR_DIM=$'\033[2m'
readonly _DAT_COLOR_RESET=$'\033[0m'

# _log_level_num <level> - Map a level name to a number for comparisons.
_log_level_num() {
    case "$1" in
        debug) printf '0' ;;
        info)  printf '1' ;;
        warn)  printf '2' ;;
        error) printf '3' ;;
        *)     printf '1' ;;
    esac
}

# log_init - Choose and prepare the log file. Called once by admin.sh after
# the configuration has been loaded. Never fails: if no writable location is
# found, file logging is silently disabled.
log_init() {
    local log_dir="${DAT_LOG_DIR:-${DAT_ROOT}/logs}"

    # Fall back to the XDG state directory (e.g. ~/.local/state/dat) when the
    # preferred directory is not writable, e.g. for a system-wide install.
    if ! mkdir -p "${log_dir}" 2>/dev/null || [[ ! -w "${log_dir}" ]]; then
        log_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/${DAT_CMD}"
        mkdir -p "${log_dir}" 2>/dev/null || return 0
    fi

    DAT_LOG_FILE="${log_dir}/dat.log"
    touch "${DAT_LOG_FILE}" 2>/dev/null || DAT_LOG_FILE=""
}

# _log <level> <message> - Internal worker: write one log line.
_log() {
    local level="$1"
    local message="$2"
    local timestamp

    # Skip messages below the configured level.
    if (( $(_log_level_num "${level}") < $(_log_level_num "${DAT_LOG_LEVEL}") )); then
        return 0
    fi

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # File output (plain, machine readable).
    if [[ -n "${DAT_LOG_FILE}" ]]; then
        printf '%s [%-5s] %s\n' "${timestamp}" "${level}" "${message}" >> "${DAT_LOG_FILE}"
    fi

    # Terminal output on stderr, colored when supported.
    local prefix="[${level}]"
    if [[ -t 2 ]]; then
        case "${level}" in
            error) prefix="${_DAT_COLOR_RED}${prefix}${_DAT_COLOR_RESET}" ;;
            warn)  prefix="${_DAT_COLOR_YELLOW}${prefix}${_DAT_COLOR_RESET}" ;;
            debug) prefix="${_DAT_COLOR_DIM}${prefix}${_DAT_COLOR_RESET}" ;;
        esac
    fi
    printf '%s %s\n' "${prefix}" "${message}" >&2
}

# Public logging functions.
log_debug() { _log debug "$1"; }
log_info()  { _log info  "$1"; }
log_warn()  { _log warn  "$1"; }
log_error() { _log error "$1"; }
