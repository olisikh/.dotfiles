### dotfiles

1. Clone it
2. Run ./install.sh to install
3. Run ./uninstall.sh to uninstall

Nix help:
https://github.com/agilesteel/.dotfiles/blob/master/nix/home-manager/home.nix

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

2. Restart nix daemon:
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
https://home-manager-options.extranix.com/?query=wezterm&release=master

## Quick nix-darwin help

Feeling lost with nix-darwin config options?

```bash
darwin-help
```

This command opens a browser window with documentation about nix-darwin settings

## Available Nix templates:

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
