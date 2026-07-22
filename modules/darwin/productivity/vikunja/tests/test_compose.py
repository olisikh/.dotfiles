from __future__ import annotations

import unittest
from pathlib import Path


COMPOSE = Path(__file__).resolve().parents[1] / "compose" / "docker-compose.yaml"


class VikunjaComposeTests(unittest.TestCase):
    def test_postgres_18_uses_an_isolated_named_volume(self) -> None:
        source = COMPOSE.read_text(encoding="utf-8")
        self.assertIn("- vikunja-postgres:/var/lib/postgresql\n", source)
        self.assertIn("\nvolumes:\n  vikunja-postgres:\n", source)

    def test_manual_backup_wrapper_sets_its_runtime_environment(self) -> None:
        module = COMPOSE.parents[1] / "default.nix"
        source = module.read_text(encoding="utf-8")
        self.assertIn('export VIKUNJA_STATE_DIR="${cfg.stateDir}"', source)
        self.assertIn('export VIKUNJA_COMPOSE_PROJECT="${cfg.composeProject}"', source)
        self.assertNotIn("VIKUNJA_COMPOSE_FILE = toString composeFile;", source)
        self.assertIn("runtimeInputs = [ pkgs.docker renderer healthcheck pkgs.coreutils ];", source)

    def test_backup_checks_database_readiness_before_dumping(self) -> None:
        script = COMPOSE.parents[1] / "scripts" / "vikunja-backup"
        source = script.read_text(encoding="utf-8")
        self.assertIn("compose exec -T db pg_isready -U vikunja -d vikunja >/dev/null", source)


if __name__ == "__main__":
    unittest.main()
