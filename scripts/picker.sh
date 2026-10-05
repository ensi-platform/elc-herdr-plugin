#!/usr/bin/env bash
# fzf picker for ELC components. Open a terminal or run start/restart/stop.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

herdr_bin="${HERDR_BIN_PATH:-herdr}"

die() {
  printf 'elc: %s\n' "$*" >&2
  printf '\nPress Enter to close…\n' >&2
  # shellcheck disable=SC2034
  read -r _ || true
  exit 1
}

pause() {
  printf '\nPress Enter to close…\n' >&2
  # shellcheck disable=SC2034
  read -r _ || true
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not on PATH"
}

require_cmd elc
require_cmd fzf

elc_args=()
if [ -n "${ELC_WORKSPACE:-}" ]; then
  elc_args+=(-w "$ELC_WORKSPACE")
fi

workspace_name="$(elc "${elc_args[@]}" workspace show 2>/dev/null || true)"
header="ELC${workspace_name:+ ($workspace_name)}"
header="${header}
Enter/ctrl-v: pane right   ctrl-h: pane down   ctrl-t: tab   ctrl-w: workspace
ctrl-s: start   ctrl-r: restart   ctrl-d: stop   esc: cancel"

fzf_out="$(
  elc "${elc_args[@]}" list 2>/dev/null | fzf \
    --prompt 'component> ' \
    --header "$header" \
    --height=100% \
    --layout=reverse \
    --border \
    --expect=ctrl-t,ctrl-w,ctrl-v,ctrl-h,ctrl-s,ctrl-r,ctrl-d \
    --bind 'ctrl-j:down,ctrl-k:up' || true
)"

# fzf --expect: line 1 is the key (empty for Enter), line 2 is the selection.
key="$(printf '%s\n' "$fzf_out" | sed -n '1p')"
component="$(printf '%s\n' "$fzf_out" | sed -n '2p')"

if [ -z "$component" ]; then
  exit 0
fi

split_direction=right
case "$key" in
  ctrl-t) mode=tab ;;
  ctrl-w) mode=workspace ;;
  ctrl-h) mode=pane; split_direction=down ;;
  ctrl-s) mode=start ;;
  ctrl-r) mode=restart ;;
  ctrl-d) mode=stop ;;
  ctrl-v|*) mode=pane; split_direction=right ;;
esac

run_elc_lifecycle() {
  local action="$1"
  printf 'elc: %s %s\n\n' "$action" "$component" >&2
  if elc "${elc_args[@]}" -c "$component" "$action"; then
    printf '\nelc: %s %s — ok\n' "$action" "$component" >&2
    pause
    exit 0
  else
    status=$?
    printf '\nelc: %s %s — failed (exit %s)\n' "$action" "$component" "$status" >&2
    pause
    exit "$status"
  fi
}

case "$mode" in
  start|restart|stop)
    run_elc_lifecycle "$mode"
    ;;
esac

path="$(
  elc "${elc_args[@]}" -c "$component" vars 2>/dev/null \
    | sed -n 's/^SVC_PATH=//p' \
    | head -n 1
)"
[ -n "$path" ] || die "could not resolve SVC_PATH for '$component'"
[ -d "$path" ] || die "path does not exist for '$component': $path
clone it with: elc ${ELC_WORKSPACE:+-w $ELC_WORKSPACE }-c $component clone"

# Prefer explicit ids from the action; fall back to popup context / env.
target_pane="${ELC_TARGET_PANE:-${HERDR_PANE_ID:-}}"
target_workspace="${ELC_TARGET_WORKSPACE:-${HERDR_WORKSPACE_ID:-}}"

if [ -z "$target_pane" ] && [ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]; then
  target_pane="$(
    printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" \
      | jq -r '.focused_pane_id // empty' 2>/dev/null || true
  )"
fi
if [ -z "$target_workspace" ] && [ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]; then
  target_workspace="$(
    printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" \
      | jq -r '.workspace_id // empty' 2>/dev/null || true
  )"
fi

case "$mode" in
  pane)
    [ -n "$target_pane" ] || die "no target pane to split (invoke from a Herdr pane)"
    exec "$herdr_bin" pane split \
      --pane "$target_pane" \
      --direction "$split_direction" \
      --cwd "$path" \
      --focus
    ;;
  tab)
    if [ -n "$target_workspace" ]; then
      exec "$herdr_bin" tab create \
        --workspace "$target_workspace" \
        --cwd "$path" \
        --label "$component" \
        --focus
    else
      exec "$herdr_bin" tab create \
        --cwd "$path" \
        --label "$component" \
        --focus
    fi
    ;;
  workspace)
    exec "$herdr_bin" workspace create \
      --cwd "$path" \
      --label "$component" \
      --focus
    ;;
esac
