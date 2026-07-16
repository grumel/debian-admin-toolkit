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
# Authentication:
#   - locally: the gh CLI's git credential helper (gh auth login)
#   - in CI:   set GITHUB_TOKEN, which is used for the clone/push
#
# The token is never printed; only the token-free URL is logged.

set -euo pipefail

REPO_SLUG="${WIKI_REPO_SLUG:-grumel/debian-admin-toolkit}"

# Token-free URL for log output.
WIKI_URL_DISPLAY="https://github.com/${REPO_SLUG}.wiki.git"

# URL actually used for git operations. In CI there is no credential helper,
# so authenticate with the token the workflow provides.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    WIKI_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO_SLUG}.wiki.git"
else
    WIKI_URL="${WIKI_URL_DISPLAY}"
fi

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

    printf 'Cloning %s ...\n' "${WIKI_URL_DISPLAY}"
    if ! git clone --quiet "${WIKI_URL}" "${clone}" 2>/dev/null; then
        fail "Could not clone the wiki.

Either the wiki repository does not exist yet, or authentication failed.
GitHub only creates it after the first page has been saved once via the
web UI: open https://github.com/${REPO_SLUG}/wiki, click \"Create the first
page\", save it, then re-run this script."
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

    # Commit with the caller's git identity, falling back to a bot identity
    # when none is configured (the usual case in CI).
    local -a ident=()
    if ! git -C "${clone}" config user.email >/dev/null 2>&1; then
        ident=(-c "user.name=github-actions[bot]"
               -c "user.email=41898282+github-actions[bot]@users.noreply.github.com")
    fi

    git -C "${clone}" "${ident[@]}" commit --quiet \
        -m "Sync wiki from repository (dat $(tr -d '[:space:]' < "${REPO_ROOT}/VERSION"))"
    git -C "${clone}" push --quiet origin HEAD
    printf '\nPublished to https://github.com/%s/wiki\n' "${REPO_SLUG}"
}

main "$@"
