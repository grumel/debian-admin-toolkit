#!/usr/bin/env bash
#
# packaging/build-tarball.sh - Build a distributable source tarball of DAT.
#
# Usage: packaging/build-tarball.sh [output-dir]
#
# Produces <output-dir>/debian-admin-toolkit-<version>.tar.gz containing the
# runtime files needed to install the toolkit (no .git, no logs, no CI). The
# archive unpacks into a single top-level directory.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
OUT_DIR="${1:-${REPO_ROOT}/dist}"

# Runtime files that belong in the distributed package.
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

# Staging directory, kept at global scope so the EXIT trap can clean it up
# after main() returns.
STAGING=""
cleanup() { [[ -n "${STAGING}" ]] && rm -rf "${STAGING}"; }
trap cleanup EXIT

main() {
    local version pkg
    version="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
    pkg="debian-admin-toolkit-${version}"

    mkdir -p "${OUT_DIR}"
    STAGING="$(mktemp -d)"
    local staging="${STAGING}"

    mkdir -p "${staging}/${pkg}"
    local item
    for item in "${ITEMS[@]}"; do
        cp -a "${REPO_ROOT}/${item}" "${staging}/${pkg}/${item}"
    done
    # Ship an empty logs/ directory so the toolkit can log from the checkout.
    mkdir -p "${staging}/${pkg}/logs"

    local tarball="${OUT_DIR}/${pkg}.tar.gz"
    tar czf "${tarball}" -C "${staging}" "${pkg}"
    printf 'Built %s\n' "${tarball}"
}

main "$@"
