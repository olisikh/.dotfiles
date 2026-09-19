### dotfiles

1. Clone it
2. Run ./install.sh to install
3. Run ./uninstall.sh to uninstall

Nix help:
<https://github.com/agilesteel/.dotfiles/blob/master/nix/home-manager/home.nix>

## Configuration profiles

`dots build` uses the `default` profile unless another profile is selected. The
profile is part of the generated flake configuration, so switching profiles is
pure and does not change the machine hostname.

```sh
dots build                       # default profile
dots build --profile default    # explicit default profile
dots build --profile boring     # boring profile
dots build -p boring             # short form
dots build -p boring --skip-gc   # skip generation pruning
```

All systems currently provide the `default` profile. The Mac mini
(`olisikh-mini`) also provides the paired `boring` system and home profiles:

| System | `default` | `boring` |
| --- | --- | --- |
| `olisikh-mini` | yabai, skhd, jankyborders | skhd, jankyborders |

The `boring` mini profile is the previous mini baseline: yabai is disabled while
skhd and jankyborders remain enabled. Its activation explicitly boots out the
stale `org.nixos.yabai` LaunchAgent and removes its plist during
`postActivation`. Other systems reject
`boring` rather than falling back to another configuration.

Before rebuilding, `dots build` and `install.sh` print the selected profile plus
the exact Darwin and Home Manager flake references they will use. Home Manager
writes the active profile to `~/.config/dotfiles/.env`; later `dots build` calls
use that managed state unless `-p`/`--profile` explicitly overrides it.

## Graphify in Pi

`/graphify .` runs the installed Graphify skill through the current Pi agent.
Code is extracted structurally; uncached document/media semantics use native
`delegate` subagents on the configured model route. No separate DeepSeek/Gemini
key is needed, and the standalone `graphify extract` CI backend is not used.

- `graphify_build` / `graphify_update` return agent workflow instructions, not a
  completed graph. The agent owns extraction, validation and publication.
- `graphify_query`, `graphify_path` and `graphify_explain` traverse a current graph.
  Their optional `path` selects a corpus; otherwise they use the Git root or cwd.
- Source edits mark existing graphs stale. They refresh **before next use**, never
  through a hidden post-task extraction or surprise model continuation.
- Plan mode does not execute Graphify, including lifecycle hooks and `/graphify`.
- Builds use staging and preserve the previous graph on failure. A leftover
  publication backup must be recovered if a crash left `graphify-out` absent.
- Other operations/exports use the upstream skill. The old npm wrapper's automatic
  context hints and dedicated upgrade/watch/headless tools are no longer loaded.

The Pi adapter lives in `modules/home/ai/pi/extensions/graphify-integration.ts` and
`extensions/lib/graphify-tools.ts`; its workflow guide is deployed to
`~/.pi/agent/graphify/session.md`. The Python installation and upstream skill remain
managed separately by `~/.llm-harness`. Apply Home Manager through the normal
Darwin rebuild, then restart/reload Pi to replace the old wrapper. A Nix build
without switching does not change the running session.

Run the adapter regression tests using Pi's installed TypeBox dependency (no
installation into the Nix-managed extension directory):

```sh
cd modules/home/ai/pi/extensions
bun run test:graphify
GRAPHIFY_LIVE_TESTS=1 bun run test:graphify  # also verify installed Python isolation
```

The live check requires the existing Graphify CLI on PATH. Traversal may update
Graphify's last-query cache stamp; freshness probes do not modify corpus artifacts.

## Self-signed company cert issues: make sure nix uses proper CA during nix build

1. Configure Determinate Nix daemon to know about cert whereabouts:

```bash
sudo vim /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
```

add the following environment configuration:

```xml
<key>EnvironmentVariables</key>
<dict>
  <key>NIX_SSL_CERT_FILE</key>
  <string>/etc/nix/macos-keychain.crt</string>
  <key>SSL_CERT_FILE</key>
  <string>/etc/nix/macos-keychain.crt</string>
  <key>CURL_CA_BUNDLE</key>
  <string>/etc/nix/macos-keychain.crt</string>
  <key>GIT_SSL_CAINFO</key>
  <string>/etc/nix/macos-keychain.crt</string>
  <key>REQUESTS_CA_BUNDLE</key>
  <string>/etc/nix/macos-keychain.crt</string>
</dict>
```

1. Restart nix daemon:

```
sudo launchctl bootout system /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
```

## Nix and Github

Nix downloads packages from Github and you may quickly get rate limited by Github.
For that not to happen, generate a token in Github and add it to nix.conf file as:

```
access-tokens = github.com=<access_token>
```

## Nix fetchFromGithub: how to figure out SHA256 hash of a revision

If you have access to `lib`, then set `sha256 = lib.fakeHash`, run the build, check the error message, it'd show the real hash value which you can then take and set.

Otherwie you may use nix-prefetch with fetchFromGithub command specifying the repository details, as shown down below:

```
nix-prefetch fetchFromGitHub --owner catppuccin --repo alacritty --rev main
The fetcher will be called as follows:
> fetchFromGitHub {
>   owner = "catppuccin";
>   repo = "alacritty";
>   rev = "main";
>   sha256 = "sha256:0000000000000000000000000000000000000000000000000000";
> }

sha256-HiIYxTlif5Lbl9BAvPsnXp8WAexL8YuohMDd/eCJVQ8=
```

## Configure programs with home manager

Most of the packages have home-manager support, for example \
wezterm has this page that tells what options you have to configure it: \
<https://home-manager-options.extranix.com/?query=wezterm&release=master>

## Nixvim plugin docs

Nixvim plugin options are documented at:
<https://nix-community.github.io/nixvim/plugins/>

For example, `lensline` options:
<https://nix-community.github.io/nixvim/plugins/lensline/index.html>

## Quick nix-darwin help

Feeling lost with nix-darwin config options?

```bash
darwin-help
```

This command opens a browser window with documentation about nix-darwin settings

## Available Nix templates

| Name      | Description                                       |
| --------- | ------------------------------------------------- |
| `empty`   | A NixOS system and modules ready to modify.       |
| `home`    | A Nix Flake that exports home manager.            |
| `system`  | A NixOS system and modules ready to modify.       |
| `package` | A Nix Flake that exports packages and an overlay. |
| `module`  | A Nix Flake that exports NixOS modules.           |
| `lib`     | A Nix Flake that exports a custom `lib`           |

To generate template files, run:

```sh
home template <name>
```
