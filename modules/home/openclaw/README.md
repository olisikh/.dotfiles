# OpenClaw Home Module

This module manages `~/.openclaw/openclaw.json` declaratively and keeps secrets out of git by using OpenClaw env
SecretRefs plus `sops-nix` decrypted files.

## What It Mirrors From Live Config

- `agents.defaults.model = "openai-codex/gpt-5.4"`
- Telegram DM/group allowlists include `3942079` and `13252999`
- Two-agent setup:
  - `main` agent in `~/.openclaw/workspace`
  - `wife` agent in `~/.openclaw/workspace-wife`
- Wife direct Telegram binding for peer `13252999`
- Wife restrictions:
  - `sandbox.mode = "off"`
  - strict `tools.deny` (while keeping `web_search` and `web_fetch` allowed)
- Live-aligned non-secret sections: `auth`, `tools`, `session`, `hooks`, `channels`, `gateway`, `plugins`, `bindings`

## Secrets Pattern

Expected sops secret files:

- `~/.config/sops-nix/secrets/openclawGatewayToken`
- `~/.config/sops-nix/secrets/openclawTelegramBotToken`
- `~/.config/sops-nix/secrets/gemini`

Use the generated wrapper to run OpenClaw with these secrets loaded:

```bash
~/.local/bin/openclaw-with-secrets
```

## Enable Example

```nix
olisikh = {
  sops.enable = true;
  openclaw.enable = true;
};
```

## Intentionally Manual

- OAuth/session state under `auth.profiles` remains runtime-managed.
- Plugin install metadata (`plugins.installs`) is not pinned.
- Gateway `controlUi.allowedOrigins` may need host/LAN-specific adjustments.
