#!/usr/bin/env bash
# DAT-MODULE
# Id: system
# Name: System Information
# Description: Debian version, kernel, CPU, RAM, BIOS, temperatures, disks, SMART
# Entry: module_system_main
#
# modules/10-system.sh - System information module (roadmap phase 2).
#
# Read-only module: it only inspects the system and never changes anything.
# Optional tools (dmidecode, lm-sensors, smartmontools) are detected at
# runtime; missing tools produce a hint instead of an error.

# --- Section collectors -------------------------------------------------------
# Each sys_* function prints a plain-text report section on stdout and must
# not fail the toolkit when information is unavailable.

# sys_os - Debian release and OS details.
sys_os() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        (source /etc/os-release && printf 'Distribution:   %s\n' "${PRETTY_NAME:-unknown}")
    fi
    if [[ -r /etc/debian_version ]]; then
        printf 'Debian version: %s\n' "$(cat /etc/debian_version)"
    fi
    printf 'Hostname:       %s\n' "$(hostname)"
    printf 'Architecture:   %s\n' "$(uname -m)"
    if has_cmd uptime; then
        printf 'Uptime:         %s\n' "$(uptime -p 2>/dev/null || uptime)"
    fi
}

# sys_kernel - Kernel and boot information.
sys_kernel() {
    printf 'Kernel release: %s\n' "$(uname -r)"
    printf 'Kernel version: %s\n' "$(uname -v)"
    printf 'Command line:   %s\n' "$(cat /proc/cmdline 2>/dev/null || printf 'n/a')"
}

# sys_cpu - CPU model, cores and frequencies.
sys_cpu() {
    if has_cmd lscpu; then
        lscpu
    else
        grep -E '^(model name|cpu cores|siblings)' /proc/cpuinfo | sort -u
    fi
}

# sys_memory - RAM and swap usage.
sys_memory() {
    if has_cmd free; then
        free -h
    else
        grep -E '^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree)' /proc/meminfo
    fi
}

# sys_bios - BIOS/UEFI and mainboard details (needs dmidecode + root).
sys_bios() {
    if ! has_cmd dmidecode; then
        printf 'dmidecode is not installed.\nInstall it with: sudo apt install dmidecode\n'
        return 0
    fi
    run_privileged dmidecode -t bios -t baseboard -t system 2>&1 || \
        printf '\nCould not read DMI data (root privileges required).\n'
}

# sys_temps - Temperatures from lm-sensors, with a /sys fallback.
sys_temps() {
    if has_cmd sensors; then
        sensors 2>&1
        return 0
    fi

    # Fallback: kernel thermal zones.
    local zone type temp found=0
    for zone in /sys/class/thermal/thermal_zone*; do
        [[ -r "${zone}/temp" ]] || continue
        type="$(cat "${zone}/type")"
        temp="$(cat "${zone}/temp")"
        printf '%-20s %s.%s °C\n' "${type}:" "$(( temp / 1000 ))" "$(( (temp % 1000) / 100 ))"
        found=1
    done

    if (( ! found )); then
        printf 'No temperature sensors found.\nFor more sensors install lm-sensors: sudo apt install lm-sensors\n'
    fi
}

# sys_disks - Block devices, partitions and filesystem usage.
sys_disks() {
    printf '== Block devices ==\n'
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL 2>&1
    printf '\n== Filesystem usage ==\n'
    df -h -x tmpfs -x devtmpfs -x overlay 2>&1
}

# sys_smart - SMART health for all physical disks (needs smartmontools + root).
sys_smart() {
    if ! has_cmd smartctl; then
        printf 'smartctl is not installed.\nInstall it with: sudo apt install smartmontools\n'
        return 0
    fi

    local disk found=0
    while IFS= read -r disk; do
        found=1
        printf '== %s ==\n' "${disk}"
        run_privileged smartctl -H -i "${disk}" 2>&1 || \
            printf 'Could not read SMART data for %s.\n' "${disk}"
        printf '\n'
    done < <(lsblk -dn -o NAME,TYPE | awk '$2 == "disk" { print "/dev/" $1 }')

    if (( ! found )); then
        printf 'No physical disks found.\n'
    fi
}

# --- UI ------------------------------------------------------------------------

# _system_show <title> <collector> - Run a collector and display its output.
_system_show() {
    local title="$1"
    local collector="$2"
    local output

    log_debug "system: collecting '${collector}'"
    output="$("${collector}" 2>&1)" || true
    ui_show_text "${title}" "${output:-No data available.}"
}

# _system_full_report - All sections concatenated into one report.
_system_full_report() {
    local section
    for section in \
        "Operating system:sys_os" \
        "Kernel:sys_kernel" \
        "CPU:sys_cpu" \
        "Memory:sys_memory" \
        "BIOS / Mainboard:sys_bios" \
        "Temperatures:sys_temps" \
        "Disks:sys_disks" \
        "SMART:sys_smart"; do
        printf '########## %s ##########\n' "${section%%:*}"
        "${section#*:}" 2>&1 || true
        printf '\n'
    done
}

# module_system_main - Entry point: submenu over all system sections.
module_system_main() {
    local choice

    while true; do
        if ! choice="$(ui_menu "System Information" "Select a topic:" \
            "os"     "Operating system and Debian version" \
            "kernel" "Kernel" \
            "cpu"    "CPU" \
            "memory" "RAM and swap" \
            "bios"   "BIOS / Mainboard" \
            "temps"  "Temperatures" \
            "disks"  "Disks and filesystems" \
            "smart"  "SMART health" \
            "report" "Full report (all topics)" \
            "back"   "Back to main menu")"; then
            return 0
        fi

        case "${choice}" in
            os)     _system_show "Operating system" sys_os ;;
            kernel) _system_show "Kernel" sys_kernel ;;
            cpu)    _system_show "CPU" sys_cpu ;;
            memory) _system_show "RAM and swap" sys_memory ;;
            bios)   _system_show "BIOS / Mainboard" sys_bios ;;
            temps)  _system_show "Temperatures" sys_temps ;;
            disks)  _system_show "Disks and filesystems" sys_disks ;;
            smart)  _system_show "SMART health" sys_smart ;;
            report) _system_show "System report" _system_full_report ;;
            back)   return 0 ;;
        esac
    done
}
