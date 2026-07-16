#!/usr/bin/env bash
#
# install.sh - Installer for the Debian Admin Toolkit.
#
# Usage:
#   sudo ./install.sh            System-wide install to /opt/debian-admin-toolkit
#                                with a launcher at /usr/local/bin/dat
#   ./install.sh --user          Per-user install to ~/.local/share/debian-admin-toolkit
#                                with a launcher at ~/.local/bin/dat
#   ./install.sh --help          Show usage
#
# The installer copies the toolkit files and creates a symlink launcher so
# the toolkit can be started with the 'dat' command.

set -euo pipefail

# Everything the toolkit needs at runtime.
readonly INSTALL_ITEMS=(
    admin.sh
    uninstall.sh
    VERSION
    LICENSE
    README.md
    CHANGELOG.md
    config
    docs
    lib
    modules
    plugins
)

SRC_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

usage() {
    cat <<EOF
Debian Admin Toolkit installer

Usage: ./install.sh [--user] [--help]

  (no option)  System-wide install (requires root):
               files:    /opt/debian-admin-toolkit
               launcher: /usr/local/bin/dat
  --user       Per-user install (no root required):
               files:    ~/.local/share/debian-admin-toolkit
               launcher: ~/.local/bin/dat
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

    local install_dir bin_dir
    if [[ "${mode}" == "system" ]]; then
        [[ ${EUID} -eq 0 ]] || fail "System-wide install requires root. Run with sudo or use --user."
        install_dir="/opt/debian-admin-toolkit"
        bin_dir="/usr/local/bin"
    else
        install_dir="${HOME}/.local/share/debian-admin-toolkit"
        bin_dir="${HOME}/.local/bin"
    fi

    printf 'Installing Debian Admin Toolkit (%s) to %s ...\n' \
        "$(tr -d '[:space:]' < "${SRC_DIR}/VERSION")" "${install_dir}"

    # Copy the toolkit. An existing installation is replaced, but user data
    # in logs/ is preserved because logs are not part of INSTALL_ITEMS.
    mkdir -p "${install_dir}" "${bin_dir}"
    local item
    for item in "${INSTALL_ITEMS[@]}"; do
        [[ -e "${SRC_DIR}/${item}" ]] || fail "Missing source item: ${item}"
        rm -rf "${install_dir:?}/${item}"
        cp -a "${SRC_DIR}/${item}" "${install_dir}/${item}"
    done
    mkdir -p "${install_dir}/logs"
    chmod 0755 "${install_dir}/admin.sh" "${install_dir}/uninstall.sh"

    # Launcher symlink.
    ln -sf "${install_dir}/admin.sh" "${bin_dir}/dat"
    printf 'Launcher created: %s/dat\n' "${bin_dir}"

    if [[ "${mode}" == "user" ]] && ! printf '%s' "${PATH}" | tr ':' '\n' | grep -qx "${bin_dir}"; then
        printf 'NOTE: %s is not in your PATH. Add it to use the "dat" command.\n' "${bin_dir}"
    fi

    printf 'Done. Start the toolkit with: dat\n'
}

main "$@"
