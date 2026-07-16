# Usage

## Interactive menu

Start the toolkit with no arguments to get the whiptail main menu, which
lists every installed module plus any plugins:

```bash
dat
```

Navigate with the **arrow keys**, confirm with **Enter**, and leave a dialog
with **Esc** or *Cancel*. Cancelling a submenu returns you to the main menu;
cancelling the main menu exits.

## Command line options

| Option | Effect |
|--------|--------|
| *(none)* | Start the interactive main menu |
| `<module-id>` | Run a single module directly, e.g. `dat system` |
| `--list`, `-l` | List available modules and plugins, then exit |
| `--version`, `-V` | Print the version, then exit |
| `--debug` | Enable debug logging for this run |
| `--help`, `-h` | Show usage |

```bash
dat --list
```

```text
system       System Information       Debian version, kernel, CPU, RAM, BIOS, ...
network      Network                  IP, DNS, gateway, firewall, SSH, xrdp, ...
desktop      Desktop                  Desktop environment, themes, fonts, ...
software     Software                 Install common tools (Git, VS Code, ...)
maintenance  Maintenance              apt update/upgrade/autoremove, journal, ...
reports      Reports                  Generate HTML hardware, network and ...
```

## Running a single module

Handy for scripts, SSH one-liners and shortcuts — it skips the main menu and
opens that module's submenu directly:

```bash
dat system
dat network
dat reports
```

See [[Modules]] for what each one offers.

## Root privileges

DAT runs as a normal user. Individual actions that need root (reading BIOS
data via `dmidecode`, SMART health, `apt` installs, journal vacuum) call
`sudo` only for that step, and you are prompted for your password by sudo
itself. Nothing needs `sudo dat`.

If a feature needs root and sudo is unavailable, you get a clear message
rather than a crash.

## Text mode instead of whiptail

On a minimal server, a serial console, or in a container without whiptail,
DAT automatically falls back to a numbered plain-text menu. You can force
either backend:

```bash
DAT_UI_BACKEND=text dat
DAT_UI_BACKEND=whiptail dat
```

See [[Configuration]] to make that permanent.

## Logging

Every run logs to a file and prints warnings and errors to the terminal.
Use `--debug` for verbose output:

```bash
dat --debug system
```

Log location, in order of preference:

1. `<install dir>/logs/dat.log`
2. `~/.local/state/dat/dat.log` (when the install directory is not writable,
   which is the normal case for a `/opt` or package install)

## Manual page

The `.deb` package ships a manual page:

```bash
man dat
```
