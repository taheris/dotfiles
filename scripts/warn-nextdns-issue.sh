#!/usr/bin/env bash
# Remove with the NextDNS workaround once df-ebl's acceptance criteria pass.
# Keep live network requests outside pure Nix evaluation and sandboxed builds.
set -u
issue=https://github.com/tailscale/tailscale/issues/6130
if ! response=$(curl --fail --silent --show-error --location \
    --connect-timeout 5 --max-time 15 \
    -H 'Accept: application/vnd.github+json' \
    https://api.github.com/repos/tailscale/tailscale/issues/6130 2>/dev/null); then
    printf 'warning: could not check %s; retaining the NextDNS workaround\n' "$issue" >&2
elif ! state=$(printf '%s' "$response" | jq -er '.state | select(. == "open" or . == "closed")' 2>/dev/null); then
    printf 'warning: invalid issue response for %s; retaining the NextDNS workaround\n' "$issue" >&2
elif [[ $state != open ]]; then
    printf 'warning: %s is %s; review/remove the NextDNS workaround (df-ebl), after verifying its acceptance criteria\n' "$issue" "$state" >&2
fi
# Status checks and unavailable tools/network must never block local checks.
exit 0
