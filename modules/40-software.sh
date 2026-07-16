#!/usr/bin/env bash
# DAT-MODULE
# Id: software
# Name: Software
# Description: Install common tools (Git, VS Code, Docker, Python, browsers, VLC)
# Entry: module_software_main
#
# modules/40-software.sh - Guided installation of common software
# (roadmap phase 5).
#
# Every install runs through apt as root (via run_privileged) and only after
# the operator confirms it. Packages that require a third-party APT
# repository (VS Code, Docker, Google Chrome) set up the vendor key and
# source list first. Already-installed software is detected and skipped.

# --- Helpers ------------------------------------------------------------------

# sw_apt_installed <package> - Return 0 if a .deb package is installed.
sw_apt_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

# sw_apt_update - Refresh the package lists (once per module run).
sw_apt_update() {
    if [[ -z "${_SW_APT_UPDATED:-}" ]]; then
        log_info "Running apt-get update"
        run_privileged apt-get update -qq || return 1
        _SW_APT_UPDATED=1
    fi
}

# sw_apt_install <package...> - Update lists and install packages.
sw_apt_install() {
    sw_apt_update || return 1
    log_info "Installing: $*"
    run_privileged env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

# sw_confirm_install <name> - Ask for confirmation before installing <name>.
# Returns 0 to proceed, 1 to abort.
sw_confirm_install() {
    ui_yesno "Install ${1}" "Install ${1} now? This uses apt and requires root privileges."
}

# sw_run_install <name> <check-cmd-or-pkg> <installer-fn> - Shared flow:
# report if already present, confirm, run installer, show the result.
sw_run_install() {
    local name="$1"
    local check="$2"
    local installer="$3"

    if has_cmd "${check}" || sw_apt_installed "${check}"; then
        ui_msgbox "${name}" "${name} appears to be installed already."
        return 0
    fi

    sw_confirm_install "${name}" || return 0

    local output
    if output="$("${installer}" 2>&1)"; then
        ui_show_text "${name}" "Installation finished.

${output}"
    else
        ui_show_text "${name}" "Installation failed.

${output}"
    fi
}

# --- Plain apt installers -----------------------------------------------------

_install_git()    { sw_apt_install git; }
_install_python() { sw_apt_install python3 python3-pip python3-venv; }
_install_vlc()    { sw_apt_install vlc; }
# Debian ships Firefox ESR in the main repositories.
_install_firefox() { sw_apt_install firefox-esr; }

# --- Third-party repository installers -----------------------------------------

# _install_vscode - Microsoft VS Code from the official Microsoft APT repo.
_install_vscode() {
    sw_apt_install wget gpg apt-transport-https || return 1

    local keyring="/usr/share/keyrings/packages.microsoft.gpg"
    local list="/etc/apt/sources.list.d/vscode.list"

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | run_privileged tee "${keyring}" >/dev/null || return 1

    printf 'deb [arch=amd64,arm64,armhf signed-by=%s] https://packages.microsoft.com/repos/code stable main\n' \
        "${keyring}" | run_privileged tee "${list}" >/dev/null || return 1

    _SW_APT_UPDATED=""  # new repo added: force a refresh
    sw_apt_install code
}

# _install_docker - Docker CE from Docker's official APT repo (Debian).
_install_docker() {
    sw_apt_install ca-certificates curl || return 1

    local keyring="/etc/apt/keyrings/docker.asc"
    local list="/etc/apt/sources.list.d/docker.list"

    run_privileged install -m 0755 -d /etc/apt/keyrings || return 1
    run_privileged curl -fsSL https://download.docker.com/linux/debian/gpg -o "${keyring}" || return 1
    run_privileged chmod a+r "${keyring}" || return 1

    local arch codename
    arch="$(dpkg --print-architecture)"
    # shellcheck disable=SC1091
    codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME}")"

    printf 'deb [arch=%s signed-by=%s] https://download.docker.com/linux/debian %s stable\n' \
        "${arch}" "${keyring}" "${codename}" \
        | run_privileged tee "${list}" >/dev/null || return 1

    _SW_APT_UPDATED=""  # new repo added: force a refresh
    sw_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# _install_chrome - Google Chrome stable from Google's official APT repo.
_install_chrome() {
    sw_apt_install wget gpg || return 1

    local keyring="/usr/share/keyrings/google-chrome.gpg"
    local list="/etc/apt/sources.list.d/google-chrome.list"

    wget -qO- https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor \
        | run_privileged tee "${keyring}" >/dev/null || return 1

    printf 'deb [arch=amd64 signed-by=%s] https://dl.google.com/linux/chrome/deb/ stable main\n' \
        "${keyring}" | run_privileged tee "${list}" >/dev/null || return 1

    _SW_APT_UPDATED=""  # new repo added: force a refresh
    sw_apt_install google-chrome-stable
}

# --- Status overview ----------------------------------------------------------

# sw_status - Show which of the managed programs are installed.
sw_status() {
    printf '%-14s %-12s %s\n' "Program" "Installed" "Version / command"
    printf '%-14s %-12s %s\n' "-------" "---------" "-----------------"

    _sw_status_row "Git"      git      "git --version"
    _sw_status_row "Python 3" python3  "python3 --version"
    _sw_status_row "VS Code"  code     "code --version"
    _sw_status_row "Docker"   docker   "docker --version"
    _sw_status_row "Chrome"   google-chrome-stable "google-chrome --version"
    _sw_status_row "Firefox"  firefox-esr "firefox-esr --version"
    _sw_status_row "VLC"      vlc      "vlc --version"
}

# _sw_status_row <label> <cmd-or-pkg> <version-cmd> - One status line.
_sw_status_row() {
    local label="$1" probe="$2" version_cmd="$3"
    local state="no" version="-"

    if has_cmd "${probe}" || sw_apt_installed "${probe}"; then
        state="yes"
        # Intentional word splitting: version_cmd is "command arg" from a
        # trusted literal above, not user input.
        # shellcheck disable=SC2086
        version="$(${version_cmd} 2>/dev/null | head -n 1 || printf '-')"
    fi
    printf '%-14s %-12s %s\n' "${label}" "${state}" "${version}"
}

# --- Menu ---------------------------------------------------------------------

# module_software_main - Entry point: submenu of installable programs.
module_software_main() {
    local choice

    while true; do
        if ! choice="$(ui_menu "Software" "Select software to install:" \
            "status"  "Show installation status" \
            "git"     "Git" \
            "python"  "Python 3 (pip, venv)" \
            "vscode"  "Visual Studio Code" \
            "docker"  "Docker CE" \
            "chrome"  "Google Chrome" \
            "firefox" "Firefox ESR" \
            "vlc"     "VLC media player" \
            "back"    "Back to main menu")"; then
            return 0
        fi

        case "${choice}" in
            status)  ui_show_cmd "Software status" sw_status ;;
            git)     sw_run_install "Git" git _install_git ;;
            python)  sw_run_install "Python 3" python3 _install_python ;;
            vscode)  sw_run_install "Visual Studio Code" code _install_vscode ;;
            docker)  sw_run_install "Docker CE" docker _install_docker ;;
            chrome)  sw_run_install "Google Chrome" google-chrome-stable _install_chrome ;;
            firefox) sw_run_install "Firefox ESR" firefox-esr _install_firefox ;;
            vlc)     sw_run_install "VLC" vlc _install_vlc ;;
            back)    return 0 ;;
        esac
    done
}
