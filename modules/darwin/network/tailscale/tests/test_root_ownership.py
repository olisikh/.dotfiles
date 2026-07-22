from __future__ import annotations

import unittest
from pathlib import Path


class TailscaleCaddyRootOwnershipTests(unittest.TestCase):
    def test_declares_vikunja_root_owner_and_exclusive_guard(self) -> None:
        repository = next(
            parent
            for parent in Path(__file__).resolve().parents
            if (parent / "flake.nix").exists()
        )
        source = (repository / "modules/darwin/network/tailscale/default.nix").read_text(
            encoding="utf-8"
        )

        self.assertIn("vikunja = {", source)
        self.assertIn("Exactly one Tailnet root owner may be enabled", source)
        self.assertIn("reverse_proxy ${caddyCfg.vikunja.upstream}", source)


if __name__ == "__main__":
    unittest.main()
