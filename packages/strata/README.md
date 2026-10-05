# Strata

Strata **0.1.40.1** for text-only Orca IQ3_XXS inference on **2× RTX 4090**.
The package uses CUDA 13 and upstream's pinned llama.cpp source. It requires
x86-64 Linux with AVX2 and an NVIDIA driver compatible with CUDA 13 (580+).
It does not enable a service or change the existing llama.cpp installation.

## Start the prepared model

The Orca GGUFs, compatibility pack, tokenizer and MTP draft layer must already
be prepared. Your existing configuration from the earlier setup is reused:

```sh
ulimit -l unlimited
nix run .#strata
```

- Web interface: <http://127.0.0.1:8081/>
- OpenAI-compatible API: `http://127.0.0.1:8081/v1`
- Stop with **Ctrl+C**.

Starting never downloads weights, repacks the model or installs Python packages.
The launcher updates Nix-owned engine/profile paths after package upgrades and
selects `--resident-experts`, keeping model paths, GPU split, sampling and security
settings. Strata 0.1.40+ supports resident RAM mode on both GPUs: only experts absent
from both GPU caches are copied into locked RAM, rather than the full expert arena.
The config defaults `env.STRATA_RESIDENT_HEADROOM_GIB` to `"8"` (8 GiB); an existing
value is preserved. If the whole complement does not fit, upstream keeps the hottest
experts that fit and reads the rest from disk, or falls back to plain mapped mode.
Check the startup log for `resident RAM mode` and monitor file reads and available
RAM during long-context testing.

If your shell cannot raise the locked-memory limit, use a transient service:

```sh
sudo systemd-run --collect --wait --pty \
  -p User="$USER" -p WorkingDirectory="$PWD" -p LimitMEMLOCK=infinity \
  --setenv=HOME="$HOME" "$(command -v nix)" run "$PWD#strata"
```

Forward a custom `STRATA_STATE_DIR` or `XDG_DATA_HOME` with `--setenv` too.

## Context, thinking and output

| Setting | Fallback default | Meaning |
| --- | ---: | --- |
| Context | **131072** (128K) | Full rendered prompt plus generated tokens |
| Thinking cap | **65536** (64K) | Hard cap before the server closes thinking and continues answering |
| Total output | **98304** (96K) | Thinking, wrap-up and answer combined |

A 96K output allowance in a 128K context leaves roughly **32K for the prompt**
and about **32K for the answer** after a full 64K thinking run. Longer prompts
need a smaller output allowance or a larger context (native ceiling: 262144).
Larger contexts can reduce expert-cache capacity and throughput.

**Saved values win over fallback defaults.** A package upgrade does not reset
custom budgets. For smaller contexts, missing thinking/output settings default
to at most half/three quarters of the context respectively.

Apply the agreed settings without starting, hashing, downloading or repacking:

```sh
nix run .#strata -- --update-config \
  --context 131072 --reasoning-budget-tokens 65536 --max-tokens 98304
```

Stop a running server first and restart normally afterward. The same budget flags
work on a normal start. `--reasoning-budget-tokens 0` disables the **cap**, not
thinking itself. Other server options, such as `--lazy`, are passed through.

**Clients can override the defaults.** Raise an old client-side 32K output limit
to `max_completion_tokens: 98304` (OpenAI), `max_output_tokens: 98304` (Responses),
or `max_tokens: 98304` (Anthropic). A request's `reasoning_budget_tokens` overrides
the saved hard thinking cap; an effort level such as `high` is not a token limit.

## Configuration and previews

State defaults to `${XDG_DATA_HOME:-$HOME/.local/share}/strata`; set
`STRATA_STATE_DIR` to use another directory. Models remain outside the Nix store.

- `strata-orca-iq3_xxs.json`: engine arguments, thinking cap and server settings.
- `strata-orca-iq3_xxs.shared-settings.json`: default output limit and shared API settings.

Use `--config /path/to/model.json` for another prepared configuration. Both files
are validated before writing; each changed file gets a `.bak` backup and is
replaced atomically. The two writes are not a single filesystem transaction.

```sh
nix run .#strata -- --dry-run
```

This prints the proposed configuration without writes, GPU checks or inference.
Combine it with budget flags to preview an update. The preview includes the full
config, so redact any API key before sharing it.

## Build and fresh preparation

```sh
nix build .#strata .#checks.x86_64-linux.strata-smoke
```

There is no custom model installer. Enter `nix shell .#strata` to make the
preparation commands available. For fresh preparation, follow the upstream
[Orca guide](https://github.com/Niko1221/Strata/blob/v0.1.40.1/docs/ORCA.md), using
`strata-iq-pack`, `strata-mtp-fetch`, `strata-mtp-pack` and `strata-mtp-rt` in place
of its Python tool commands. Use Orca's own tokenizer and `--compat-bf16` packing.
For this dual-4090/64 GB host, keep GPUs `[0,1]`, `layer_split: "auto"` and
`--resident-experts`; the launcher migrates an existing `--mmap-experts` config on
start or `--update-config`. No model download or repacking is required.

## Code layout

- `default.nix`: native engine build, upstream Python dependencies and command wrappers.
- `run.sh`: argument parsing, config writes and server launch.
- `config.jq`: named helpers for budget resolution, validation and Nix resource rebinding.
- `test-run.sh`: model/GPU-free launcher checks.

The Python API server (`serve/server.py`) and preparation tools (`tools/`) come
unmodified from upstream Strata. There is no project-owned Python adapter.
