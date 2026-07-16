# Writing modules and plugins

Modules (shipped in `modules/`) and plugins (dropped into `plugins/`) use
the same format. To extend the toolkit, copy a single `.sh` file into
`plugins/` — it appears in the main menu on the next start. No registration,
no configuration.

A ready-to-use template ships as
[`plugins/hello.sh.example`](../plugins/hello.sh.example). Only files ending
in `.sh` are discovered, so the template stays inactive until you copy it:

```bash
cp plugins/hello.sh.example plugins/hello.sh
dat --list        # "hello" now appears
```

## Module format

A module is a Bash file with a metadata header within its first 20 lines:

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

| Field         | Required | Meaning                                              |
|---------------|----------|------------------------------------------------------|
| `Id`          | yes      | Unique id (`[a-z][a-z0-9-]*`), also the CLI argument |
| `Name`        | yes      | Menu label                                           |
| `Description` | no       | Shown by `dat --list`                                |
| `Entry`       | yes      | Function called when the module starts               |

Files are discovered in lexical order; a numeric prefix such as
`10-system.sh` controls the menu position. Modules with a missing or invalid
header are skipped with a warning.

## Rules for module code

- The file is **sourced** when the module runs: define functions only, do
  not execute anything at the top level.
- Prefix all function names with your module id (e.g. `module_hello_*`,
  `hello_*`) to avoid collisions.
- Use the framework instead of reinventing it:
  - `ui_menu`, `ui_msgbox`, `ui_yesno`, `ui_show_text`, `ui_show_cmd` for dialogs
  - `log_debug` / `log_info` / `log_warn` / `log_error` for logging
  - `has_cmd` / `require_cmd` to probe for optional tools
  - `run_privileged` for actions that need root
- Handle missing tools gracefully: check with `has_cmd` and show a helpful
  message instead of failing.
- The entry function's return code is reported to the user: return non-zero
  only for real errors.
- Code must be ShellCheck-clean (CI enforces this for shipped modules).

## Testing a module

```bash
dat --list          # module is discovered
dat <id>            # run it directly, without the main menu
bash tests/run_tests.sh
```
