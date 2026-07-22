from __future__ import annotations

import importlib.util
import os
import stat
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "render-vikunja-env.py"


def load_module():
    spec = importlib.util.spec_from_file_location("render_vikunja_env", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RenderVikunjaEnvTests(unittest.TestCase):
    def make_environment(self, root: Path) -> dict[str, str]:
        secrets = root / "secrets"
        secrets.mkdir()
        (secrets / "database-password").write_text("db-password\n", encoding="utf-8")
        (secrets / "service-secret").write_text("service-secret\n", encoding="utf-8")
        return {
            "VIKUNJA_STATE_DIR": str(root / "state"),
            "VIKUNJA_SECRETS_DIR": str(secrets),
            "VIKUNJA_PORT": "3456",
            "VIKUNJA_SERVICE_PUBLICURL": "https://example.ts.net",
            "VIKUNJA_IMAGE_TAG": "2.3.0",
            "POSTGRES_IMAGE_TAG": "18.3",
        }

    def test_renders_private_envfile_and_runtime_directories(self) -> None:
        module = load_module()
        with tempfile.TemporaryDirectory() as temporary:
            environment = self.make_environment(Path(temporary))
            output = module.render_env(environment)

            self.assertEqual(output.name, "vikunja.env")
            self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)
            values = dict(
                line.split("=", 1)
                for line in output.read_text(encoding="utf-8").splitlines()
            )
            self.assertEqual(values["VIKUNJA_SERVICE_PUBLICURL"], "https://example.ts.net")
            self.assertEqual(values["VIKUNJA_DATABASE_PASSWORD"], "db-password")
            self.assertEqual(values["VIKUNJA_SERVICE_SECRET"], "service-secret")
            for relative in ("data/files", "backups", "logs"):
                directory = Path(environment["VIKUNJA_STATE_DIR"]) / relative
                self.assertTrue(directory.is_dir())
                self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o700)
            self.assertFalse((Path(environment["VIKUNJA_STATE_DIR"]) / "data/postgres").exists())

    def test_rejects_missing_secret_without_writing_envfile(self) -> None:
        module = load_module()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            environment = self.make_environment(root)
            (root / "secrets" / "service-secret").unlink()

            with self.assertRaises(module.ConfigurationError):
                module.render_env(environment)

            self.assertFalse((root / "state" / "vikunja.env").exists())

    def test_rejects_multiline_secret_without_writing_envfile(self) -> None:
        module = load_module()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            environment = self.make_environment(root)
            (root / "secrets" / "database-password").write_text(
                "first\nsecond\n", encoding="utf-8"
            )

            with self.assertRaises(module.ConfigurationError):
                module.render_env(environment)

            self.assertFalse((root / "state" / "vikunja.env").exists())


if __name__ == "__main__":
    unittest.main()
