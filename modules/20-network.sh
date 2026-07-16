#!/usr/bin/env bash
# DAT-MODULE
# Id: network
# Name: Network
# Description: IP, DNS, gateway, firewall, SSH, xrdp, diagnostics, port overview
# Entry: module_network_main
#
# modules/20-network.sh - Network information and diagnostics (roadmap phase 3).
#
# Mostly read-only. The connectivity and port checks talk to hosts the
# operator explicitly enters and are meant for systems the operator
# administers. Optional tools (ss/ip/ufw/systemctl) are detected at runtime.

# --- Section collectors -------------------------------------------------------

# net_ip - Interfaces and their addresses.
net_ip() {
    if has_cmd ip; then
        printf '== Interfaces and addresses ==\n'
        ip -brief address 2>/dev/null || ip address
        printf '\n== Link state ==\n'
        ip -brief link 2>/dev/null || ip link
    else
        printf 'The iproute2 "ip" command is not available.\n'
        has_cmd ifconfig && ifconfig -a
    fi
}

# net_gateway - Default gateway and routing table.
net_gateway() {
    if has_cmd ip; then
        printf '== Default route(s) ==\n'
        ip route show default 2>/dev/null || printf 'No default route.\n'
        printf '\n== Routing table ==\n'
        ip route 2>/dev/null
    else
        printf 'The iproute2 "ip" command is not available.\n'
        has_cmd route && route -n
    fi
}

# net_dns - Resolver configuration.
net_dns() {
    if has_cmd resolvectl; then
        printf '== resolvectl status ==\n'
        resolvectl status 2>&1 || true
        printf '\n'
    fi
    printf '== /etc/resolv.conf ==\n'
    if [[ -r /etc/resolv.conf ]]; then
        grep -vE '^\s*#' /etc/resolv.conf | grep -vE '^\s*$'
    else
        printf 'Not readable.\n'
    fi
}

# net_firewall - Firewall status (ufw, nftables or iptables).
net_firewall() {
    local shown=0

    if has_cmd ufw; then
        printf '== ufw ==\n'
        run_privileged ufw status verbose 2>&1 || printf 'Could not query ufw.\n'
        printf '\n'
        shown=1
    fi

    if has_cmd nft; then
        printf '== nftables ruleset ==\n'
        run_privileged nft list ruleset 2>&1 | head -n 60 || printf 'Could not query nftables.\n'
        printf '\n'
        shown=1
    elif has_cmd iptables; then
        printf '== iptables (filter) ==\n'
        run_privileged iptables -L -n -v 2>&1 | head -n 60 || printf 'Could not query iptables.\n'
        printf '\n'
        shown=1
    fi

    (( shown )) || printf 'No firewall front-end (ufw/nft/iptables) found.\n'
}

# _service_status <unit> - One-line status of a systemd unit, if systemd is used.
_service_status() {
    local unit="$1"

    if ! has_cmd systemctl; then
        printf '%-12s systemctl not available\n' "${unit}:"
        return 0
    fi

    local active enabled
    active="$(systemctl is-active "${unit}" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "${unit}" 2>/dev/null || true)"
    printf '%-14s active=%-10s enabled=%s\n' "${unit}:" "${active:-unknown}" "${enabled:-unknown}"
}

# net_ssh - SSH server status and effective key settings.
net_ssh() {
    printf '== SSH server (sshd) ==\n'
    _service_status ssh
    _service_status sshd

    if has_cmd sshd; then
        printf '\n== Effective sshd configuration (selected) ==\n'
        run_privileged sshd -T 2>/dev/null \
            | grep -iE '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|x11forwarding) ' \
            || printf 'Could not read sshd configuration (needs root).\n'
    else
        printf '\nOpenSSH server is not installed (package: openssh-server).\n'
    fi
}

# net_xrdp - xrdp remote desktop service status.
net_xrdp() {
    printf '== xrdp ==\n'
    if has_cmd xrdp || systemctl list-unit-files 2>/dev/null | grep -q '^xrdp'; then
        _service_status xrdp
        _service_status xrdp-sesman
    else
        printf 'xrdp is not installed (package: xrdp).\n'
    fi
}

# net_ports - Listening TCP/UDP sockets on this host.
net_ports() {
    if has_cmd ss; then
        printf '== Listening sockets (ss -tulpn) ==\n'
        run_privileged ss -tulpn 2>/dev/null || ss -tuln
    elif has_cmd netstat; then
        printf '== Listening sockets (netstat) ==\n'
        run_privileged netstat -tulpn 2>/dev/null || netstat -tuln
    else
        printf 'Neither ss nor netstat is available (package: iproute2).\n'
    fi
}

# --- Interactive diagnostics --------------------------------------------------

# net_ping - Ping a host the operator enters.
net_ping() {
    local host
    host="$(ui_input "Ping" "Host or IP to ping:")" || return 0
    [[ -z "${host}" ]] && return 0

    ui_show_cmd "Ping ${host}" ping -c 4 -W 2 "${host}"
}

# net_portcheck - Check whether a single TCP port is open on a host the
# operator enters. Intended for systems the operator administers.
net_portcheck() {
    local target port
    target="$(ui_input "Port check" "Target host or IP:")" || return 0
    [[ -z "${target}" ]] && return 0
    port="$(ui_input "Port check" "TCP port on ${target}:")" || return 0
    [[ "${port}" =~ ^[0-9]+$ ]] || { ui_msgbox "Port check" "Invalid port: ${port}"; return 0; }

    local result
    if has_cmd nc; then
        if nc -z -w 3 "${target}" "${port}" 2>/dev/null; then
            result="OPEN"
        else
            result="closed or filtered"
        fi
    else
        # Fallback using bash's /dev/tcp pseudo-device.
        if timeout 3 bash -c "exec 3<>/dev/tcp/${target}/${port}" 2>/dev/null; then
            result="OPEN"
        else
            result="closed or filtered"
        fi
    fi

    ui_msgbox "Port check" "${target}:${port} is ${result}."
}

# --- Report and menu ----------------------------------------------------------

# _network_show <title> <collector> - Run a collector and display its output.
_network_show() {
    local title="$1"
    local collector="$2"
    local output

    log_debug "network: collecting '${collector}'"
    output="$("${collector}" 2>&1)" || true
    ui_show_text "${title}" "${output:-No data available.}"
}

# _network_full_report - All read-only sections in one report.
_network_full_report() {
    local section
    for section in \
        "IP addresses:net_ip" \
        "Gateway and routes:net_gateway" \
        "DNS:net_dns" \
        "Firewall:net_firewall" \
        "SSH:net_ssh" \
        "xrdp:net_xrdp" \
        "Listening ports:net_ports"; do
        printf '########## %s ##########\n' "${section%%:*}"
        "${section#*:}" 2>&1 || true
        printf '\n'
    done
}

# module_network_main - Entry point: submenu over all network topics.
module_network_main() {
    local choice

    while true; do
        if ! choice="$(ui_menu "Network" "Select a topic:" \
            "ip"        "IP addresses and interfaces" \
            "gateway"   "Gateway and routing" \
            "dns"       "DNS / resolver" \
            "firewall"  "Firewall status" \
            "ssh"       "SSH server" \
            "xrdp"      "xrdp remote desktop" \
            "ports"     "Listening ports" \
            "ping"      "Ping a host" \
            "portcheck" "Check a TCP port on a host" \
            "report"    "Full report (read-only topics)" \
            "back"      "Back to main menu")"; then
            return 0
        fi

        case "${choice}" in
            ip)        _network_show "IP addresses" net_ip ;;
            gateway)   _network_show "Gateway and routing" net_gateway ;;
            dns)       _network_show "DNS / resolver" net_dns ;;
            firewall)  _network_show "Firewall status" net_firewall ;;
            ssh)       _network_show "SSH server" net_ssh ;;
            xrdp)      _network_show "xrdp remote desktop" net_xrdp ;;
            ports)     _network_show "Listening ports" net_ports ;;
            ping)      net_ping ;;
            portcheck) net_portcheck ;;
            report)    _network_show "Network report" _network_full_report ;;
            back)      return 0 ;;
        esac
    done
}
