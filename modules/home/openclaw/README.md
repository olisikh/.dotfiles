# OpenClaw Home Module

This module is intentionally thin. Host-specific `openclaw.json`-equivalent config now lives outside this module and
is provided per system via `olisikh.openclaw.config`.

## Per-System Config

Example wiring in a home config:

```nix
let
  openclawConfig = import ./openclaw-config.nix {
    homeDirectory = "/Users/olisikh";
  };
in
{
  olisikh.openclaw = {
    enable = true;
    config = openclawConfig;
  };
}
```

Current host file:

- `homes/aarch64-darwin/olisikh@olisikh-mini/openclaw-config.nix`

## Secrets Injection

If `olisikh.openclaw.useSopsSecrets = true` and `injectSecrets = true`, the module injects:

- `channels.telegram.tokenFile` from `~/.config/sops-nix/secrets/openclawTelegramBotToken`
- `gateway.auth.token` as file-based SecretRef from `~/.config/sops-nix/secrets/openclawGatewayToken`
- Gemini key SecretRef from `~/.config/sops-nix/secrets/gemini` for:
  - `agents.defaults.memorySearch.remote.apiKey`
  - `plugins.entries.google.config.webSearch.apiKey`

That keeps secrets out of git and out of static Nix config values.
