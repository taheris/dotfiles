"""Small Nix model workflow; Hugging Face downloads, upstream Strata packs/runs."""

import argparse
import contextlib
import fcntl
import hashlib
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import urlsplit

PACK_FILES = (
    "index.txt",
    "dense.bin",
    "native_experts.txt",
    "tokenizer/vocab.json",
    "tokenizer/chat_template.jinja",
)


def catalog(upstream):
    """Export the pinned setup.py catalog at build time, without running its installer."""
    result = {}
    for family, fam in upstream["FAMILIES"].items():
        for quant, model in upstream["MODELS"].items():
            if family not in model.get("families", ("qwen", "swift")):
                continue
            repo, revision, folder = re.fullmatch(
                r"/(.+?)/resolve/([^/]+)/(.*)",
                urlsplit(fam["hf"].format(q=quant)).path,
            ).groups()
            files = []
            for i in range(1, upstream["model_shards"](fam, quant) + 1):
                name = upstream["model_file"](fam, quant, i)
                size, sha = fam.get("sha256", {}).get(name, (None, None))
                files.append({"path": folder + name, "size": size, "sha256": sha})
            result[f"{family}-{quant.lower()}"] = {
                "family": family,
                "quant": quant,
                "title": fam["title"],
                "about": model["about"],
                "repo": repo,
                "revision": revision,
                "files": files,
                "download_gb": model["download_gb"],
                "experimental": model.get("experimental", False),
                "pack_args": fam.get("pack_args", []),
                "profile": fam.get("profile", "expert-profile.bin"),
            }
    return result


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def write_json(path, value):
    """Publish only complete metadata/configs; never expose partial JSON."""
    fd, name = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, indent=2)
            stream.write("\n")
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def fingerprint(path):
    stat = path.stat()
    return [stat.st_size, stat.st_mtime_ns, stat.st_ino]


def downloaded(model, root):
    mark = read_json(root / "download.json")
    if (
        not mark
        or mark.get("repo") != model["repo"]
        or mark.get("revision") != model["revision"]
    ):
        return False
    try:
        return all(
            mark["files"][file["path"]]["stat"]
            == fingerprint(root / "gguf" / file["path"])
            and (
                file["sha256"] is None
                or mark["files"][file["path"]]["sha256"] == file["sha256"]
            )
            for file in model["files"]
        )
    except (FileNotFoundError, KeyError):
        return False


def pack_identity(root):
    mark = read_json(root / "download.json")
    if not mark:
        return None
    return {
        "repo": mark["repo"],
        "revision": mark["revision"],
        "files": {path: file["sha256"] for path, file in mark["files"].items()},
    }


def packed(root):
    identity = pack_identity(root)
    return (
        identity is not None
        and read_json(root / "pack/source.json") == identity
        and all((root / "pack" / name).is_file() for name in PACK_FILES)
    )


@contextlib.contextmanager
def lock(root):
    root.mkdir(parents=True, exist_ok=True)
    with (root / ".lock").open("w") as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def download(model, root):
    if downloaded(model, root):
        print("Already downloaded and verified.")
        return
    from huggingface_hub import HfApi, snapshot_download

    files = [dict(file) for file in model["files"]]
    if any(file["sha256"] is None for file in files):
        # Non-Unsloth families publish their hashes in the Hub's LFS pointers.
        info = HfApi().model_info(
            model["repo"], revision=model["revision"], files_metadata=True
        )
        siblings = {file.rfilename: file for file in info.siblings}
        for file in files:
            remote = siblings[file["path"]]
            if not remote.lfs:
                raise ValueError(f"No LFS checksum for {file['path']}")
            file.update(size=remote.size, sha256=remote.lfs.sha256)
    snapshot_download(
        repo_id=model["repo"],
        revision=model["revision"],
        allow_patterns=[file["path"] for file in files],
        local_dir=root / "gguf",
        max_workers=2,
    )
    mark = {"repo": model["repo"], "revision": model["revision"], "files": {}}
    previous = read_json(root / "download.json") or {}
    for file in files:
        path = root / "gguf" / file["path"]
        stamp = fingerprint(path)
        if stamp[0] != file["size"]:
            raise ValueError(f"Wrong size: {path}; remove it and retry download")
        old = previous.get("files", {}).get(file["path"], {})
        if old.get("stat") != stamp or old.get("sha256") != file["sha256"]:
            print(f"Verifying SHA-256: {path.name}", flush=True)
            with path.open("rb") as stream:
                digest = hashlib.file_digest(stream, "sha256").hexdigest()
            if digest != file["sha256"]:
                raise ValueError(f"Wrong SHA-256: {path}; remove it and retry download")
        mark["files"][file["path"]] = {"stat": stamp, "sha256": file["sha256"]}
    write_json(root / "download.json", mark)


def run_config(model, root, source, context, gpus, mtp):
    first = root / "gguf" / model["files"][0]["path"]
    # Keep shard filenames: resolving HF cache symlinks breaks split discovery.
    args = [
        "--pack",
        str(root / "pack"),
        "--native",
        str(first),
        "--expert-profile",
        str(source / "data" / model["profile"]),
        "--expert-cache",
        "auto",
        "--resident-experts",
        "--prefill",
        "512",
        "--spec",
        "4",
        "--spec-min-p",
        "0.5",
        "--max-context",
        str(context),
        "--kv",
        "int8",
    ]
    if mtp:
        args += ["--mtp", str(mtp)]
    return {
        "exe": str(source / "engine/strata"),
        "cwd": str(root),
        "args": args,
        "tokenizer": str(root / "pack/tokenizer"),
        "model_name": f"{model['family']}-{model['quant'].lower()}",
        "log": str(root / "strata.log"),
        "host": "127.0.0.1",
        "port": 8081,
        "gpu": gpus,
        "layer_split": "auto",
        "lib_dirs": [],
        "env": {"STRATA_RESIDENT_HEADROOM_GIB": "8"},
    }


def prepare(model, root, config, source, options):
    if not downloaded(model, root):
        raise ValueError("Weights missing or changed; run models download first")
    if config.exists() and (
        options.context is not None or options.gpus is not None or options.mtp
    ):
        raise ValueError(
            f"Config already exists: {config}; use models run --context or edit it for GPU/MTP changes"
        )
    if options.mtp and not options.mtp.is_dir():
        raise ValueError(f"MTP runtime directory not found: {options.mtp}")
    if not packed(root):
        if (root / "pack").exists():
            raise ValueError(
                f"Stale/incomplete pack: {root / 'pack'}; move it aside and prepare again"
            )
        # Failed/interrupted packing never damages the published pack.
        with tempfile.TemporaryDirectory(dir=root, prefix="packing-") as temporary:
            subprocess.run(
                [
                    "strata-iq-pack",
                    "--gguf",
                    str(root / "gguf" / model["files"][0]["path"]),
                    "--out",
                    temporary,
                    *model["pack_args"],
                ],
                check=True,
            )
            if not all((Path(temporary) / name).is_file() for name in PACK_FILES):
                raise ValueError("Upstream packer did not produce a complete pack")
            write_json(Path(temporary) / "source.json", pack_identity(root))
            os.rename(temporary, root / "pack")
    if not config.exists():
        write_json(
            config,
            run_config(
                model,
                root,
                source,
                options.context or 32768,
                options.gpus or [0, 1],
                options.mtp,
            ),
        )
    print(
        f"Prepared: {config}\nRun with: strata-run models run {model['family']}-{model['quant'].lower()}"
    )


def gpu_ids(text):
    if not re.fullmatch(r"[0-9]+(,[0-9]+)*", text):
        raise argparse.ArgumentTypeError("expected GPU IDs such as 0 or 0,1")
    ids = [int(part) for part in text.split(",")]
    if len(set(ids)) != len(ids):
        raise argparse.ArgumentTypeError("GPU IDs must be unique")
    return ids


def context_tokens(text):
    try:
        value = int(text)
        if 1 <= value <= 262144:
            return value
    except ValueError:
        pass
    raise argparse.ArgumentTypeError("context must be between 1 and 262144")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    listing = sub.add_parser(
        "list", help="list supported variants and local status (offline)"
    )
    listing.add_argument("--json", action="store_true")
    for command, help_text in (
        ("info", "show the pinned download and local paths (offline)"),
        ("download", "download only the selected GGUF shards; resume and verify"),
        (
            "prepare",
            "pack downloaded weights and create a separate run config (offline)",
        ),
        ("run", "run a prepared model; never download or pack"),
    ):
        child = sub.add_parser(command, help=help_text)
        child.add_argument("model", help="ID from models list, e.g. unsloth-ud-iq4_xs")
        if command == "info":
            child.add_argument("--json", action="store_true")
        elif command == "download":
            child.add_argument(
                "--dry-run",
                action="store_true",
                help="show the plan without downloads/writes",
            )
        elif command == "prepare":
            child.add_argument(
                "--context",
                type=context_tokens,
                help="initial context (default: 32768)",
            )
            child.add_argument(
                "--gpus", type=gpu_ids, help="initial GPUs (default: 0,1)"
            )
            child.add_argument(
                "--mtp",
                type=lambda p: Path(p).absolute(),
                help="existing optional MTP runtime directory",
            )
    options, rest = parser.parse_known_args()
    if rest and options.command != "run":
        parser.error("unrecognized arguments: " + " ".join(rest))
    source = Path(os.environ["STRATA_SOURCE"])
    state = Path(
        os.environ.get("STRATA_STATE_DIR")
        or Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
        / "strata"
    ).absolute()
    models = read_json(source / "models.json")
    if options.command == "list":
        rows = []
        for key, model in models.items():
            root = state / "models" / key
            ready = downloaded(model, root)
            status = (
                "prepared"
                if ready and packed(root) and (state / f"strata-{key}.json").is_file()
                else ("downloaded" if ready else "available")
            )
            rows.append({"id": key, "status": status, **model})
        if options.json:
            print(json.dumps(rows, indent=2))
        else:
            print(f"{'MODEL':<24} {'STATUS':<12} {'GB':>6}  NOTES")
            for row in rows:
                print(
                    f"{row['id']:<24} {row['status']:<12} {row['download_gb']:>6.1f}  "
                    f"{row['about']}"
                )
            print(
                "\nOnly upstream's supported text-only Qwen3.8-Flash-Next variants are listed."
            )
        return
    key = options.model.lower()
    if key not in models:
        parser.error(f"unknown model: {options.model}; use models list")
    model = models[key]
    root = state / "models" / key
    config = state / f"strata-{key}.json"
    if options.command == "info" or (options.command == "download" and options.dry_run):
        info = {
            "id": key,
            **model,
            "directory": str(root),
            "config": str(config),
            "downloaded": downloaded(model, root),
            "packed": packed(root),
        }
        print(json.dumps(info, indent=2))
    elif options.command == "run":
        if not downloaded(model, root) or not packed(root) or not config.is_file():
            raise ValueError(
                "Model not prepared; use models download, then models prepare"
            )
        if "--config" in rest or any(arg.startswith("--config=") for arg in rest):
            parser.error(
                "models run selects its own config; use strata-run --config directly instead"
            )
        if rest[:1] == ["--"]:
            rest = rest[1:]
        os.execvp("strata-run", ["strata-run", "--config", str(config), *rest])
    else:
        with lock(root):
            if options.command == "download":
                download(model, root)
            else:
                prepare(model, root, config, source, options)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"strata models: {error}") from error
