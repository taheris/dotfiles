# Strata

Strata **0.1.40.1** for text-only Qwen3.8-Flash-Next inference on **2× RTX 4090**.
The package uses CUDA 13 and upstream's pinned llama.cpp source. It requires
x86-64 Linux with AVX2 and an NVIDIA driver compatible with CUDA 13 (580+).
It does not enable a service or change the existing llama.cpp installation.

## List, download and try another model

```sh
nix run .#strata -- models list
nix run .#strata -- models info unsloth-ud-iq4_xs
nix run .#strata -- models download unsloth-ud-iq4_xs --dry-run
nix run .#strata -- models download unsloth-ud-iq4_xs
nix run .#strata -- models prepare unsloth-ud-iq4_xs
ulimit -l unlimited
nix run .#strata -- models run unsloth-ud-iq4_xs
```

The catalog comes from this package's **pinned upstream release**: original Qwen,
Swift, Coder and Unsloth variants. This is not a browser for arbitrary Hugging Face
models: Strata supports this architecture and only the listed quantizations.
`list` shows available/downloaded/prepared status; `list --json` and `info` expose
the repository, revision, shard names and local paths without network access.
Your existing Orca config is not changed or selected by these commands.

- **Download** uses Hugging Face Hub's resumable downloader, selects only this
  quantization's shards and stays on the pinned revision (no fallback to `main`).
  All shards are checked for size and SHA-256. Checks are remembered by file size,
  modification time and inode; unchanged downloads are reused without network or
  hashing. `HF_TOKEN` and `HF_ENDPOINT` work as in Hugging Face Hub.
- **Prepare** is offline and calls the packaged upstream `strata-iq-pack`. Unsloth
  gets `--compat-bf16`; experts stay in the GGUFs, with no enormous `experts.bin`
  copy. A complete pack is published before its config. Repeating preparation
  reuses the pack and preserves the saved config. A stale/incomplete pack must be
  moved aside before preparing again.
- **Run** calls the existing launcher, never downloading, hashing or packing.
  Stop the old server before switching models; these configs use port **8081**.
  Budget flags, `--dry-run`, `--update-config` and server flags such as `--lazy`
  work after the model ID.

New configs start at **32K context**, GPUs **`[0,1]`**, automatic layer split,
int8 KV and resident CPU experts with 8 GiB RAM headroom. Set initial context or
GPU selection with `models prepare MODEL --context 65536 --gpus 0,1` (or `0` for
one GPU). Once a config exists, change budgets with `models run MODEL --context ...`
and GPU settings in that model's config, rather than recreating it.

**UD-IQ4_XS is a 93.7 GB download**, plus roughly 1.4 GB for the compatibility
pack. It has 59.5 GB of experts. With 64 GB RAM and two 4090s, resident mode keeps
experts absent from both GPU caches in RAM; actual capacity depends on context,
free VRAM and other applications. Watch the startup log for resident-mode
fallbacks and SSD reads. This GPU/model combination is not benchmarked here.
BF16 compatibility packing rounds some small projections; see upstream's
[Unsloth notes](https://github.com/Niko1221/Strata/blob/v0.1.40.1/docs/UNSLOTH_Q4.md#ud-iq4_xs-setup-from-0139-621).

The MTP draft layer is **optional**. New configs use lookup-only drafting to avoid
an additional download. To reuse an already-prepared MTP runtime, supply
`models prepare MODEL --mtp /path/to/mtp/rt` on first preparation. Prepare a fresh
runtime with the upstream commands below if needed; it costs about another 6 GB.

State is under `${STRATA_STATE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/strata}`:
`models/MODEL/gguf`, `models/MODEL/pack`, and `strata-MODEL.json`. Set
`STRATA_STATE_DIR` **before downloading** to put everything on your model SSD.
Nothing installs a service or puts weights in the Nix store. In `nix shell .#strata`,
`strata-models` is the same interface as `strata-run models`.

## Start the existing prepared Orca model

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

The model workflow wraps downloads and native packing, not upstream's OS/Python/
engine installer. Enter `nix shell .#strata` to make the individual preparation
commands available. For Orca or fresh MTP preparation, follow the upstream
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
- `models.py`: thin catalog/download/prepare/run interface using Hugging Face Hub.
- `test-models.py`: offline workflow tests with tiny synthetic files and mocked packers.

The Python API server (`serve/server.py`) and preparation tools (`tools/`) come
unmodified from upstream Strata. The model workflow never invokes upstream's
system installer, downloads an engine or installs Python packages at runtime.
