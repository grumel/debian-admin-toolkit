# Debian Admin Toolkit

Welcome to the **Debian Admin Toolkit (DAT)** handbook.

DAT is a modular, whiptail-based administration toolkit for **Debian 12
(Bookworm)** and **Debian 13 (Trixie)**, usable on desktops and servers.
Everything runs from one command:

```bash
dat
```

**Current release:** [v1.0.0](https://github.com/grumel/debian-admin-toolkit/releases/tag/v1.0.0)

## Start here

| Page | What it covers |
|------|----------------|
| [[Installation]] | `.deb` package, source install, requirements, uninstall |
| [[Usage]] | The main menu, command line options, running a single module |
| [[Modules]] | What each built-in module does |
| [[Configuration]] | Config files, log levels, UI backend |
| [[Writing Plugins]] | Extend DAT by dropping in one file |
| [[Troubleshooting]] | Missing tools, sudo, logs, whiptail issues |
| [[FAQ]] | Short answers to common questions |

## What DAT does

- **System** — Debian release, kernel, CPU, RAM, BIOS, temperatures, disks, SMART
- **Network** — addresses, routing, DNS, firewall, SSH, xrdp, listening ports, ping, port checks
- **Desktop** — environment detection, themes/fonts, dark mode, animations
- **Software** — guided installs: Git, Python, VS Code, Docker, Chrome, Firefox, VLC
- **Maintenance** — updates, autoremove, journal, disk usage, `/etc` backups
- **Reports** — HTML hardware, network and diagnostic reports
- **Plugins** — copy one `.sh` file into `plugins/` and it appears in the menu

## Design principles

- **Read-only by default.** Inspection never changes the system. Anything
  that does change something asks first.
- **Degrades gracefully.** Optional tools (`dmidecode`, `smartctl`,
  `sensors`, …) are detected at runtime; if one is missing you get an
  install hint, not an error.
- **Works without a GUI.** whiptail menus on a terminal, with an automatic
  plain-text fallback for minimal servers and serial consoles.

## Developer documentation

Deeper, code-level docs live in the repository:

- [docs/architecture.md](https://github.com/grumel/debian-admin-toolkit/blob/main/docs/architecture.md) — framework internals and startup sequence
- [docs/modules.md](https://github.com/grumel/debian-admin-toolkit/blob/main/docs/modules.md) — module/plugin format reference
- [docs/releasing.md](https://github.com/grumel/debian-admin-toolkit/blob/main/docs/releasing.md) — CI and release process

## License

[MIT](https://github.com/grumel/debian-admin-toolkit/blob/main/LICENSE)
