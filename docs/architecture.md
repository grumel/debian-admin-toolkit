# Architecture

The Debian Admin Toolkit (DAT) is a modular Bash application for Debian 12
and Debian 13. It separates a small, stable framework from replaceable
feature modules.

## Layout

```text
debian-admin-toolkit/
├── admin.sh          Entry point: argument parsing, framework init, main menu
├── install.sh        System-wide or per-user installer (creates the `dat` launcher)
├── uninstall.sh      Uninstaller
├── config/           Shipped default configuration (dat.conf)
├── docs/             Project documentation
├── lib/              Framework libraries (sourced, never executed)
│   ├── core.sh       Constants, version, command/privilege helpers, tmpdir
│   ├── log.sh        Leveled logging to file and terminal
│   ├── config.sh     Safe KEY=VALUE config parsing with override order
│   ├── ui.sh         whiptail dialogs with plain-text fallback
│   └── modules.sh    Module/plugin discovery and execution
├── logs/             Default log location for a from-source checkout
├── modules/          Built-in feature modules
├── plugins/          Drop-in user modules (same format as modules/)
└── tests/            Test runner and test suites
```

## Startup sequence

1. `admin.sh` resolves `DAT_ROOT` (following symlinks, so the `dat`
   launcher works) and sources the libraries in a fixed order:
   core → log → config → ui → modules.
2. Command line arguments are parsed.
3. `config_load` reads `config/dat.conf`, then `/etc/dat/dat.conf`, then
   `~/.config/dat/dat.conf` (later files override earlier ones).
4. `log_init` picks a writable log file, `ui_init` selects the UI backend.
5. `modules_discover` scans `modules/` and `plugins/` for metadata headers.
6. Depending on the arguments, a single module runs directly or the
   whiptail main menu starts.

## Design rules

- **Libraries are pure**: files in `lib/` only define functions and
  variables; they never produce output or side effects when sourced.
- **Config is data, not code**: configuration files are parsed line by
  line and validated; they are never `source`d.
- **Modules are isolated**: a module is only sourced when it runs. A broken
  plugin is skipped with a warning and cannot take down the toolkit.
- **Everything observable is logged**: modules use `log_*`; errors surface
  in the UI and in the log file.
- **ShellCheck-clean**: CI rejects any script with ShellCheck findings.

## Error handling

`admin.sh` runs with `set -euo pipefail`. Expected failures (user cancels a
dialog, an optional tool is missing) are handled explicitly and reported via
the UI and the log; unexpected failures terminate with a non-zero exit code.
