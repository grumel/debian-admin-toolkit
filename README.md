# Debian Admin Toolkit (DAT)

[![CI](https://github.com/grumel/debian-admin-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/grumel/debian-admin-toolkit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A modular administration toolkit for **Debian 12 (Bookworm)** and
**Debian 13 (Trixie)**, for desktops and servers. One `dat` command, a
whiptail menu, and a plugin system: drop a single file into `plugins/` and
it appears in the menu.

> ✅ **Version 1.0** — all roadmap phases complete. See the [roadmap](#roadmap).

## Features

- **Modular**: small framework (`lib/`), independent feature modules
  (`modules/`), drop-in plugins (`plugins/`)
- **Terminal UI**: whiptail menus with an automatic plain-text fallback
- **Safe configuration**: `KEY=VALUE` files that are parsed, never sourced,
  with system-wide and per-user overrides
- **Logging**: leveled logging to file and terminal
- **Quality gates**: ShellCheck and a test suite run in CI on every push

## Installation

### Debian package (recommended)

Download the `.deb` from the [latest release](https://github.com/grumel/debian-admin-toolkit/releases)
and install it — this pulls in dependencies, adds the `dat` launcher and a
`dat(1)` man page:

```bash
sudo apt install ./debian-admin-toolkit_<version>_all.deb
```

### From source

```bash
git clone https://github.com/grumel/debian-admin-toolkit.git
cd debian-admin-toolkit

# System-wide (files in /opt, launcher /usr/local/bin/dat):
sudo ./install.sh

# ... or per user (no root, launcher ~/.local/bin/dat):
./install.sh --user
```

Uninstall the source install with `sudo ./uninstall.sh` (or
`./uninstall.sh --user`); remove the package with
`sudo apt remove debian-admin-toolkit`.

## Usage

```bash
dat              # interactive main menu
dat --list       # list available modules and plugins
dat <module-id>  # run one module directly, e.g. later: dat system
dat --debug      # verbose logging for this run
```

Running from a source checkout without installing also works:
`./admin.sh`.

## Configuration

Defaults ship in [config/dat.conf](config/dat.conf). Override them in
`/etc/dat/dat.conf` (system-wide) or `~/.config/dat/dat.conf` (per user):

```ini
DAT_LOG_LEVEL=info      # debug | info | warn | error
DAT_UI_BACKEND=auto     # auto | whiptail | text
```

## Extending

Copy one `.sh` file into `plugins/` — done. Format and rules:
[docs/modules.md](docs/modules.md). Architecture overview:
[docs/architecture.md](docs/architecture.md).

## Roadmap

| Phase | Scope                                                            | Status |
|-------|------------------------------------------------------------------|--------|
| 1     | Repository, framework, installer                                 | ✅     |
| 2     | System module (OS, kernel, CPU, RAM, BIOS, temps, disks, SMART)  | ✅     |
| 3     | Network (IP, DNS, firewall, SSH, xrdp, diagnostics, port scan)   | ✅     |
| 4     | Desktop (GNOME, KDE, XFCE, themes, fonts, dark mode)             | ✅     |
| 5     | Software installation (Git, VS Code, Docker, browsers, …)        | ✅     |
| 6     | Maintenance (updates, cleanup, journal, backups)                 | ✅     |
| 7     | Plugin system polish                                             | ✅     |
| 8     | HTML reports (hardware, network, diagnostics)                    | ✅     |
| 9     | CI/CD releases                                                   | ✅     |
| 10    | Version 1.0: deb package, man page, release                      | ✅     |

## Development

```bash
bash tests/run_tests.sh                 # run the test suite
find . -name '*.sh' -not -path './.git/*' -exec \
    shellcheck --shell=bash --external-sources {} +
```

Contributions follow [Semantic Versioning](https://semver.org/) and
[Keep a Changelog](https://keepachangelog.com/). Every commit must be
ShellCheck-clean and pass the test suite.

## License

[MIT](LICENSE)
