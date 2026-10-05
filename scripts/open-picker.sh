#!/usr/bin/env bash
# Open the ELC component picker popup, forwarding the caller's layout context.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

herdr_bin="${HERDR_BIN_PATH:-herdr}"
plugin_id="${HERDR_PLUGIN_ID:-elc}"

exec "$herdr_bin" plugin pane open \
  --plugin "$plugin_id" \
  --entrypoint picker \
  --focus \
  --env "ELC_TARGET_PANE=${HERDR_PANE_ID:-}" \
  --env "ELC_TARGET_WORKSPACE=${HERDR_WORKSPACE_ID:-}" \
  --env "ELC_TARGET_TAB=${HERDR_TAB_ID:-}" \
  --env "ELC_WORKSPACE=${ELC_WORKSPACE:-}"
