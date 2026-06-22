# Agent Instructions

## Start

- Run `bd dolt pull`.

## Beads

Use `bd` only; no markdown TODOs.

```bash
bd ready
bd show <id>
bd create --title="..." --description="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id>
bd dep add <issue> <depends-on>
```

Flow: ready → claim → implement → close. Priorities: 0-4. Types: `task`,
`bug`, `feature`, `epic`.

## Land

```bash
git add <files>
git commit -m "..."
git push origin main
wrix beads push
```

## Verify

```bash
nix fmt
nix build
nix flake check
```
