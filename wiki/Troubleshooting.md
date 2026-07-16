# Troubleshooting

## `dat: command not found`

**After a per-user install** (`./install.sh --user`) the launcher lands in
`~/.local/bin`, which is not always on your `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
exec bash
```

**After a source or package install**, check the launcher exists:

```bash
ls -l /usr/bin/dat /usr/local/bin/dat 2>/dev/null
```

You can always run the toolkit directly from a checkout with `./admin.sh`.

## The menu looks broken / no dialogs appear

DAT needs `whiptail` for the graphical menu:

```bash
sudo apt install whiptail
```

Without it (or over a serial console, in a container, or when input is
piped) DAT falls back to a numbered plain-text menu automatically. You can
force it:

```bash
DAT_UI_BACKEND=text dat
```

If whiptail renders but looks cramped, enlarge the terminal — dialogs size
themselves to the window.

## "Required command 'x' not found"

Optional features need optional tools. Install what the message names:

| Feature | Package |
|---------|---------|
| BIOS / mainboard details | `dmidecode` |
| Temperatures (full sensor set) | `lm-sensors` |
| SMART health | `smartmontools` |
| Addresses, routes, listening ports | `iproute2` |
| Installed fonts | `fontconfig` |
| Building a `.deb` yourself | `dpkg-dev` |

Everything else keeps working — DAT never aborts because an optional tool is
absent.

## "This action requires root privileges"

Some entries (BIOS, SMART, firewall rules, apt installs, journal vacuum)
must run as root. DAT calls `sudo` only for that single step; sudo asks for
your password itself.

- Do **not** run `sudo dat` — it is not needed and makes new files
  root-owned.
- If `sudo` is not installed, run those entries from a root shell instead.

## Temperatures show nothing useful

Without `lm-sensors` DAT falls back to the kernel's thermal zones, which
often expose only one or two values. For the full picture:

```bash
sudo apt install lm-sensors
sudo sensors-detect      # answer the questions, then re-run dat
```

## SMART reports "Unable to detect device type"

Common for USB enclosures and some NVMe drives. Test the device directly to
see the underlying error:

```bash
sudo smartctl -H -i /dev/sda
```

Virtual disks (VMs, cloud) usually have no SMART data at all — that is
expected.

## Disk usage analysis fails or takes very long

It walks the filesystem as root. If sudo cannot authenticate
non-interactively it reports that it could not analyse usage. On very large
filesystems the scan simply takes a while — the `df` section above it is
instant.

## An upgrade or install failed

The dialog shows apt's own output, which names the real cause (held
packages, no network, a broken third-party repo). Reproduce it directly:

```bash
sudo apt update
sudo apt upgrade
```

## Where are the logs?

In order of preference:

1. `<install dir>/logs/dat.log`
2. `~/.local/state/dat/dat.log` — the normal location for `/opt` and package
   installs

Get more detail with:

```bash
dat --debug <module>
tail -f ~/.local/state/dat/dat.log
```

## A plugin does not show up

- Does the filename end in `.sh` and sit in `plugins/`?
- Does it have the `# DAT-MODULE` header **within the first 20 lines**, with
  `Id`, `Name` and `Entry`?
- Is the `Id` unique and of the form `[a-z][a-z0-9-]*`?

`dat --list` prints a warning naming the exact reason a file was skipped,
for example:

```text
[warn] Skipping module '/opt/debian-admin-toolkit/plugins/zz-broken.sh': incomplete metadata header.
```

Add `--debug` to also see every module that *was* registered. See
[[Writing Plugins]].

## Reporting a bug

Open an
[issue](https://github.com/grumel/debian-admin-toolkit/issues) and include:

```bash
dat --version
cat /etc/debian_version
dat --debug <module-that-failed>
```

plus the relevant lines from the log.
