# OpenClaw Home Module

This module is now a thin compatibility layer over `nix-openclaw` (`programs.openclaw`), instead of manually
writing `~/.openclaw/openclaw.json` and wiring `pkgs.openclaw` ourselves.

## What It Does

- Uses the upstream `nix-openclaw` Home Manager module for:
  - OpenClaw package/app wiring
  - launchd/systemd service management
  - generated config file lifecycle
  - bundled/custom plugin plumbing
- Keeps local defaults for:
  - Telegram allowlists
  - local gateway mode/auth
  - two-agent setup (`main` + restricted `wife`)
  - live-aligned shape from `~/.openclaw/openclaw.json` (2026.4.10-era fields)

## Package Pin

The flake overlay pins OpenClaw source to upstream `openclaw/openclaw` commit:

- `9fd08f9d0f54bc1f811d6dfbcc619cb7e565fca9` (version `2026.4.10`)

with fixed hashes for reproducibility.

## Secrets

By default (`olisikh.openclaw.useSopsSecrets = true`) the module expects:

- `~/.config/sops-nix/secrets/openclawGatewayToken`
- `~/.config/sops-nix/secrets/openclawTelegramBotToken`
- `~/.config/sops-nix/secrets/gemini`

Gateway auth token is configured through OpenClaw `SecretRef` + file provider.
Telegram bot token is passed via `channels.telegram.tokenFile`.
Gemini API key is configured through OpenClaw `SecretRef` + file provider.

## Enable Example

```nix
olisikh = {
  sops.enable = true;
  openclaw.enable = true;
};
```

## Optional Overrides

- `olisikh.openclaw.documents` to manage AGENTS/SOUL/TOOLS docs in workspace
- `olisikh.openclaw.bundledPlugins` and `olisikh.openclaw.customPlugins`
- `olisikh.openclaw.extraConfig` for raw recursive config overrides
