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

