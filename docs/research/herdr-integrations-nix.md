# Declarative Herdr integrations for Pi and Hermes

## Finding

Herdr's integrations are small embedded assets, not packages that must be installed by the Herdr CLI:

- Pi: one TypeScript extension at `~/.pi/agent/extensions/herdr-agent-state.ts`.
- Hermes: `plugin.yaml` plus `__init__.py` at `~/.hermes/plugins/herdr-agent-state/`, plus `herdr-agent-state` in the Hermes `plugins.enabled` list.

The installed Herdr package is Nix-managed at version `0.8.2`, but its Nix closure exposes only the binary and runtime references; the integration assets are embedded in the binary and are not exposed as separate Nix paths. The reproducible route is therefore to fetch the exact upstream assets at the same Herdr tag with fixed-output hashes.

## Exact pinned assets

Source tag: `v0.8.2`

```nix
herdrPiIntegration = pkgs.fetchurl {
  url = "https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/src/integration/assets/pi/herdr-agent-state.ts";
  hash = "sha256-mxxBzXJSD8Kr5fKirsmVwSqSbM6ETfRyx/1fyuT02/o=";
};

herdrHermesPluginManifest = pkgs.fetchurl {
  url = "https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/src/integration/assets/hermes/plugin.yaml";
  hash = "sha256-4cd1ptbMrS+ObgVmoKphru+bgUH1nYp0KnfGlRomEXA=";
};

herdrHermesPluginInit = pkgs.fetchurl {
  url = "https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/src/integration/assets/hermes/__init__.py";
  hash = "sha256-YohPPg9xT3i/xCcizd7z3TKgoYRQKGTXnREzKVY97tI=";
};
```

The Pi asset is marked `HERDR_INTEGRATION_ID=pi` and `HERDR_INTEGRATION_VERSION=8`; the Hermes asset is marked `HERDR_INTEGRATION_ID=hermes` and `HERDR_INTEGRATION_VERSION=5`. Use the asset marker and package tag as the compatibility reference, not the older version numbers shown in some rendered documentation pages.

## Recommended Nix/Home Manager wiring

### Pi

Add a direct Home Manager file:

```nix
home.file.".pi/agent/extensions/herdr-agent-state.ts".source = herdrPiIntegration;
```

This path is intentional. The existing local Pi extensions live under the Nix-managed package directory `~/.pi/agent/extensions/olisikh`; placing the official file at the direct path matches Herdr's installer and lets `herdr integration status` recognize it as current. It does not conflict with the existing `olisikh` extension package.

Do not only add the file to the `olisikh` package's `package.json`: Pi would load it, but Herdr's status checker would still report the official integration as missing because it checks the canonical direct path.

The extension is inert outside Herdr. It activates only when `HERDR_ENV=1`, `HERDR_SOCKET_PATH`, and `HERDR_PANE_ID` are present, and only reports lifecycle state for Pi's TUI mode.

### Hermes

Manage the plugin files directly:

```nix
home.file.".hermes/plugins/herdr-agent-state/plugin.yaml".source = herdrHermesPluginManifest;
home.file.".hermes/plugins/herdr-agent-state/__init__.py".source = herdrHermesPluginInit;
```

Do not make Home Manager own the whole `~/.hermes/config.yaml`: Hermes and its CLI currently write model, cron, plugin, routing, and runtime settings there. Replacing the whole file from Nix would risk clobbering user-owned state.

Instead, add a small idempotent Home Manager activation step that ensures the single value `herdr-agent-state` is present in `plugins.enabled`, preserving all other YAML keys and list entries. The activation should use a temporary file plus atomic replacement, create a mode-0600 backup before the first mutation, and be a no-op when the entry is already present. It should not invoke `herdr integration install hermes`, because that command is imperative and would bypass the Nix source of truth.

The plugin only reports session identity for interactive Hermes platforms (`cli`, `tui`, `desktop`, `acp`) when Hermes is actually running inside a Herdr pane. It does not connect the Telegram gateway to Herdr.

## Why not use the Herdr installer during activation

`herdr integration install pi` and `herdr integration install hermes` are useful for unmanaged homes, but they are the wrong source of truth here:

- they write mutable files outside the Nix expression;
- they can overwrite Nix-managed Pi extension paths;
- Hermes installation also mutates `config.yaml`;
- updates become dependent on when a human runs the command rather than on the pinned Nix generation.

The Nix module should own the exact assets and the enablement convergence.

## Verification after a rebuild

Without restarting the live Hermes gateway from inside its own session:

1. `herdr integration status` reports Pi and Hermes as current.
2. The Pi file resolves to the active Home Manager/Nix generation.
3. The Hermes plugin files resolve to the active Home Manager/Nix generation.
4. `hermes config check` passes.
5. `hermes plugins list --plain --no-bundled` includes `herdr-agent-state` as enabled.
6. Start a fresh Pi session inside Herdr and verify `herdr agent list` shows native Pi state/session data.
7. Start a fresh interactive Hermes process inside Herdr and verify `herdr agent list` shows its native session reference; state remains screen-detected for Hermes.
8. Verify a Herdr server restart restores Pi/Hermes sessions only when those interactive processes were launched inside Herdr.

## Scope boundary

These integrations improve Herdr observability, waits, rollups, and session restore. They do not implement Hermes-as-brain orchestration. The separate Hermes→Pi worker adapter still needs to create worktrees/tasks, launch Pi, pass task briefs, collect receipts, and report acceptance through Kanban.

## Sources

- Herdr integrations: https://herdr.dev/docs/integrations
- Herdr socket API: https://herdr.dev/docs/socket-api
- Pi asset at pinned tag: https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/src/integration/assets/pi/herdr-agent-state.ts
- Hermes manifest at pinned tag: https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/src/integration/assets/hermes/plugin.yaml
- Hermes plugin at pinned tag: https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/src/integration/assets/hermes/__init__.py
- Pi Nix module: `modules/home/ai/pi/default.nix`
- Herdr Nix module: `modules/home/ai/herdr/default.nix`
