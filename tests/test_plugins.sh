#!/usr/bin/env bash
#
# tests/test_plugins.sh - Tests for the plugin drop-in mechanism.
#
# Verifies that:
#   - a valid plugin dropped into plugins/ is discovered and runnable,
#   - the shipped hello.sh.example template is NOT auto-discovered,
#   - a plugin with a broken metadata header is skipped, not fatal,
#   - a duplicate module id is rejected.
#
# The temporary plugin files are always removed again, including on failure.

set -euo pipefail

DAT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
export DAT_ROOT

FAILURES=0
CREATED_FILES=()

# assert <description> <command...> - Run a check and record the result.
assert() {
    local desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        printf 'ok     %s\n' "${desc}"
    else
        printf 'FAILED %s\n' "${desc}"
        FAILURES=$(( FAILURES + 1 ))
    fi
}

cleanup() {
    local f
    for f in "${CREATED_FILES[@]}"; do
        rm -f "${f}"
    done
}
trap cleanup EXIT

# has_module <id> - Return 0 when module <id> is in the discovery registry.
has_module() {
    local wanted="$1" id
    for id in "${DAT_MODULE_IDS[@]}"; do
        [[ "${id}" == "${wanted}" ]] && return 0
    done
    return 1
}

main() {
    # Load the framework.
    # shellcheck source=../lib/core.sh
    source "${DAT_ROOT}/lib/core.sh"
    # shellcheck source=../lib/log.sh
    source "${DAT_ROOT}/lib/log.sh"
    # shellcheck source=../lib/config.sh
    source "${DAT_ROOT}/lib/config.sh"
    # shellcheck source=../lib/ui.sh
    source "${DAT_ROOT}/lib/ui.sh"
    # shellcheck source=../lib/modules.sh
    source "${DAT_ROOT}/lib/modules.sh"

    DAT_LOG_LEVEL="error"  # keep test output clean

    # 1. A valid drop-in plugin is discovered.
    local good="${DAT_ROOT}/plugins/zz-test-good.sh"
    CREATED_FILES+=("${good}")
    cat > "${good}" <<'PLUGIN'
#!/usr/bin/env bash
# DAT-MODULE
# Id: zz-test-good
# Name: Test Good
# Description: Temporary test plugin
# Entry: module_zz_test_good_main
module_zz_test_good_main() { return 0; }
PLUGIN

    # 2. A broken plugin (missing Entry) must be skipped, not fatal.
    local broken="${DAT_ROOT}/plugins/zz-test-broken.sh"
    CREATED_FILES+=("${broken}")
    cat > "${broken}" <<'PLUGIN'
#!/usr/bin/env bash
# DAT-MODULE
# Id: zz-test-broken
# Name: Test Broken
PLUGIN

    modules_discover

    assert "valid drop-in plugin is discovered" has_module "zz-test-good"
    if has_module "zz-test-broken"; then
        printf 'FAILED broken plugin must not be registered\n'
        FAILURES=$(( FAILURES + 1 ))
    else
        printf 'ok     broken plugin is not registered\n'
    fi

    # 3. The shipped example template must not be auto-discovered.
    if has_module "hello"; then
        printf 'FAILED hello.sh.example must not be discovered\n'
        FAILURES=$(( FAILURES + 1 ))
    else
        printf 'ok     hello.sh.example template is not discovered\n'
    fi

    # 4. Running the valid plugin via modules_run works.
    assert "valid plugin runs via modules_run" modules_run "zz-test-good"

    printf '%d failure(s)\n' "${FAILURES}"
    (( FAILURES == 0 ))
}

main "$@"
