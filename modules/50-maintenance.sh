#!/usr/bin/env bash
# DAT-MODULE
# Id: maintenance
# Name: Maintenance
# Description: apt update/upgrade/autoremove, journal, disk usage, backups
# Entry: module_maintenance_main
#
# modules/50-maintenance.sh - System maintenance tasks (roadmap phase 6).
#
# Read-only tasks (status, disk usage) run without confirmation. Tasks that
# change the system (upgrade, autoremove, journal vacuum) run via
# run_privileged and only after the operator confirms them.

# --- Package maintenance ------------------------------------------------------

# maint_update - Refresh package lists and show what can be upgraded.
maint_update() {
    printf '== apt-get update ==\n'
    run_privileged apt-get update 2>&1 || { printf 'update failed.\n'; return 1; }
    printf '\n== Upgradable packages ==\n'
    apt list --upgradable 2>/dev/null | tail -n +2 || printf 'none\n'
}

# maint_upgrade - Install available upgrades after confirmation.
maint_upgrade() {
    local pending
    run_privileged apt-get update -qq 2>/dev/null || true
    pending="$(apt list --upgradable 2>/dev/null | tail -n +2)"

    if [[ -z "${pending}" ]]; then
        ui_msgbox "Upgrade" "The system is already up to date."
        return 0
    fi

    if ! ui_yesno "Upgrade" "The following packages will be upgraded:

${pending}

Proceed with the upgrade?"; then
        return 0
    fi

    ui_show_cmd "Upgrade" run_privileged env DEBIAN_FRONTEND=noninteractive \
        apt-get upgrade -y
}

# maint_autoremove - Remove orphaned packages after confirmation.
maint_autoremove() {
    if ! ui_yesno "Autoremove" "Remove packages that are no longer required (apt-get autoremove)?"; then
        return 0
    fi
    ui_show_cmd "Autoremove" run_privileged env DEBIAN_FRONTEND=noninteractive \
        apt-get autoremove -y
}

# maint_clean - Clean the local apt package cache after confirmation.
maint_clean() {
    if ! ui_yesno "Clean cache" "Delete downloaded package files (apt-get clean)?"; then
        return 0
    fi
    ui_show_cmd "Clean cache" run_privileged apt-get clean
}

# --- Journal ------------------------------------------------------------------

# maint_journal_status - Journal disk usage and recent errors.
maint_journal_status() {
    if ! has_cmd journalctl; then
        printf 'systemd journal (journalctl) is not available.\n'
        return 0
    fi
    printf '== Journal disk usage ==\n'
    run_privileged journalctl --disk-usage 2>&1 || true
    printf '\n== Recent errors (last 20) ==\n'
    run_privileged journalctl -p err -n 20 --no-pager 2>&1 || true
}

# maint_journal_vacuum - Shrink the journal to a chosen size after confirmation.
maint_journal_vacuum() {
    if ! has_cmd journalctl; then
        ui_msgbox "Journal" "journalctl is not available."
        return 0
    fi

    local size
    size="$(ui_input "Journal vacuum" "Keep at most how much journal data? (e.g. 200M, 1G)" "200M")" || return 0
    [[ -z "${size}" ]] && return 0

    if ! [[ "${size}" =~ ^[0-9]+[KMG]?$ ]]; then
        ui_msgbox "Journal vacuum" "Invalid size: ${size}"
        return 0
    fi

    ui_show_cmd "Journal vacuum" run_privileged journalctl --vacuum-size="${size}"
}

# --- Disk usage ---------------------------------------------------------------

# maint_disk_usage - Filesystem usage plus the largest top-level directories.
maint_disk_usage() {
    printf '== Filesystem usage ==\n'
    df -h -x tmpfs -x devtmpfs -x overlay 2>&1
    printf '\n== Largest directories under / (top 15) ==\n'
    run_privileged du -xhd1 / 2>/dev/null | sort -rh | head -n 16 || \
        printf 'Could not analyse disk usage.\n'
}

# --- Backup -------------------------------------------------------------------

# maint_backup_etc - Create a timestamped tar.gz backup of /etc.
maint_backup_etc() {
    local dest
    dest="$(ui_input "Backup /etc" "Directory to store the backup in:" "${HOME}/dat-backups")" || return 0
    [[ -z "${dest}" ]] && return 0

    if ! mkdir -p "${dest}" 2>/dev/null; then
        ui_msgbox "Backup /etc" "Cannot create directory: ${dest}"
        return 0
    fi

    local archive
    archive="${dest}/etc-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    if ! ui_yesno "Backup /etc" "Create a compressed backup of /etc at:

${archive}?"; then
        return 0
    fi

    local output
    if output="$(run_privileged tar czf "${archive}" -C / etc 2>&1)"; then
        run_privileged chown "$(id -un):$(id -gn)" "${archive}" 2>/dev/null || true
        ui_msgbox "Backup /etc" "Backup created:
${archive}
Size: $(du -h "${archive}" 2>/dev/null | cut -f1)"
    else
        ui_show_text "Backup /etc" "Backup failed.

${output}"
    fi
}

# --- Menu ---------------------------------------------------------------------

# module_maintenance_main - Entry point: submenu of maintenance tasks.
module_maintenance_main() {
    local choice

    while true; do
        if ! choice="$(ui_menu "Maintenance" "Select a task:" \
            "update"      "Refresh package lists (apt update)" \
            "upgrade"     "Install upgrades (apt upgrade)" \
            "autoremove"  "Remove orphaned packages" \
            "clean"       "Clean apt cache" \
            "journal"     "Journal status (usage + errors)" \
            "vacuum"      "Shrink the journal" \
            "disk"        "Disk usage analysis" \
            "backup"      "Backup /etc" \
            "back"        "Back to main menu")"; then
            return 0
        fi

        case "${choice}" in
            update)     ui_show_cmd "apt update" maint_update ;;
            upgrade)    maint_upgrade ;;
            autoremove) maint_autoremove ;;
            clean)      maint_clean ;;
            journal)    ui_show_cmd "Journal status" maint_journal_status ;;
            vacuum)     maint_journal_vacuum ;;
            disk)       ui_show_cmd "Disk usage" maint_disk_usage ;;
            backup)     maint_backup_etc ;;
            back)       return 0 ;;
        esac
    done
}
