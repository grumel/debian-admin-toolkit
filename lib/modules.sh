#!/usr/bin/env bash
#
# lib/modules.sh - Module and plugin loader for the Debian Admin Toolkit.
#
# Modules live in <DAT_ROOT>/modules/, plugins in <DAT_ROOT>/plugins/.
# Both use the same format: a Bash file with a metadata header that is
# discovered automatically. Dropping a file into plugins/ is all that is
# needed to extend the toolkit.
#
# Required metadata header (first 20 lines of the file):
#
#   # DAT-MODULE
#   # Id: system
#   # Name: System Information
#   # Description: Inspect hardware and operating system details
#   # Entry: module_system_main
#
# The Entry function is called without arguments after the file has been
# sourced. This file is sourced, never executed directly.

# Guard against double sourcing.
[[ -n "${_DAT_MODULES_SH:-}" ]] && return 0
_DAT_MODULES_SH=1

# Registry, filled by modules_discover. All arrays are index-aligned.
DAT_MODULE_IDS=()
DAT_MODULE_NAMES=()
DAT_MODULE_DESCS=()
DAT_MODULE_ENTRIES=()
DAT_MODULE_FILES=()

# _module_meta <file> <field> - Extract one metadata field from a module
# header, e.g. _module_meta foo.sh "Name".
_module_meta() {
    local file="$1"
    local field="$2"

    head -n 20 "${file}" | sed -n "s/^# ${field}: //p" | head -n 1
}

# _module_register <file> - Validate one candidate file and add it to the
# registry. Invalid files are skipped with a warning so that one broken
# plugin can never take down the toolkit.
_module_register() {
    local file="$1"
    local id name desc entry

    # Only files that declare themselves as DAT modules are considered.
    head -n 20 "${file}" | grep -q '^# DAT-MODULE$' || return 0

    id="$(_module_meta "${file}" "Id")"
    name="$(_module_meta "${file}" "Name")"
    desc="$(_module_meta "${file}" "Description")"
    entry="$(_module_meta "${file}" "Entry")"

    if [[ -z "${id}" || -z "${name}" || -z "${entry}" ]]; then
        log_warn "Skipping module '${file}': incomplete metadata header."
        return 0
    fi

    if [[ ! "${id}" =~ ^[a-z][a-z0-9-]*$ ]]; then
        log_warn "Skipping module '${file}': invalid id '${id}'."
        return 0
    fi

    local existing
    for existing in "${DAT_MODULE_IDS[@]}"; do
        if [[ "${existing}" == "${id}" ]]; then
            log_warn "Skipping module '${file}': duplicate id '${id}'."
            return 0
        fi
    done

    DAT_MODULE_IDS+=("${id}")
    DAT_MODULE_NAMES+=("${name}")
    DAT_MODULE_DESCS+=("${desc}")
    DAT_MODULE_ENTRIES+=("${entry}")
    DAT_MODULE_FILES+=("${file}")
    log_debug "Registered module '${id}' from ${file}"
}

# modules_discover - Scan modules/ and plugins/ and (re)build the registry.
# Files are processed in lexical order; a numeric prefix (e.g. 10-system.sh)
# controls the menu position.
modules_discover() {
    DAT_MODULE_IDS=()
    DAT_MODULE_NAMES=()
    DAT_MODULE_DESCS=()
    DAT_MODULE_ENTRIES=()
    DAT_MODULE_FILES=()

    local dir file
    for dir in "${DAT_ROOT}/modules" "${DAT_ROOT}/plugins"; do
        [[ -d "${dir}" ]] || continue
        for file in "${dir}"/*.sh; do
            [[ -e "${file}" ]] || continue
            _module_register "${file}"
        done
    done

    log_debug "Discovered ${#DAT_MODULE_IDS[@]} module(s)."
}

# _module_index <id> - Print the registry index for a module id.
# Returns 1 when the id is unknown.
_module_index() {
    local id="$1"
    local i

    for i in "${!DAT_MODULE_IDS[@]}"; do
        if [[ "${DAT_MODULE_IDS[${i}]}" == "${id}" ]]; then
            printf '%s' "${i}"
            return 0
        fi
    done
    return 1
}

# modules_run <id> - Source a module and invoke its entry function.
modules_run() {
    local id="$1"
    local index

    if ! index="$(_module_index "${id}")"; then
        log_error "Unknown module '${id}'. Use --list to see available modules."
        return 1
    fi

    local file="${DAT_MODULE_FILES[${index}]}"
    local entry="${DAT_MODULE_ENTRIES[${index}]}"

    # shellcheck source=/dev/null
    source "${file}"

    if ! declare -F "${entry}" >/dev/null; then
        log_error "Module '${id}': entry function '${entry}' not found in ${file}."
        return 1
    fi

    log_info "Running module '${id}'."
    "${entry}"
}

# modules_list - Print all registered modules as a plain table (for --list).
modules_list() {
    local i
    for i in "${!DAT_MODULE_IDS[@]}"; do
        printf '%-12s %-24s %s\n' \
            "${DAT_MODULE_IDS[${i}]}" \
            "${DAT_MODULE_NAMES[${i}]}" \
            "${DAT_MODULE_DESCS[${i}]}"
    done
}
