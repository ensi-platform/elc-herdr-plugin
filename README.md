

Fuzzy-pick an [ELC](https://github.com/ensi-platform/elc) component and open a
shell in its folder as a new **pane**, **tab**, or **workspace**.

## Requirements

- Herdr ≥ 0.9.0
- `elc` and `fzf` on `PATH`
- A registered ELC workspace (`elc workspace list`)

## Install

```bash
herdr plugin install ensi-platform/elc-herdr-plugin
```

Add a keybinding in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+e"
type = "plugin_action"
command = "elc.open-component"
description = "open ELC component"
```

## Usage

1. Press `prefix+e` (or run `herdr plugin action invoke elc.open-component`).
2. Type to filter the component list.
3. Choose an action:
   - **Enter** / **ctrl-v** — split a new pane to the right
   - **ctrl-h** — split a new pane below
   - **ctrl-t** — new tab in the current workspace
   - **ctrl-w** — new Herdr workspace
   - **ctrl-s** — `elc start`
   - **ctrl-r** — `elc restart`
   - **ctrl-d** — `elc stop`
   - **esc** — cancel

The cwd is the component’s `SVC_PATH` from ELC. If the folder is missing, clone
it first with `elc -c <name> clone`.

## Optional workspace override

Set `ELC_WORKSPACE` in the environment (or pass it when opening the picker) to
force a specific ELC workspace instead of the current one:

```bash
ELC_WORKSPACE=ensi herdr plugin action invoke elc.open-component
```

## Development

For local development, link the working copy instead of installing from GitHub:

```bash
herdr plugin unlink elc   # if already installed via install
herdr plugin link /path/to/elc-herdr-plugin
```

Edits to scripts apply immediately — no need to re-link. To verify:

```bash
herdr plugin action invoke elc.open-component
herdr plugin log list --plugin elc
```
