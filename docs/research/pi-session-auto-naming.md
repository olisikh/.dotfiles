# Pi automatic session naming research

## Recommendation

For Pi 0.84.x, `pi-title-renamer` is the closest match when the important surface is the terminal tab/window title. It generates a short title after the first assistant response, applies it with `ctx.ui.setTitle()`, re-applies it around Pi lifecycle events, and has a deterministic prompt/project fallback. It can also write the Pi session name when enabled in config.

Install:

```sh
pi install npm:pi-title-renamer
```

Enable Pi session metadata as well as the terminal title in `~/.pi/agent/title-renamer.json`:

```json
{
  "apply": {
    "terminalTitle": true,
    "sessionName": true,
    "overwriteSessionName": false
  }
}
```

Sources:

- Repository/README: <https://github.com/mkioutcc/pi-title-renamer>
- Published package manifest/source: <https://cdn.jsdelivr.net/npm/pi-title-renamer@0.1.3/package.json> and <https://cdn.jsdelivr.net/npm/pi-title-renamer@0.1.3/extensions/title-renamer/index.ts>

## Stronger alternative for tmux/zellij/herdr

`@normful/pi-auto-name` names the Pi session and, when present, tmux, zellij, and herdr panes/tabs. It runs after the first input by default, supports first-agent-settled instead, language/style/context controls, optional periodic re-naming, and current `@earendil-works/pi-*` peer packages.

```sh
pi install npm:@normful/pi-auto-name
```

Its default config is in `~/.config/pi-auto-name/config.json`; set `namingStyle` to `topic-project` or reduce `sessionNameMaxLength` if the full Pi title is too long. The default `replaceExistingName: "always"` is worth changing to `"never"` if manual/session names must be preserved.

Sources:

- README: <https://raw.githubusercontent.com/normful/pi-bakery/main/packages/pi-auto-name/README.md>
- Manifest: <https://raw.githubusercontent.com/normful/pi-bakery/main/packages/pi-auto-name/package.json>
- Runtime/source: <https://raw.githubusercontent.com/normful/pi-bakery/main/packages/pi-auto-name/src/index.ts>

## Other candidates

- `pi-session-auto-rename` (`pi install npm:pi-session-auto-rename`) is a smaller session-only option with `/name-ai` for full-history renaming and `/name-ai-config` for selecting a naming model. It targets current `@earendil-works` Pi peers, but it warns when its selected model has no key and does not directly set the terminal title; it relies on Pi's session-name title behavior.
  - <https://github.com/egornomic/pi-session-auto-rename>
  - <https://raw.githubusercontent.com/egornomic/pi-session-auto-rename/master/index.ts>
- `pi-session-name` directly updates the terminal title and has a tiny implementation, but version 0.1.2 imports the old `@mariozechner/pi-*` packages and declares them only as devDependencies. Pi's package docs say runtime dependencies must be in dependencies/peerDependencies and production installs omit devDependencies, so it is a compatibility risk for Pi 0.84.x.
  - <https://github.com/ttttmr/pi-session-name>
  - <https://raw.githubusercontent.com/ttttmr/pi-session-name/main/package.json>
  - <https://raw.githubusercontent.com/ttttmr/pi-session-name/main/src/index.ts>
- `pi-session-title` supports pi-mono/oh-my-pi variants, but its published compatibility surface is also based on the older `@mariozechner`/`@oh-my-pi` namespaces and it is less directly packaged for the current `@earendil-works` Pi runtime.
  - <https://github.com/djdembeck/pi-session-title>

## Pi API compatibility notes

Pi exposes both `pi.setSessionName()` for the session selector and `ctx.ui.setTitle()` for the terminal title. Current Pi extension docs also expose `session_info_changed`; Pi 0.80.3 release notes say extension session metadata updates were added there. The local installation is Pi 0.84.1, so the current-peer packages above are the safer choices.

- <https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md>
- <https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md>
- <https://github.com/earendil-works/pi/releases/tag/v0.80.3>
