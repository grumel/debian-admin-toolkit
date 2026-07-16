#!/usr/bin/env bash
#
# scripts/sync-wiki.sh - Publish wiki/ to the GitHub wiki.
#
# Usage:
#   scripts/sync-wiki.sh [--dry-run]
#
# The GitHub wiki is a separate git repository
# (<repo>.wiki.git). This script mirrors the contents of the repository's
# wiki/ directory into it, so the wiki stays versioned and reviewable in the
# main repository ("wiki as code").
#
# Prerequisites: the wiki must already exist. GitHub only creates the wiki
# repository after the first page has been saved once via the web UI:
#
#   https://github.com/grumel/debian-admin-toolkit/wiki  ->  "Create the first page"
#
# Authentication uses the gh CLI's credentials (gh auth login).

set -euo pipefail

REPO_SLUG="${WIKI_REPO_SLUG:-grumel/debian-admin-toolkit}"
WIKI_URL="https://github.com/${REPO_SLUG}.wiki.git"

REPO_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SRC_DIR="${REPO_ROOT}/wiki"

DRY_RUN=0
WORK_DIR=""
cleanup() { [[ -n "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"; }
trap cleanup EXIT

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

main() {
    case "${1:-}" in
        "")         ;;
        --dry-run)  DRY_RUN=1 ;;
        --help|-h)  sed -n '3,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *)          fail "Unknown option: $1" ;;
    esac

    [[ -d "${SRC_DIR}" ]] || fail "No wiki/ directory at ${SRC_DIR}"
    command -v git >/dev/null 2>&1 || fail "git is required."

    WORK_DIR="$(mktemp -d)"
    local clone="${WORK_DIR}/wiki"

    printf 'Cloning %s ...\n' "${WIKI_URL}"
    if ! git clone --quiet "${WIKI_URL}" "${clone}" 2>/dev/null; then
        fail "Could not clone the wiki.

The wiki repository does not exist yet. Open
  https://github.com/${REPO_SLUG}/wiki
click \"Create the first page\", save it once, then re-run this script."
    fi

    # Mirror wiki/ into the clone: copy pages, drop pages that were removed.
    local page
    for page in "${clone}"/*.md; do
        [[ -e "${page}" ]] || continue
        rm -f "${page}"
    done
    cp "${SRC_DIR}"/*.md "${clone}/"

    if [[ -z "$(git -C "${clone}" status --porcelain)" ]]; then
        printf 'Wiki is already up to date.\n'
        return 0
    fi

    printf '\nPending changes:\n'
    git -C "${clone}" add -A
    git -C "${clone}" status --short

    if (( DRY_RUN )); then
        printf '\nDry run: nothing pushed.\n'
        return 0
    fi

    git -C "${clone}" commit --quiet \
        -m "Sync wiki from repository (dat $(tr -d '[:space:]' < "${REPO_ROOT}/VERSION"))"
    git -C "${clone}" push --quiet origin HEAD
    printf '\nPublished to https://github.com/%s/wiki\n' "${REPO_SLUG}"
}

main "$@"
