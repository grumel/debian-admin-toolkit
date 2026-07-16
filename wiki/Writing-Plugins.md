# Writing Plugins

Extending DAT takes exactly one step: **copy a `.sh` file into `plugins/`**.
It appears in the main menu on the next start. No registration, no
configuration, no code changes anywhere else.

## Try the shipped template

```bash
cd /opt/debian-admin-toolkit          # or your checkout
sudo cp plugins/hello.sh.example plugins/hello.sh
dat --list                            # "hello" is now listed
dat hello
```

Only files ending in `.sh` are discovered, which is why the template ships
as `.sh.example` and stays inactive until you copy it.

## Minimal plugin

```bash
#!/usr/bin/env bash
# DAT-MODULE
# Id: hello
# Name: Hello World
# Description: Example plugin that greets the user
# Entry: module_hello_main

module_hello_main() {
    ui_msgbox "Hello" "Hello from a DAT plugin!"
}
```

## The metadata header

It must appear within the **first 20 lines**, starting with `# DAT-MODULE`:

| Field | Required | Meaning |
|-------|----------|---------|
| `Id` | yes | unique id, `[a-z][a-z0-9-]*` — also the CLI argument (`dat hello`) |
| `Name` | yes | label shown in the menu |
| `Description` | no | shown by `dat --list` |
| `Entry` | yes | function called when the module runs |

Files are loaded in lexical order, so a numeric prefix controls the menu
position (`10-system.sh`, `20-network.sh`, …).

A plugin with a missing/invalid header or a duplicate `Id` is **skipped with
a warning** — one broken plugin can never take down the toolkit.

## Rules

- The file is **sourced** when the module runs: only define functions, never
  execute anything at the top level.
- Prefix your function names with the module id (`module_hello_*`,
  `hello_*`) so they cannot clash with the framework or other plugins.
- The entry function's return code is shown to the user — return non-zero
  only for real errors.

## Framework helpers

Use these instead of reinventing them; they handle the whiptail/text
fallback and logging for you.

### Dialogs

| Function | Purpose |
|----------|---------|
| `ui_msgbox <title> <text>` | show a message |
| `ui_yesno <title> <question>` | confirm; returns 0 for yes |
| `ui_input <title> <prompt> [default]` | read one line; prints it on stdout |
| `ui_menu <title> <prompt> <tag> <label> …` | selection menu; prints the chosen tag |
| `ui_show_text <title> <text>` | scrollable text box |
| `ui_show_cmd <title> <command…>` | run a command and display its output |

`ui_menu` and `ui_input` return non-zero when the user cancels — always
handle that:

```bash
choice="$(ui_menu "Title" "Pick one:" a "First" b "Second")" || return 0
```

### Logging

`log_debug`, `log_info`, `log_warn`, `log_error` — each takes one message.

### System helpers

| Function | Purpose |
|----------|---------|
| `has_cmd <cmd>` | is a command available? |
| `require_cmd <cmd> [pkg]` | log a helpful install hint if missing |
| `is_root` | running as root? |
| `run_privileged <cmd…>` | run as root, using sudo when needed |
| `dat_version` | the toolkit version |

## A more realistic example

```bash
#!/usr/bin/env bash
# DAT-MODULE
# Id: services
# Name: Failed Services
# Description: Show systemd units that failed
# Entry: module_services_main

# services_failed - Collect failed systemd units.
services_failed() {
    if ! has_cmd systemctl; then
        printf 'systemd is not available on this host.\n'
        return 0
    fi
    systemctl --failed --no-pager
}

module_services_main() {
    log_info "services: listing failed units"
    ui_show_cmd "Failed services" services_failed
}
```

Good practice shown above: probe optional tools with `has_cmd` and print a
helpful message instead of failing.

## Testing your plugin

```bash
dat --list              # is it discovered?
dat <id>                # run it directly
dat --debug <id>        # verbose logging
bash tests/run_tests.sh  # syntax + framework + plugin suites
```

The plugin test suite
([tests/test_plugins.sh](https://github.com/grumel/debian-admin-toolkit/blob/main/tests/test_plugins.sh))
verifies drop-in discovery, execution and that broken plugins are skipped.

## Contributing a module

Modules shipped in `modules/` must additionally be ShellCheck-clean (CI
enforces this). See
[docs/modules.md](https://github.com/grumel/debian-admin-toolkit/blob/main/docs/modules.md)
for the reference and
[docs/architecture.md](https://github.com/grumel/debian-admin-toolkit/blob/main/docs/architecture.md)
for how the loader works.
