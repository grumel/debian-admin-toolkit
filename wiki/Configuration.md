# Configuration

DAT reads simple `KEY=VALUE` files. They are **parsed, never executed**, so a
config file cannot run code. Unknown or invalid keys are ignored with a
warning rather than breaking the toolkit.

## Where configuration lives

Files are read in this order — later files override earlier ones:

| # | Path | Purpose |
|---|------|---------|
| 1 | `<install dir>/config/dat.conf` | shipped defaults — **do not edit** |
| 2 | `/etc/dat/dat.conf` | system-wide overrides |
| 3 | `~/.config/dat/dat.conf` | per-user overrides |

For a package install the shipped defaults are at
`/opt/debian-admin-toolkit/config/dat.conf`.

## Keys

```ini
# Minimum log level: debug | info | warn | error
DAT_LOG_LEVEL=info

# Log directory. Empty = built-in default (see below).
DAT_LOG_DIR=

# UI backend: auto | whiptail | text
DAT_UI_BACKEND=auto
```

### `DAT_LOG_LEVEL`

How much is written to the log file and shown on the terminal.
`debug` is verbose and useful when reporting a problem. The `--debug`
command line flag sets this for a single run without editing any file.

### `DAT_LOG_DIR`

Where `dat.log` is written. When empty, DAT uses:

1. `<install dir>/logs/` if writable, otherwise
2. `~/.local/state/dat/` (the normal case for `/opt` and package installs).

If neither is writable, file logging is silently skipped — the toolkit keeps
working and still prints to the terminal.

### `DAT_UI_BACKEND`

| Value | Behaviour |
|-------|-----------|
| `auto` | use whiptail on an interactive terminal, otherwise plain text |
| `whiptail` | always use whiptail dialogs |
| `text` | always use the numbered plain-text menu |

`text` is useful over serial consoles, in containers, and when piping input
for testing.

## Examples

**System-wide, verbose logging into a central directory** —
`/etc/dat/dat.conf`:

```ini
DAT_LOG_LEVEL=debug
DAT_LOG_DIR=/var/log/dat
```

Make sure the directory is writable by whoever runs `dat`.

**Per-user, always plain text** — `~/.config/dat/dat.conf`:

```ini
DAT_UI_BACKEND=text
```

## One-off overrides

Environment variables work for a single run without touching any file:

```bash
DAT_UI_BACKEND=text dat system
dat --debug network
```

## Checking what is active

Run with `--debug`; the startup lines report the chosen UI backend, the
discovered modules and the install root:

```bash
dat --debug --list
```

```text
[debug] UI backend: whiptail (94x30)
[debug] Registered module 'system' from /opt/debian-admin-toolkit/modules/10-system.sh
...
[debug] Debian Admin Toolkit 1.0.0 started (root: /opt/debian-admin-toolkit)
```

An invalid key or value in a config file is reported as a `[warn]` line at
startup, whatever the log level.
