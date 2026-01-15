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

## Importing ZScaler certificates and pointing Nix to use them

1. Import certificates:
```bash
security export -t certs -f pemseq -k /Library/Keychains/System.keychain -o /tmp/certs-system.pem
security export -t certs -f pemseq -k /System/Library/Keychains/SystemRootCertificates.keychain -o /tmp/certs-root.pem
cat /tmp/certs-root.pem /tmp/certs-system.pem > /tmp/ca_cert.pem
```

2. Move the certificate:
```bash
sudo mv /tmp/ca_cert.pem /etc/nix/
```

3. Configure Nix daemon to know about cert whereabouts:
```bash
sudo vim /Library/LaunchDaemons/<depends_on_nix_installer>.nix-daemon.plist
```
add the following:
```xml
<key>EnvironmentVariables</key>
<dict>
  <key>NIX_SSL_CERT_FILE</key>
  <string>/etc/nix/ca_cert.pem</string>
  <key>SSL_CERT_FILE</key>
  <string>/etc/nix/ca_cert.pem</string>
  <key>REQUEST_CA_BUNDLE</key>
  <string>/etc/nix/ca_cert.pem</string>
</dict>
```

4. Restart nix daemon:
```
sudo launchctl unload /Library/LaunchDaemons/<depends_on_nix_installer>.nix-daemon.plist
sudo launchctl load /Library/LaunchDaemons/<depends_on_nix_installer>.nix-daemon.plist
```

5. You may also need to make your current shell aware of the certificate, and add it to your nix config:
Run in current shell:
```bash
export NIX_SSL_CERT_FILE=/etc/nix/ca_cert.pem
export SSL_CERT_FILE=/etc/nix/ca_cert.pem
```

Add to nix:
```nix
environment.variables = {
    NIX_SSL_CERT_FILE = "/etc/nix/ca_cert.pem";
    SSL_CERT_FILE = "/etc/nix/ca_cert.pem";
    REQUEST_CA_BUNDLE = "/etc/nix/ca_cert.pem";
};
```

## Nix and Github

Nix downloads packages from Github and you may quickly get rate limited by Github.
For that not to happen, generate a token in Github and add it to nix.conf file as:

```
access-tokens = github.com=<your_access_token>
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

## If skhd and yabai not showing up in Accessibility (Tahoe shenanigans)
```bash
realpath "$(which yabai)"
realpath "$(which skhd)"
open /path/to/yabai # and then drag-and-drop binary onto Accessibility table, confirm with Touch ID if needed

```
