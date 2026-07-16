#!/usr/bin/env bash
#
# lib/core.sh - Core helpers shared by all DAT components.
#
# This file is sourced by admin.sh (and by tests), never executed directly.
# It must not produce any output when sourced.
#
# Requires: DAT_ROOT to be set by the caller before sourcing.

# Guard against double sourcing.
[[ -n "${_DAT_CORE_SH:-}" ]] && return 0
_DAT_CORE_SH=1

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Human readable toolkit name, used in UI titles and log lines.
# shellcheck disable=SC2034  # consumed by admin.sh and other libraries
readonly DAT_NAME="Debian Admin Toolkit"

# Short command name of the toolkit.
# shellcheck disable=SC2034  # consumed by lib/log.sh
readonly DAT_CMD="dat"

# ---------------------------------------------------------------------------
# Version handling
# ---------------------------------------------------------------------------

# dat_version - Print the toolkit version taken from the VERSION file.
dat_version() {
    local version_file="${DAT_ROOT}/VERSION"

    if [[ -r "${version_file}" ]]; then
        tr -d '[:space:]' < "${version_file}"
    else
        printf 'unknown'
    fi
}

# ---------------------------------------------------------------------------
# Command and privilege helpers
# ---------------------------------------------------------------------------

# has_cmd <command> - Return 0 if <command> is available in PATH.
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# require_cmd <command> [package] - Return 1 with a helpful log message if
# <command> is not installed. [package] is the Debian package that provides
# the command (defaults to the command name).
require_cmd() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if ! has_cmd "${cmd}"; then
        log_error "Required command '${cmd}' not found. Install it with: sudo apt install ${pkg}"
        return 1
    fi
}

# is_root - Return 0 when the current process runs as root.
is_root() {
    [[ ${EUID} -eq 0 ]]
}

# run_privileged <command...> - Run a command as root, using sudo when the
# current user is unprivileged. Fails with a log message if neither root
# privileges nor sudo are available.
run_privileged() {
    if is_root; then
        "$@"
    elif has_cmd sudo; then
        sudo "$@"
    else
        log_error "This action requires root privileges and 'sudo' is not available."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------

# die <message> [exit-code] - Log an error and terminate the program.
die() {
    log_error "$1"
    exit "${2:-1}"
}

# ---------------------------------------------------------------------------
# Temporary files
# ---------------------------------------------------------------------------

# dat_tmpdir - Create (once) and print a private temporary directory for the
# current DAT process. The caller (admin.sh) removes it on exit.
dat_tmpdir() {
    if [[ -z "${_DAT_TMPDIR:-}" ]]; then
        _DAT_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/dat.XXXXXX")"
    fi
    printf '%s' "${_DAT_TMPDIR}"
}

# dat_cleanup - Remove the temporary directory. Registered as an EXIT trap
# by admin.sh.
dat_cleanup() {
    if [[ -n "${_DAT_TMPDIR:-}" && -d "${_DAT_TMPDIR}" ]]; then
        rm -rf "${_DAT_TMPDIR}"
    fi
}
