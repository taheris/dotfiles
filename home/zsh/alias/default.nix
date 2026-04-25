{ ... }:

# Verb-suffix conventions used across alias files.
#
# Lifecycle (services, daemons):
# - s   status
# - st  start
# - sp  stop
# - rs  restart
# - rl  reload
# - su  suspend
# - re  resume
# - sa  stats
#
# CRUD / inspection:
# - a   add
# - rm  remove
# - i   inspect
# - l   list
# - pr  prune
#
# Other verbs:
# - sr  search
# - e   edit
# - ex  exec
# - lg  logs
#
# Cargo modifiers:
# - af  --all-features
# - at  --all-targets
# - w   --workspace
#
# Global aliases (UPPERCASE, expand anywhere in a command).
# - L = "| less"
# - T = "| tail -n +2"
#
# Examples: scst (systemctl start), dcmsp (docker compose stop).

{
  imports = [
    ./container.nix
    ./git.nix
    ./global.nix
    ./misc.nix
    ./nix.nix
    ./platform.nix
    ./rust.nix
    ./shell.nix
  ];
}
