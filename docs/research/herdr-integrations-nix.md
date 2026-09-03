# Declarative Herdr integrations for Pi and Hermes

## Finding

Herdr's integrations are small embedded assets, not packages that must be installed by the Herdr CLI:

- Pi: one TypeScript extension at `~/.pi/agent/extensions/herdr-agent-state.ts`.
- Hermes: `plugin.yaml` plus `__init__.py` at `~/.hermes/plugins/herdr-agent-state/`, plus `herdr-agent-state` in the Hermes `plugins.enabled` list.

The installed Herdr package is Nix-managed at version `0.8.2` and exposes its integration assets as package outputs. The reproducible route is therefore to consume the package-owned files directly.

The installed Herdr package already ships these assets under:

```text
${pkgs.llm-agents.herdr}/share/herdr/integrations/
```

For Herdr 0.8.2, the package paths are:

- Pi: `share/herdr/integrations/pi/herdr-agent-state.ts`;
- Hermes: `share/herdr/integrations/hermes/plugin.yaml` and `__init__.py`.

The reproducible route is to link these package-owned assets through Home Manager, not to fetch duplicate raw GitHub files.

## Recommended Nix/Home Manager wiring

### Pi

```nix
herdrPackage = pkgs.llm-agents.herdr;
herdrPiIntegration = "${herdrPackage}/share/herdr/integrations/pi/herdr-agent-state.ts";
herdrHermesPlugin = "${herdrPackage}/share/herdr/integrations/hermes";
```

This path is intentional. The existing local Pi extensions live under the Nix-managed package directory `~/.pi/agent/extensions/olisikh`; placing the official file at the direct path matches Herdr's installer and lets `herdr integration status` recognize it as current. It does not conflict with the existing `olisikh` extension package.

Do not only add the file to the `olisikh` package's `package.json`: Pi would load it, but Herdr's status checker would still report the official integration as missing because it checks the canonical direct path.

The extension is inert outside Herdr. It activates only when `HERDR_ENV=1`, `HERDR_SOCKET_PATH`, and `HERDR_PANE_ID` are present, and only reports lifecycle state for Pi's TUI mode.

### Hermes

Manage the package-owned plugin files directly:

```nix
home.file.".hermes/plugins/herdr-agent-state/plugin.yaml".source = "${herdrHermesPlugin}/plugin.yaml";
home.file.".hermes/plugins/herdr-agent-state/__init__.py".source = "${herdrHermesPlugin}/__init__.py";
```

Do not make Home Manager own the whole `~/.hermes/config.yaml`: Hermes and its CLI write model, cron, plugin, routing, and runtime settings there. Instead, the nix-darwin system module declares a minimal root-owned `/etc/hermes/config.yaml` managed-scope overlay:

```yaml
plugins:
  enabled:
    - herdr-agent-state
```

Hermes merges this layer over the user's config, so the plugin is enabled declaratively without changing the user's file. This is implemented in `modules/darwin/ai/hermes/default.nix` and enabled for `olisikh-mini` in its system configuration.

The plugin only reports session identity for interactive Hermes platforms (`cli`, `tui`, `desktop`, `acp`) when Hermes is actually running inside a Herdr pane. It does not connect the Telegram gateway to Herdr.

## Why not use the Herdr installer during activation

`herdr integration install pi` and `herdr integration install hermes` are useful for unmanaged homes, but are not used here:

- the Herdr package already ships the version-matched assets;
- Home Manager owns the canonical agent paths;
- nix-darwin owns the immutable Hermes managed-scope allow-list.

## Verification after a rebuild

Without restarting the live Hermes gateway from inside its own session:

1. `herdr integration status` reports Pi and Hermes current.
2. The Pi file resolves to the active Home Manager/Nix generation.
3. The Hermes plugin files resolve to the active Home Manager/Nix generation.
4. `/etc/hermes/config.yaml` is the active Nix-managed overlay and contains `plugins.enabled: [herdr-agent-state]`.
5. `hermes config check` passes.
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
