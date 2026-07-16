# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- User handbook as wiki sources under `wiki/` (Home, Installation, Usage,
  Modules, Configuration, Writing Plugins, Troubleshooting, FAQ, sidebar),
  versioned and reviewable in the repository
- `scripts/sync-wiki.sh` to publish `wiki/` to the GitHub wiki, with a
  `--dry-run` mode. Authenticates via `GITHUB_TOKEN` when set (for CI) and
  via the local git credential helper otherwise

### Fixed
- `--debug` now also logs the configuration loading. The flag was applied
  after `config_load`, so the `Loading configuration from ...` messages were
  never emitted. It is now applied before *and* after loading, so the flag
  still beats a `DAT_LOG_LEVEL` set in a config file

## [1.0.0] - 2026-07-16

First stable release. Complete modular toolkit covering system, network,
desktop, software, maintenance and reporting, with a plugin system, CI and
packaging (source tarball and `.deb`).

### Added
- Debian package build (`packaging/build-deb.sh`, `packaging/deb/control.in`)
  installing to `/opt/debian-admin-toolkit` with a `/usr/bin/dat` launcher
  and a `dat(1)` manual page (`docs/dat.1`); the release workflow attaches
  the `.deb` alongside the source tarball
- Release automation: `packaging/build-tarball.sh` builds a clean source
  tarball, and `.github/workflows/release.yml` runs on version tags to lint,
  test, verify the tag matches `VERSION`, build the tarball, extract the
  changelog section and publish a GitHub Release. Documented in
  `docs/releasing.md`
- Reports module (`modules/60-reports.sh`): generate self-contained HTML
  reports — hardware inventory, network inventory and a combined diagnostic
  report — saved to a chosen directory. Reports reuse the read-only
  collector functions from the system and network modules (no duplication)
  and HTML-escape all command output
- Plugin system polish: example plugin template
  (`plugins/hello.sh.example`, inactive until copied to `.sh`) and a
  dedicated plugin test suite (`tests/test_plugins.sh`) that verifies
  drop-in discovery, execution, skipping of broken/duplicate plugins and
  that the template is not auto-loaded
- Maintenance module (`modules/50-maintenance.sh`): refresh package lists,
  install upgrades, autoremove orphaned packages, clean the apt cache,
  inspect and vacuum the systemd journal, analyse disk usage (df plus the
  largest directories), and create timestamped tar.gz backups of `/etc`.
  System-changing tasks run via sudo only after an explicit confirmation
- Software module (`modules/40-software.sh`): guided installation of Git,
  Python 3 (pip/venv), VS Code, Docker CE, Google Chrome, Firefox ESR and
  VLC, plus an installation-status overview. Third-party programs (VS Code,
  Docker, Chrome) set up the vendor APT key and source list first. Every
  install runs via apt as root only after an explicit confirmation, and
  already-installed software is detected and skipped
- Desktop module (`modules/30-desktop.sh`): detects the desktop environment
  (GNOME/KDE/XFCE), reports theme/icon/cursor/font settings and installed
  fonts, and offers reversible per-user tweaks for dark mode and animations
  (GNOME via gsettings; KDE via plasma-apply tools when present). Operates on
  the current user's session only, never on system-wide configuration
- Network module (`modules/20-network.sh`): IP addresses and interfaces,
  gateway and routing, DNS/resolver, firewall status (ufw/nftables/iptables),
  SSH server status and effective config, xrdp service, listening ports
  (ss/netstat), plus interactive ping and single-port TCP checks, and a
  combined read-only report
- `ui_input` dialog helper (whiptail inputbox with text fallback)
- System information module (`modules/10-system.sh`): Debian/OS release,
  kernel, CPU, RAM/swap, BIOS and mainboard (dmidecode), temperatures
  (lm-sensors with a `/sys` thermal-zone fallback), disks and filesystems,
  and SMART health (smartmontools). Read-only; optional tools are detected
  at runtime and missing ones produce a hint instead of an error
- Framework libraries: core helpers, leveled logging, safe config parsing,
  whiptail UI with plain-text fallback, module/plugin loader (`lib/`)
- Main entry point `admin.sh` with `--help`, `--version`, `--list`,
  `--debug` and direct module execution
- Plugin system: drop a single `.sh` file with a `# DAT-MODULE` header into
  `plugins/` to extend the toolkit
- Installer (`install.sh`) with system-wide (`/opt` + `/usr/local/bin/dat`)
  and per-user (`--user`) modes; matching `uninstall.sh`
- Default configuration `config/dat.conf` with system-wide and per-user
  override locations
- Test suite (`tests/`) with syntax, framework and CLI checks
- GitHub Actions CI: ShellCheck and tests on every push and pull request
- Documentation: architecture overview, module developer guide and release
  guide (`docs/`)

## [0.1.0-dev] - 2026-07-16

### Added
- Initial repository structure
- VERSION file
- Initial README
- MIT license
