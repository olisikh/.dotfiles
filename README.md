### dotfiles

1. Clone it
2. Run ./install.sh to install
3. Run ./uninstall.sh to uninstall

Nix help:
https://github.com/agilesteel/.dotfiles/blob/master/nix/home-manager/home.nix

## When it stops working again after OSX update

Edit the file /etc/zshrc adding the following lines in the end:

```bash
# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
```

## Nix and Github

Nix downloads packages from Github and you may quickly get rate limited by Github.
For that not to happen, generate a token in Github and add it to nix.conf file as:

```
access-tokens = github.com=<your_access_token>
```

## Nix fetchFromGithub: how to figure out SHA256 hash of a revision

You may use nix-prefetch with fetchFromGithub command specifying the owner of the repository,
name of the repository and revision:

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
