#!/usr/bin/env bash
#
# tests/run_tests.sh - Test runner for the Debian Admin Toolkit.
#
# Runs every tests/test_*.sh file in its own Bash process and reports a
# summary. A test file fails when it exits with a non-zero status.
#
# Usage: bash tests/run_tests.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

main() {
    local -a failed=()
    local total=0
    local test_file

    for test_file in "${TESTS_DIR}"/test_*.sh; do
        [[ -e "${test_file}" ]] || continue
        total=$(( total + 1 ))
        printf '=== %s\n' "$(basename "${test_file}")"
        if bash "${test_file}"; then
            printf -- '--- PASS\n\n'
        else
            printf -- '--- FAIL\n\n'
            failed+=("$(basename "${test_file}")")
        fi
    done

    printf '%d test file(s), %d failed.\n' "${total}" "${#failed[@]}"
    if (( ${#failed[@]} > 0 )); then
        printf 'Failed: %s\n' "${failed[*]}"
        exit 1
    fi
}

main "$@"
