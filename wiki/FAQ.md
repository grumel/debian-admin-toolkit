# FAQ

### Which Debian versions are supported?

Debian 12 (Bookworm) and Debian 13 (Trixie), on desktops and servers. DAT is
plain Bash 5 and standard Debian tools, so it generally works on Debian
derivatives too — but only Debian 12/13 are tested.

### Does DAT change my system without asking?

No. Inspection is read-only. Every entry that changes something — apt
installs, upgrades, autoremove, journal vacuum, dark mode, animations — asks
for confirmation first. The `system`, `network` and `reports` modules never
change anything at all.

### Do I need to run it with sudo?

No. Run `dat` as your normal user; it calls `sudo` only for the individual
steps that need root, and sudo prompts you itself. Avoid `sudo dat`.

### Does it work on a headless server?

Yes. whiptail runs in any terminal, including over SSH. Without whiptail, or
over a serial console, DAT falls back to a plain-text menu automatically
(`DAT_UI_BACKEND=text`).

### Can I run one module non-interactively?

You can jump straight to a module with `dat system`, but the modules are
menu-driven by design. For scripting, call the underlying tools directly, or
write a plugin — see [[Writing Plugins]].

### How do I add my own feature?

Copy one `.sh` file with a `# DAT-MODULE` header into `plugins/`. That's the
whole process — see [[Writing Plugins]].

### Where do the HTML reports go?

To a directory you choose when generating them, `~/dat-reports` by default,
as `<report>-<hostname>-<timestamp>.html`. They are self-contained: open,
archive or send them as-is.

### Is my data sent anywhere?

No. DAT runs entirely locally and has no telemetry. Reports are written to
your disk only. The only network access is what you explicitly trigger:
`apt` installs, the vendor repositories for VS Code/Docker/Chrome, and the
ping/port checks against hosts you type in.

### Why does installing VS Code, Docker or Chrome add a repository?

Those programs are not in Debian's repositories. DAT adds the vendor's
official APT repository and signing key so that the program receives updates
through normal `apt upgrade`. This is the same procedure the vendors
document, and it happens only after you confirm.

### Does DAT update itself?

No. Update it the way you installed it: `apt` for the `.deb`, or
`git pull` plus `./install.sh` for a source install.

### Can I keep my configuration when uninstalling?

Yes — both `uninstall.sh` and `apt remove` deliberately leave `/etc/dat` and
`~/.config/dat` in place.

### What is the difference between the `.deb` and `install.sh`?

The `.deb` is the recommended route: apt resolves dependencies, adds
`/usr/bin/dat` and a `man dat` page, and handles removal. `install.sh` is
for running from a git checkout, and additionally offers a per-user install
(`--user`) that needs no root.

### How is it licensed?

[MIT](https://github.com/grumel/debian-admin-toolkit/blob/main/LICENSE) —
free to use, modify and redistribute.

### Where do I report bugs or ask for features?

On the
[issue tracker](https://github.com/grumel/debian-admin-toolkit/issues). See
[[Troubleshooting]] for the details worth including.
