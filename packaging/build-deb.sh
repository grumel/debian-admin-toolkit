#!/usr/bin/env bash
#
# packaging/build-deb.sh - Build a .deb package of the Debian Admin Toolkit.
#
# Usage: packaging/build-deb.sh [output-dir]
#
# Produces <output-dir>/debian-admin-toolkit_<version>_all.deb. The package
# installs the toolkit to /opt/debian-admin-toolkit, provides the launcher
# /usr/bin/dat and a manual page. Requires dpkg-deb (package: dpkg-dev).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
OUT_DIR="${1:-${REPO_ROOT}/dist}"

# Runtime files installed under /opt/debian-admin-toolkit.
readonly ITEMS=(
    admin.sh
    install.sh
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

BUILD_DIR=""
cleanup() { [[ -n "${BUILD_DIR}" ]] && rm -rf "${BUILD_DIR}"; }
trap cleanup EXIT

main() {
    command -v dpkg-deb >/dev/null 2>&1 || {
        printf 'ERROR: dpkg-deb not found. Install it with: sudo apt install dpkg-dev\n' >&2
        exit 1
    }

    local version pkgroot install_dir
    version="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
    BUILD_DIR="$(mktemp -d)"
    pkgroot="${BUILD_DIR}/pkg"
    install_dir="${pkgroot}/opt/debian-admin-toolkit"

    # --- Payload: /opt/debian-admin-toolkit ---
    mkdir -p "${install_dir}"
    local item
    for item in "${ITEMS[@]}"; do
        cp -a "${REPO_ROOT}/${item}" "${install_dir}/${item}"
    done
    mkdir -p "${install_dir}/logs"
    chmod 0755 "${install_dir}/admin.sh" "${install_dir}/install.sh" \
        "${install_dir}/uninstall.sh"

    # --- Launcher: /usr/bin/dat -> admin.sh ---
    mkdir -p "${pkgroot}/usr/bin"
    ln -s /opt/debian-admin-toolkit/admin.sh "${pkgroot}/usr/bin/dat"

    # --- Manual page ---
    mkdir -p "${pkgroot}/usr/share/man/man1"
    gzip -9 -c "${REPO_ROOT}/docs/dat.1" > "${pkgroot}/usr/share/man/man1/dat.1.gz"

    # --- Control metadata ---
    mkdir -p "${pkgroot}/DEBIAN"
    sed "s/@VERSION@/${version}/" "${REPO_ROOT}/packaging/deb/control.in" \
        > "${pkgroot}/DEBIAN/control"

    # --- Build ---
    mkdir -p "${OUT_DIR}"
    local deb="${OUT_DIR}/debian-admin-toolkit_${version}_all.deb"
    dpkg-deb --build --root-owner-group "${pkgroot}" "${deb}" >/dev/null
    printf 'Built %s\n' "${deb}"
}

main "$@"
