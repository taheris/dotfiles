"""Offline workflow tests: tiny fake shards, no network, model weights or GPUs."""

import contextlib
import copy
import hashlib
import io
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

import models


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.state = Path(self.temporary.name) / "state with spaces"
        self.root = self.state / "models/unsloth-ud-iq4_xs"
        self.config = self.state / "strata-unsloth-ud-iq4_xs.json"
        self.source = Path(os.environ["STRATA_SOURCE"])
        self.catalog = models.read_json(self.source / "models.json")
        self.model = copy.deepcopy(self.catalog["unsloth-ud-iq4_xs"])
        self.content = b"tiny fake GGUF for workflow tests\n"
        for file in self.model["files"]:
            file.update(
                size=len(self.content), sha256=hashlib.sha256(self.content).hexdigest()
            )
        self.options = types.SimpleNamespace(context=None, gpus=None, mtp=None)
        self.env = patch.dict(os.environ, STRATA_STATE_DIR=str(self.state))
        self.env.start()
        self.addCleanup(self.env.stop)

    def cli(self, *args):
        output = io.StringIO()
        with (
            patch.object(sys, "argv", ["strata-models", *args]),
            contextlib.redirect_stdout(output),
        ):
            models.main()
        return output.getvalue()

    def fake_download(self, **kwargs):
        self.assertEqual(kwargs["repo_id"], self.model["repo"])
        self.assertEqual(kwargs["revision"], self.model["revision"])
        self.assertEqual(
            kwargs["allow_patterns"], [f["path"] for f in self.model["files"]]
        )
        for name in kwargs["allow_patterns"]:
            path = Path(kwargs["local_dir"]) / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(self.content)

    def download(self):
        hub = types.SimpleNamespace(HfApi=None, snapshot_download=self.fake_download)
        with models.lock(self.root), patch.dict(sys.modules, huggingface_hub=hub):
            models.download(self.model, self.root)

    def fake_pack(self, command, **kwargs):
        self.assertEqual(command[0], "strata-iq-pack")
        self.assertIn("--compat-bf16", command)
        self.assertNotIn("--experts-bin", command)
        first = str(self.root / "gguf" / self.model["files"][0]["path"])
        self.assertEqual(command[command.index("--gguf") + 1], first)
        out = Path(command[command.index("--out") + 1])
        for name in models.PACK_FILES:
            path = out / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("fake pack\n")

    def prepare(self):
        with (
            models.lock(self.root),
            patch.object(models.subprocess, "run", side_effect=self.fake_pack) as pack,
        ):
            models.prepare(
                self.model, self.root, self.config, self.source, self.options
            )
            return pack.call_count

    def test_real_catalog(self):
        model = self.catalog["unsloth-ud-iq4_xs"]
        self.assertEqual(model["revision"], "38bb39ee97821de2c9009abb7e93950eec396e66")
        self.assertEqual(len(model["files"]), 3)
        self.assertEqual(sum(f["size"] for f in model["files"]), 93682584224)
        self.assertEqual(model["pack_args"], ["--compat-bf16"])
        self.assertTrue(model["files"][0]["path"].startswith("UD-IQ4_XS/"))
        self.assertNotIn("swift-q2_0", self.catalog)
        self.assertEqual(
            self.catalog["coder-iq1_m"]["profile"], "expert-profile-coder.bin"
        )
        self.assertEqual(len(self.catalog["unsloth-ud-q4_k_xl"]["files"]), 4)

    def test_listing_and_preview_do_not_write(self):
        rows = json.loads(self.cli("list", "--json"))
        self.assertTrue(all(row["status"] == "available" for row in rows))
        info = json.loads(self.cli("download", "unsloth-ud-iq4_xs", "--dry-run"))
        self.assertEqual(info["config"], str(self.config))
        self.assertFalse(self.state.exists())

    def test_unknown_model_and_options_do_not_write(self):
        with contextlib.redirect_stderr(io.StringIO()):
            for args in (
                ("download", "../oops"),
                ("prepare", "unsloth-ud-iq4_xs", "--context", "0"),
                ("prepare", "unsloth-ud-iq4_xs", "--gpus", "0,0"),
                ("download", "unsloth-ud-iq4_xs", "--oops"),
            ):
                with self.assertRaises(SystemExit):
                    self.cli(*args)
        self.assertFalse(self.state.exists())

    def test_run_and_prepare_require_download(self):
        with self.assertRaisesRegex(ValueError, "not prepared"):
            self.cli("run", "unsloth-ud-iq4_xs")
        with self.assertRaisesRegex(ValueError, "Weights missing"):
            self.prepare()
        self.assertFalse(self.config.exists())

    def test_download_verifies_then_skips_without_network(self):
        self.download()
        self.assertTrue(models.downloaded(self.model, self.root))
        with patch.dict(sys.modules, huggingface_hub=None):
            models.download(self.model, self.root)
        file = self.root / "gguf" / self.model["files"][1]["path"]
        file.write_bytes(b"damaged shard")
        self.assertFalse(models.downloaded(self.model, self.root))

    def test_bad_checksum_does_not_mark_download_complete(self):
        self.model["files"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "Wrong SHA-256"):
            self.download()
        self.assertFalse(models.downloaded(self.model, self.root))
        self.assertFalse((self.root / "download.json").exists())

    def test_bad_size_does_not_mark_download_complete(self):
        self.model["files"][1]["size"] += 1
        with self.assertRaisesRegex(ValueError, "Wrong size"):
            self.download()
        self.assertFalse((self.root / "download.json").exists())

    def test_non_unsloth_metadata_is_pinned(self):
        for file in self.model["files"]:
            file.update(size=None, sha256=None)
        siblings = [
            types.SimpleNamespace(
                rfilename=f["path"],
                size=len(self.content),
                lfs=types.SimpleNamespace(
                    sha256=hashlib.sha256(self.content).hexdigest()
                ),
            )
            for f in self.model["files"]
        ]
        api = Mock()
        api.model_info.return_value = types.SimpleNamespace(siblings=siblings)
        hub = types.SimpleNamespace(
            HfApi=lambda: api, snapshot_download=self.fake_download
        )
        with models.lock(self.root), patch.dict(sys.modules, huggingface_hub=hub):
            models.download(self.model, self.root)
        api.model_info.assert_called_once_with(
            self.model["repo"], revision=self.model["revision"], files_metadata=True
        )
        self.assertTrue(models.downloaded(self.model, self.root))

    def test_prepare_is_offline_idempotent_and_preserves_config(self):
        self.download()
        self.assertEqual(self.prepare(), 1)
        cfg = models.read_json(self.config)
        self.assertEqual(cfg["gpu"], [0, 1])
        self.assertEqual(cfg["layer_split"], "auto")
        self.assertIn("--resident-experts", cfg["args"])
        self.assertNotIn("--resident-budget-gib", cfg["args"])
        self.assertNotIn("--mtp", cfg["args"])
        self.assertEqual(cfg["args"][cfg["args"].index("--max-context") + 1], "32768")
        cfg["api_key"] = "keep-secret"
        models.write_json(self.config, cfg)
        before = self.config.read_bytes()
        self.assertEqual(self.prepare(), 0)
        self.assertEqual(self.config.read_bytes(), before)
        self.options.context = 65536
        with self.assertRaisesRegex(ValueError, "Config already exists"):
            self.prepare()
        self.assertEqual(self.config.read_bytes(), before)

    def test_failed_pack_does_not_publish_config_or_pack(self):
        self.download()
        with (
            models.lock(self.root),
            patch.object(
                models.subprocess,
                "run",
                side_effect=subprocess.CalledProcessError(1, "pack"),
            ),
            self.assertRaises(subprocess.CalledProcessError),
        ):
            models.prepare(
                self.model, self.root, self.config, self.source, self.options
            )
        self.assertFalse(self.config.exists())
        self.assertFalse((self.root / "pack").exists())
        self.assertEqual(list(self.root.glob("packing-*")), [])
        self.assertEqual(self.prepare(), 1)

    def test_config_options_and_optional_mtp(self):
        self.download()
        self.options.gpus = [1]
        self.options.context = 65536
        self.options.mtp = self.state / "mtp/rt"
        self.options.mtp.mkdir(parents=True)
        self.prepare()
        cfg = models.read_json(self.config)
        self.assertEqual(cfg["gpu"], [1])
        self.assertIn(str(self.options.mtp), cfg["args"])

    def test_run_execs_launcher_and_forwards_options_without_packing(self):
        self.download()
        self.prepare()
        # Use the tiny test model's checksums; the real catalog has the full-size ones.
        original = models.read_json
        with patch.object(models, "read_json", wraps=original) as read:

            def fake_read(path):
                return (
                    {"unsloth-ud-iq4_xs": self.model}
                    if path == self.source / "models.json"
                    else original(path)
                )

            read.side_effect = fake_read
            with patch.object(models.os, "execvp") as execute:
                self.cli(
                    "run",
                    "unsloth-ud-iq4_xs",
                    "--context",
                    "131072",
                    "--dry-run",
                    "--lazy",
                )
                execute.assert_called_once_with(
                    "strata-run",
                    [
                        "strata-run",
                        "--config",
                        str(self.config),
                        "--context",
                        "131072",
                        "--dry-run",
                        "--lazy",
                    ],
                )

    def test_status_tracks_download_and_preparation(self):
        original = models.read_json

        def fake_read(path):
            if path == self.source / "models.json":
                return {"unsloth-ud-iq4_xs": self.model}
            return original(path)

        with patch.object(models, "read_json", side_effect=fake_read):
            self.download()
            self.assertEqual(
                json.loads(self.cli("list", "--json"))[0]["status"], "downloaded"
            )
            self.prepare()
            self.assertEqual(
                json.loads(self.cli("list", "--json"))[0]["status"], "prepared"
            )
            shard = self.root / "gguf" / self.model["files"][2]["path"]
            shard.unlink()
            self.assertEqual(
                json.loads(self.cli("list", "--json"))[0]["status"], "available"
            )
            with self.assertRaisesRegex(ValueError, "not prepared"):
                self.cli("run", "unsloth-ud-iq4_xs")

    def test_incomplete_pack_is_not_reused_or_deleted(self):
        self.download()
        (self.root / "pack").mkdir()
        incomplete = self.root / "pack/dense.bin"
        incomplete.write_text("keep until moved aside")
        with self.assertRaisesRegex(ValueError, "Stale/incomplete pack"):
            self.prepare()
        self.assertEqual(incomplete.read_text(), "keep until moved aside")
        self.assertFalse(self.config.exists())

    def test_unavailable_pin_never_falls_back_to_main(self):
        fetch = Mock(side_effect=ValueError("revision unavailable"))
        hub = types.SimpleNamespace(HfApi=None, snapshot_download=fetch)
        with (
            models.lock(self.root),
            patch.dict(sys.modules, huggingface_hub=hub),
            self.assertRaisesRegex(ValueError, "revision unavailable"),
        ):
            models.download(self.model, self.root)
        self.assertEqual(fetch.call_count, 1)
        self.assertEqual(fetch.call_args.kwargs["revision"], self.model["revision"])
        self.assertFalse((self.root / "download.json").exists())

    def test_changed_revision_does_not_reuse_pack(self):
        self.download()
        self.prepare()
        mark = models.read_json(self.root / "download.json")
        mark["revision"] = "different-revision"
        models.write_json(self.root / "download.json", mark)
        self.assertFalse(models.packed(self.root))
        self.assertFalse(models.downloaded(self.model, self.root))


if __name__ == "__main__":
    unittest.main()
