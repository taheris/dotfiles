#!/usr/bin/env bash
# Single-quoted filters passed to assert_json use jq variables, not shell variables.
# shellcheck disable=SC2016
set -euo pipefail

root=$(mktemp -d)
trap 'rm -rf -- "$root"' EXIT
export STRATA_STATE_DIR=$root/state
mkdir -p "$STRATA_STATE_DIR"
config=$STRATA_STATE_DIR/strata-orca-iq3_xxs.json
shared=$STRATA_STATE_DIR/strata-orca-iq3_xxs.shared-settings.json

assert_json() {
  local path=$1
  local condition=$2
  jq -e "$condition" "$path" > /dev/null
}

# A prepared model with no saved budgets and obsolete Nix-owned paths.
cat > "$config" <<'JSON'
{
  "exe": "/nix/store/garbage-collected/strata",
  "cwd": "/models",
  "lib_dirs": ["/old/cuda"],
  "args": [
    "--pack", "/models/pack",
    "--native", "/models/orca.gguf",
    "--ple-gguf", "/models/orca.gguf",
    "--expert-profile", "/nix/store/old/lib/strata/data/expert-profile.bin",
    "--mmap-experts", "--kv", "int8"
  ],
  "tokenizer": "/models/tokenizer",
  "gpu": [0, 1],
  "layer_split": "auto",
  "host": "127.0.0.1",
  "api_key": "test-secret",
  "sampling": {"temperature": 0.6},
  "mcp_servers": {"local": {"command": "test"}}
}
JSON
cp "$config" "$root/original.json"

echo 'Checking defaults and write-free previews...'
strata-run --dry-run > "$root/plan.json"
assert_json "$root/plan.json" '
  .config.args | index("--max-context") as $index | .[$index + 1] == "131072"
'
assert_json "$root/plan.json" '
  .config.reasoning_budget_tokens == 65536 and
  .shared.max_tokens == 98304 and
  .config.cwd == "/models" and
  .config.gpu == [0, 1] and
  .config.layer_split == "auto" and
  .config.tokenizer == "/models/tokenizer" and
  .config.api_key == "test-secret" and
  .config.sampling.temperature == 0.6 and
  .config.mcp_servers.local.command == "test" and
  .config.lib_dirs == [] and
  (.config.args | map(select(. == "--resident-experts")) | length) == 1 and
  (.config.args | index("--mmap-experts")) == null and
  .config.env.STRATA_RESIDENT_HEADROOM_GIB == "8"
'
cmp "$config" "$root/original.json"
test ! -e "$shared"
test ! -e "$config.bak"

echo 'Checking saves, backups and Nix resource rebinding...'
strata-run --update-config
assert_json "$config" '
  .reasoning_budget_tokens == 65536 and .port == 8081 and
  (.args | index("--resident-experts")) != null and
  (.args | index("--mmap-experts")) == null and
  .env.STRATA_RESIDENT_HEADROOM_GIB == "8"
'
assert_json "$shared" '.max_tokens == 98304'
cmp "$config.bak" "$root/original.json"

# A repeated identical update must not duplicate mode flags or replace the backup.
cp "$config" "$root/resident.json"
strata-run --update-config
cmp "$config" "$root/resident.json"
cmp "$config.bak" "$root/original.json"
jq --arg source "$EXPECTED_SOURCE" -e '
  .exe == ($source + "/engine/strata") and
  (.args | index("--expert-profile") as $index |
    .[$index + 1] == ($source + "/data/expert-profile.bin"))
' "$config" > /dev/null

echo 'Checking custom settings and explicit overrides...'
jq '
  .args |= (index("--max-context") as $index | .[$index + 1] = "65536") |
  .args |= (index("--expert-profile") as $index | .[$index + 1] = "/models/custom-profile.bin") |
  .reasoning_budget_tokens = 0 |
  .env = {STRATA_RESIDENT_HEADROOM_GIB: "10", STRATA_CUSTOM: "keep"}
' "$config" > "$root/custom.json"
mv "$root/custom.json" "$config"
printf '%s\n' '{"max_tokens":32768,"temperature":0.7,"reasoning_effort":"low"}' > "$shared"

strata-run --dry-run > "$root/custom-plan.json"
assert_json "$root/custom-plan.json" '
  .config.reasoning_budget_tokens == 0 and
  .shared.max_tokens == 32768 and
  .shared.temperature == 0.7 and
  .config.env.STRATA_RESIDENT_HEADROOM_GIB == "10" and
  .config.env.STRATA_CUSTOM == "keep" and
  (.config.args | index("--max-context") as $index | .[$index + 1] == "65536") and
  (.config.args | index("--expert-profile") as $index | .[$index + 1] == "/models/custom-profile.bin")
'
strata-run --update-config --family orca \
  --context 131072 --reasoning-budget-tokens 65536 --max-tokens 98304
assert_json "$config" '
  .reasoning_budget_tokens == 65536 and
  (.args | index("--max-context") as $index | .[$index + 1] == "131072")
'
assert_json "$shared" '
  .max_tokens == 98304 and .temperature == 0.7 and .reasoning_effort == "low"
'

echo 'Checking resident mode for configs without a mode or with duplicate flags...'
for mode in missing duplicate; do
  jq --arg mode "$mode" '
    .args |= map(select(. != "--resident-experts" and . != "--mmap-experts")) |
    if $mode == "duplicate" then
      .args += ["--mmap-experts", "--resident-experts", "--resident-experts"]
    else . end
  ' "$config" > "$root/$mode.json"
  strata-run --dry-run --config "$root/$mode.json" > "$root/$mode-plan.json"
  assert_json "$root/$mode-plan.json" '
    (.config.args | map(select(. == "--resident-experts")) | length) == 1 and
    (.config.args | index("--mmap-experts")) == null and
    .config.gpu == [0, 1] and .config.layer_split == "auto"
  '
done

echo 'Checking failed validation leaves both files untouched...'
cp "$config" "$root/before.json"
cp "$shared" "$root/shared-before.json"
invalid_options=(
  '--context 0'
  '--context 262145'
  '--context 32768'
  '--reasoning-budget-tokens -1'
  '--max-tokens 0'
  '--max-tokens 65536'
  '--max-tokens 262144'
  '--port 65536'
  '--context nope'
  '--setup'
)
for options in "${invalid_options[@]}"; do
  read -r -a args <<< "$options"
  if strata-run --update-config "${args[@]}" > /dev/null 2>&1; then
    echo "Unexpected success: $options" >&2
    exit 1
  fi
  cmp "$config" "$root/before.json"
  cmp "$shared" "$root/shared-before.json"
done

printf '[]\n' > "$shared"
if strata-run --update-config > /dev/null 2>&1; then
  echo 'Unexpected success with malformed shared settings' >&2
  exit 1
fi
cmp "$config" "$root/before.json"
mv "$root/shared-before.json" "$shared"

echo 'Checking server exec and forwarded arguments without models or GPUs...'
cat > "$root/server" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$LAUNCH_RECORD"
SH
chmod +x "$root/server"
export STRATA_SOURCE=$EXPECTED_SOURCE
export STRATA_SERVER=$root/server
export LAUNCH_RECORD=$root/launched
bash "$RUN_SCRIPT" --port 8082 --lazy
printf '%s\n' --engine strata --config "$config" --port 8082 --lazy > "$root/expected"
cmp "$LAUNCH_RECORD" "$root/expected"
test ! -e "$STRATA_STATE_DIR/serve"
test ! -e "$STRATA_STATE_DIR/data-files"
echo 'Launcher checks passed.'
