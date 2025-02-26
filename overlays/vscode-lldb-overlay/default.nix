
# Snowfall Lib provides access to additional information via a primary argument of
# your overlay.
{
  # Channels are named after NixPkgs instances in your flake inputs. For example,
  # with the input `nixpkgs` there will be a channel available at `channels.nixpkgs`.
  # These channels are system-specific instances of NixPkgs that can be used to quickly
  # pull packages into your overlay.
  channels
, # The namespace used for your Flake, defaulting to "internal" if not set.
  namespace
, # Inputs from your flake.
  inputs
, ...
}:

final: prev: {
  # For example, to pull a package from unstable NixPkgs make sure you have the
  # input `unstable = "github:nixos/nixpkgs/nixos-unstable"` in your flake.
  # inherit (channels.unstable) chromium;

  vscode-extensions = prev.vscode-extensions // {
    vadimcn = prev.vscode-extensions.vadimcn // {
      vscode-lldb = inputs.vscodelldb-fix.legacyPackages."${prev.system}".vscode-extensions.vadimcn.vscode-lldb;
    };
  };
}

