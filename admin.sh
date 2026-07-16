#!/usr/bin/env bash
#
# admin.sh - Main entry point of the Debian Admin Toolkit (DAT).
#
# Usage:
#   dat                 Start the interactive main menu
#   dat <module-id>     Run a single module directly
#   dat --list          List available modules and plugins
#   dat --version       Print the toolkit version
#   dat --help          Show usage information
#   dat --debug         Enable debug logging for this run
#
# The toolkit is modular: everything beyond argument handling and the main
# menu lives in lib/ (framework) and modules/ or plugins/ (features).

set -euo pipefail

# Resolve the toolkit root, following symlinks so that a launcher like
# /usr/local/bin/dat -> /opt/debian-admin-toolkit/admin.sh works.
DAT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
export DAT_ROOT

# Load the framework libraries (order matters).
# shellcheck source=lib/core.sh
source "${DAT_ROOT}/lib/core.sh"
# shellcheck source=lib/log.sh
source "${DAT_ROOT}/lib/log.sh"
# shellcheck source=lib/config.sh
source "${DAT_ROOT}/lib/config.sh"
# shellcheck source=lib/ui.sh
source "${DAT_ROOT}/lib/ui.sh"
# shellcheck source=lib/modules.sh
source "${DAT_ROOT}/lib/modules.sh"

# usage - Print help text.
usage() {
    cat <<EOF
${DAT_NAME} $(dat_version)

Usage: ${DAT_CMD} [OPTION] [MODULE]

Options:
  --list       List available modules and plugins
  --version    Print the toolkit version
  --debug      Enable debug logging for this run
  --help       Show this help

Without arguments an interactive main menu is started.
With MODULE (see --list) a single module is run directly.
EOF
}

# main_menu - Interactive main menu loop over all discovered modules.
main_menu() {
    local -a menu_items
    local choice i

    while true; do
        menu_items=()
        for i in "${!DAT_MODULE_IDS[@]}"; do
            menu_items+=("${DAT_MODULE_IDS[${i}]}" "${DAT_MODULE_NAMES[${i}]}")
        done
        menu_items+=("quit" "Exit the toolkit")

        if ! choice="$(ui_menu "${DAT_NAME} $(dat_version)" \
            "Select a module:" "${menu_items[@]}")"; then
            break
        fi

        case "${choice}" in
            quit) break ;;
            *)    modules_run "${choice}" || \
                      ui_msgbox "Error" "Module '${choice}' failed. See the log for details." ;;
        esac
    done
}

main() {
    local run_module=""
    local debug=0

    # Argument parsing. Options first, then an optional module id.
    while (( $# > 0 )); do
        case "$1" in
            --help|-h)    usage; exit 0 ;;
            --version|-V) dat_version; printf '\n'; exit 0 ;;
            --list|-l)    run_module="--list" ;;
            --debug)      debug=1 ;;
            -*)           printf 'Unknown option: %s\n\n' "$1" >&2; usage; exit 2 ;;
            *)            run_module="$1" ;;
        esac
        shift
    done

    # Initialise the framework.
    # --debug is applied twice on purpose: before config_load so that loading
    # the configuration is logged too, and again afterwards so the command
    # line flag always beats a DAT_LOG_LEVEL coming from a config file.
    # Messages logged before log_init only reach the terminal, because the
    # log file location itself depends on the configuration.
    (( debug )) && DAT_LOG_LEVEL="debug"
    config_load
    (( debug )) && DAT_LOG_LEVEL="debug"
    log_init
    ui_init
    trap dat_cleanup EXIT
    modules_discover

    log_debug "${DAT_NAME} $(dat_version) started (root: ${DAT_ROOT})"

    if [[ "${run_module}" == "--list" ]]; then
        modules_list
    elif [[ -n "${run_module}" ]]; then
        modules_run "${run_module}"
    else
        main_menu
    fi
}

main "$@"
