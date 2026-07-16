#!/usr/bin/env bash
#
# tests/test_framework.sh - Basic tests for the DAT framework.
#
# Checks Bash syntax of every script, loads the libraries and verifies the
# core functions, configuration parsing and module discovery.

set -euo pipefail

DAT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
export DAT_ROOT

FAILURES=0

# assert <description> <command...> - Run a check (output suppressed) and
# record the result.
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

# fn_defined <name> - Check that a function is defined.
fn_defined() {
    declare -F "$1" > /dev/null
}

# --- Syntax checks -----------------------------------------------------------

check_syntax() {
    local file
    while IFS= read -r file; do
        assert "syntax: ${file#"${DAT_ROOT}"/}" bash -n "${file}"
    done < <(find "${DAT_ROOT}" -name '*.sh' -not -path '*/.git/*' | sort)
}

# --- Framework checks ----------------------------------------------------------

check_framework() {
    # Load the libraries exactly like admin.sh does.
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

    local fn
    for fn in dat_version has_cmd require_cmd is_root die \
              log_debug log_info log_warn log_error log_init \
              config_load ui_init ui_menu ui_msgbox ui_show_text \
              modules_discover modules_run modules_list; do
        assert "function defined: ${fn}" fn_defined "${fn}"
    done

    # VERSION must contain a semantic version.
    local version
    version="$(dat_version)"
    assert "VERSION is semantic (${version})" \
        bash -c "[[ '${version}' =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?\$ ]]"

    # Configuration loading must succeed and keep valid defaults.
    config_load
    assert "config: valid log level (${DAT_LOG_LEVEL})" \
        bash -c "[[ '${DAT_LOG_LEVEL}' =~ ^(debug|info|warn|error)\$ ]]"

    # Module discovery must run without errors.
    modules_discover
    assert "module discovery runs (${#DAT_MODULE_IDS[@]} module(s))" modules_discover
}

# --- CLI checks ----------------------------------------------------------------

check_cli() {
    assert "admin.sh --help exits 0"    bash "${DAT_ROOT}/admin.sh" --help
    assert "admin.sh --version exits 0" bash "${DAT_ROOT}/admin.sh" --version
    assert "admin.sh --list exits 0"    bash "${DAT_ROOT}/admin.sh" --list
}

main() {
    check_syntax
    check_framework
    check_cli
    printf '%d failure(s)\n' "${FAILURES}"
    (( FAILURES == 0 ))
}

main "$@"
