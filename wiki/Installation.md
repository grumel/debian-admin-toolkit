# Installation

DAT supports Debian 12 (Bookworm) and Debian 13 (Trixie), on desktops and
servers.

## Requirements

| | |
|---|---|
| **Required** | `bash` (>= 5.0), `whiptail` (package `whiptail`) |
| **Recommended** | `dmidecode`, `lm-sensors`, `smartmontools`, `iproute2`, `fontconfig` |

The recommended tools are only needed by individual features. If one is
missing, the affected menu entry tells you which package to install instead
of failing.

## Option 1: Debian package (recommended)

Download the `.deb` from the
[latest release](https://github.com/grumel/debian-admin-toolkit/releases)
and install it with `apt`, which pulls in the dependencies:

```bash
sudo apt install ./debian-admin-toolkit_1.0.0_all.deb
```

This installs:

| Path | Contents |
|------|----------|
| `/opt/debian-admin-toolkit` | the toolkit itself |
| `/usr/bin/dat` | launcher (symlink to `admin.sh`) |
| `/usr/share/man/man1/dat.1.gz` | manual page (`man dat`) |

Remove it again with:

```bash
sudo apt remove debian-admin-toolkit
```

## Option 2: From source

```bash
git clone https://github.com/grumel/debian-admin-toolkit.git
cd debian-admin-toolkit
```

**System-wide** (files in `/opt/debian-admin-toolkit`, launcher
`/usr/local/bin/dat`):

```bash
sudo ./install.sh
```

**Per user** (no root; files in `~/.local/share/debian-admin-toolkit`,
launcher `~/.local/bin/dat`):

```bash
./install.sh --user
```

If `dat` is not found after a per-user install, add `~/.local/bin` to your
`PATH`.

Uninstall with `sudo ./uninstall.sh` or `./uninstall.sh --user`.
Configuration in `/etc/dat` and `~/.config/dat` is deliberately kept.

## Option 3: Run without installing

The toolkit runs straight from a checkout:

```bash
./admin.sh
```

## Verify

```bash
dat --version   # -> 1.0.0
dat --list      # lists the available modules
```

## Building packages yourself

```bash
bash packaging/build-tarball.sh dist   # source tarball
bash packaging/build-deb.sh dist       # .deb (needs dpkg-dev)
```

See [[Usage]] next, or
[docs/releasing.md](https://github.com/grumel/debian-admin-toolkit/blob/main/docs/releasing.md)
for the full release process.
