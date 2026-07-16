#!/usr/bin/env bash
#
# uninstall.sh - Uninstaller for the Debian Admin Toolkit.
#
# Usage:
#   sudo ./uninstall.sh          Remove a system-wide installation
#   ./uninstall.sh --user        Remove a per-user installation
#   ./uninstall.sh --help        Show usage
#
# Removes the installed files and the 'dat' launcher. Per-user configuration
# in ~/.config/dat and system configuration in /etc/dat are kept.

set -euo pipefail

usage() {
    cat <<EOF
Debian Admin Toolkit uninstaller

Usage: ./uninstall.sh [--user] [--help]

  (no option)  Remove the system-wide installation (requires root):
               /opt/debian-admin-toolkit and /usr/local/bin/dat
  --user       Remove the per-user installation:
               ~/.local/share/debian-admin-toolkit and ~/.local/bin/dat

Configuration files (/etc/dat, ~/.config/dat) are not removed.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

main() {
    local mode="system"

    case "${1:-}" in
        "")        ;;
        --user)    mode="user" ;;
        --help|-h) usage; exit 0 ;;
        *)         usage; fail "Unknown option: $1" ;;
    esac

    local install_dir launcher
    if [[ "${mode}" == "system" ]]; then
        [[ ${EUID} -eq 0 ]] || fail "Removing a system-wide install requires root. Run with sudo or use --user."
        install_dir="/opt/debian-admin-toolkit"
        launcher="/usr/local/bin/dat"
    else
        install_dir="${HOME}/.local/share/debian-admin-toolkit"
        launcher="${HOME}/.local/bin/dat"
    fi

    [[ -d "${install_dir}" || -L "${launcher}" ]] || \
        fail "No installation found at ${install_dir}."

    printf 'Removing %s and %s ...\n' "${install_dir}" "${launcher}"
    rm -rf "${install_dir}"
    rm -f "${launcher}"
    printf 'Debian Admin Toolkit has been removed.\n'
}

main "$@"
