# Modules

DAT ships six modules. Each one is a submenu; run it from the main menu or
directly with `dat <id>`.

Read-only entries never change anything. Entries that change the system are
marked **changes the system** below and always ask for confirmation first.

---

## `system` — System Information

Read-only hardware and OS inspection.

| Entry | Uses | Notes |
|-------|------|-------|
| Operating system | `/etc/os-release`, `/etc/debian_version` | distribution, hostname, arch, uptime |
| Kernel | `uname`, `/proc/cmdline` | release, version, boot command line |
| CPU | `lscpu` (falls back to `/proc/cpuinfo`) | model, cores, caches, flags |
| RAM and swap | `free` (falls back to `/proc/meminfo`) | |
| BIOS / Mainboard | `dmidecode` | needs root; needs package `dmidecode` |
| Temperatures | `sensors`, else `/sys` thermal zones | `lm-sensors` gives more sensors |
| Disks and filesystems | `lsblk`, `df` | |
| SMART health | `smartctl` per physical disk | needs root; package `smartmontools` |
| **Full report** | all of the above | one combined text report |

---

## `network` — Network

Mostly read-only; the last two entries reach out to a host you type in.

| Entry | Uses | Notes |
|-------|------|-------|
| IP addresses and interfaces | `ip -brief` (falls back to `ifconfig`) | |
| Gateway and routing | `ip route` | default route + full table |
| DNS / resolver | `resolvectl`, `/etc/resolv.conf` | |
| Firewall status | `ufw`, else `nft`, else `iptables` | needs root to read rules |
| SSH server | `systemctl`, `sshd -T` | status + effective key settings |
| xrdp | `systemctl` | reports if not installed |
| Listening ports | `ss` (falls back to `netstat`) | root shows owning processes |
| Ping a host | `ping -c 4` | prompts for a host |
| Check a TCP port | `nc`, else bash `/dev/tcp` | prompts for host + port |
| **Full report** | the read-only entries | one combined text report |

> The ping and port check target a host you enter and are meant for systems
> you administer.

---

## `desktop` — Desktop

Acts on **your user session only** — never system-wide. Changes are
reversible from the same menu.

| Entry | Uses | Notes |
|-------|------|-------|
| Desktop environment info | `XDG_*`, process probing | detects GNOME / KDE / XFCE |
| Theme, icons, cursor, fonts | `gsettings` (GNOME), `xfconf-query` (XFCE) | KDE: pointers to its tools |
| Installed fonts | `fc-list` | package `fontconfig` |
| Dark mode | GNOME `color-scheme`, KDE `plasma-apply-colorscheme` | **changes the session** |
| Animations | GNOME `enable-animations` | **changes the session**; off = faster |

---

## `software` — Software

Guided installation. Every install asks first, runs `apt` as root, and is
skipped if the program is already present.

| Entry | Source |
|-------|--------|
| Show installation status | read-only overview of all entries below |
| Git | Debian repo |
| Python 3 (pip, venv) | Debian repo |
| VS Code | Microsoft APT repo (key + source list added) |
| Docker CE | Docker APT repo (key + source list added) |
| Google Chrome | Google APT repo (key + source list added) |
| Firefox ESR | Debian repo |
| VLC | Debian repo |

> VS Code, Docker and Chrome add a third-party APT repository and its
> signing key to your system. **Changes the system.**

---

## `maintenance` — Maintenance

| Entry | Notes |
|-------|-------|
| Refresh package lists | `apt-get update`, then shows what is upgradable |
| Install upgrades | lists pending packages, then `apt-get upgrade` — **changes the system** |
| Remove orphaned packages | `apt-get autoremove` — **changes the system** |
| Clean apt cache | `apt-get clean` — **changes the system** |
| Journal status | disk usage + last 20 errors |
| Shrink the journal | `journalctl --vacuum-size` — **changes the system** |
| Disk usage analysis | `df` plus the largest top-level directories |
| Backup `/etc` | timestamped `tar.gz` into a directory you choose |

---

## `reports` — Reports

Generates self-contained **HTML** files you can open in a browser, archive
or send on. Output goes to a directory you choose (default
`~/dat-reports`), named `<report>-<hostname>-<timestamp>.html`.

| Entry | Contents |
|-------|----------|
| Hardware inventory | OS, kernel, CPU, memory, BIOS, temperatures, disks, SMART |
| Network inventory | addresses, routing, DNS, firewall, SSH, listening ports |
| Full diagnostic report | hardware + network combined |

Reports reuse the same collectors as the `system` and `network` modules, so
they always match what the menus show. All command output is HTML-escaped,
and the styling adapts to light and dark browsers.

---

## Adding your own

Any `.sh` file you drop into `plugins/` shows up here too — see
[[Writing Plugins]].
