#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'strata: %s\n' "$*" >&2
  exit 1
}

# Model management is explicit: normal starts never download or repack.
if [[ ${1:-} == models ]]; then
  shift
  exec "$STRATA_MODELS" "$@"
fi

show_help() {
  cat <<'HELP'
Start an already-prepared model. No downloads or repacking on start.

Usage: strata-run [options] [strata-server options]
       strata-run models {list,info,download,prepare,run} [options]

Use `strata-run models list` for supported variants and local status.
Without a model/config selection, start the existing Orca model.

  --config PATH                 Use a different saved run config
  --context N                   Set the full context limit
  --reasoning-budget-tokens N    Set the hard thinking cap (0 disables it)
  --max-tokens N                Set the shared total-output default
  --port N                      Set the API port
  --dry-run                     Preview changes without writing or starting
  --update-config               Save changes without starting the server

Fallback defaults: 131072 context, 65536 thinking, 98304 output, port 8081.
Saved budgets take precedence; explicit options override saved budgets.
Expert mode: resident RAM on the saved GPU split, with 8 GiB headroom unless saved.
Other options, such as --lazy, are passed to upstream strata-server.
HELP
  printf '\nDefault config: %s\n' "$config_path"
}

state_dir=${STRATA_STATE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/strata}
config_path=$state_dir/strata-orca-iq3_xxs.json

# Empty overrides mean "use the saved setting", not zero or unlimited.
context_override=''
thinking_override=''
output_override=''
port_override=''
dry_run=false
update_only=false
server_args=()

while (($#)); do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    --config|--context|--reasoning-budget-tokens|--max-tokens|--port|--family)
      if (($# < 2)); then
        fail "$1 needs a value"
      fi
      case $1 in
        --config)
          config_path="$2"
          ;;
        --context)
          context_override="$2"
          ;;
        --reasoning-budget-tokens)
          thinking_override="$2"
          ;;
        --max-tokens)
          output_override="$2"
          ;;
        --port)
          port_override="$2"
          ;;
        --family)
          # Keep the previous `--family orca` invocation working.
          if [[ $2 != orca ]]; then
            fail 'Use --config for other prepared models.'
          fi
          ;;
      esac
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --update-config)
      update_only=true
      shift
      ;;
    --setup|--download|--no-start)
      fail 'Custom setup was removed; use the upstream Orca preparation tools.'
      ;;
    *)
      server_args+=("$1")
      shift
      ;;
  esac
done

if [[ ! -f $config_path ]]; then
  fail "Prepared config not found: $config_path"
fi
config_path=$(realpath -- "$config_path")
shared_path=${config_path%.json}.shared-settings.json

read_shared_settings() {
  if [[ -f $shared_path ]]; then
    jq -e . "$shared_path"
  else
    printf '{}\n'
  fi
}

# Work out both files first. A bad option or malformed JSON changes neither file.
plan_path=$(mktemp)
trap 'rm -f -- "$plan_path"' EXIT
jq -e \
  --arg package_source "$STRATA_SOURCE" \
  --arg config_directory "$(dirname -- "$config_path")" \
  --arg context_override "$context_override" \
  --arg thinking_override "$thinking_override" \
  --arg output_override "$output_override" \
  --arg port_override "$port_override" \
  --slurpfile shared <(read_shared_settings) \
  --from-file "$STRATA_SOURCE/config.jq" \
  "$config_path" > "$plan_path"

if $dry_run; then
  jq . "$plan_path"
  exit 0
fi

save_settings() {
  local key=$1
  local destination=$2
  local temporary

  # Same-directory rename makes each write atomic; mktemp keeps credentials private.
  temporary=$(mktemp "$destination.XXXXXX")
  if ! jq --arg key "$key" '.[$key]' "$plan_path" > "$temporary"; then
    rm -f -- "$temporary"
    return 1
  fi

  if [[ -f $destination ]] && cmp -s -- "$destination" "$temporary"; then
    rm -- "$temporary"
  else
    if [[ -f $destination ]]; then
      cp -p -- "$destination" "$destination.bak"
    fi
    mv -- "$temporary" "$destination"
  fi
}

save_settings config "$config_path"
save_settings shared "$shared_path"

if $update_only; then
  exit 0
fi

# Exec the packaged upstream server, so Ctrl+C and exit status reach it directly.
port=$(jq -r '.config.port' "$plan_path")
rm -- "$plan_path"
trap - EXIT
exec "$STRATA_SERVER" \
  --engine strata \
  --config "$config_path" \
  --port "$port" \
  "${server_args[@]}"
