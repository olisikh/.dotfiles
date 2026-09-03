{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  toToml = (pkgs.formats.toml { }).generate;

  cfg = config.${namespace}.ai.herdr;

  # Keep these assets aligned with the installed Herdr package. The Herdr
  # binary embeds them, but does not expose them as separate Nix paths.
  herdrVersion = "0.8.2";
  herdrPiIntegration = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/v${herdrVersion}/src/integration/assets/pi/herdr-agent-state.ts";
    hash = "sha256-mxxBzXJSD8Kr5fKirsmVwSqSbM6ETfRyx/1fyuT02/o=";
  };
  herdrHermesPluginManifest = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/v${herdrVersion}/src/integration/assets/hermes/plugin.yaml";
    hash = "sha256-4cd1ptbMrS+ObgVmoKphru+bgUH1nYp0KnfGlRomEXA=";
  };
  herdrHermesPlugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/v${herdrVersion}/src/integration/assets/hermes/__init__.py";
    hash = "sha256-YohPPg9xT3i/xCcizd7z3TKgoYRQKGTXnREzKVY97tI=";
  };

  herdrConfig = {
    keys = {
      split_vertical = "prefix+\"";
      split_horizontal = "prefix+%";
    };

    ui = {
      pane_borders = true;
      pane_outer_borders = true;
      pane_gaps = true;
      show_agent_labels_on_pane_borders = true;
    };
  };
in
{
  options.${namespace}.ai.herdr = {
    enable = mkBoolOpt false "Enable Herdr terminal workspace manager";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.herdr ];

    home.file = {
      ".config/herdr/config.toml".source = toToml "herdr-config.toml" herdrConfig;
      ".hermes/plugins/herdr-agent-state/plugin.yaml".source = herdrHermesPluginManifest;
      ".hermes/plugins/herdr-agent-state/__init__.py".source = herdrHermesPlugin;
    };

    # Hermes owns this mutable configuration file. Converge only the plugin
    # enablement entry while preserving all other user-managed settings and
    # comments. Do not run `herdr integration install hermes`: that would add
    # an imperative source of truth alongside Home Manager.
    home.activation.enableHerdrHermesPlugin = lib.mkAfter ''
      config_file="$HOME/.hermes/config.yaml"
      if [ -f "$config_file" ]; then
        ${pkgs.python3}/bin/python3 - "$config_file" <<'PY'
import os
import shutil
import stat
import sys
import tempfile
from pathlib import Path

config_path = Path(sys.argv[1])
text = config_path.read_text()
lines = text.splitlines(keepends=True)

plugins_index = next(
    (i for i, line in enumerate(lines) if line.rstrip("\r\n") == "plugins:"),
    None,
)
if plugins_index is None:
    raise SystemExit("Hermes config has no top-level plugins section")

enabled_index = None
for i in range(plugins_index + 1, len(lines)):
    line = lines[i]
    stripped = line.lstrip(" ")
    if stripped and not line.startswith(" "):
        break
    if line.startswith("  enabled:"):
        enabled_index = i
        break

if enabled_index is None:
    raise SystemExit("Hermes config plugins section has no enabled list")

if any(line.strip() == "- herdr-agent-state" for line in lines[enabled_index + 1:]):
    raise SystemExit(0)

newline = "\r\n" if "\r\n" in lines[enabled_index] else "\n"
lines.insert(enabled_index + 1, f"    - herdr-agent-state{newline}")
updated = "".join(lines)

backup = config_path.with_name(config_path.name + ".bak.herdr-agent-state")
if not backup.exists():
    shutil.copy2(config_path, backup)

mode = stat.S_IMODE(config_path.stat().st_mode)
fd, temporary = tempfile.mkstemp(prefix=config_path.name + ".", dir=config_path.parent)
try:
    os.fchmod(fd, mode)
    with os.fdopen(fd, "w") as handle:
        handle.write(updated)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, config_path)
except Exception:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
    raise
PY
      fi
    '';
  };
}
