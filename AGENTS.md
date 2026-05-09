# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for macOS dotfiles. System entries live in `systems/aarch64-darwin/<host>/default.nix`; per-user Home Manager entries live in `homes/aarch64-darwin/<user>@<host>/default.nix`. Reusable Darwin modules are under `modules/darwin/`, Home Manager modules under `modules/home/`, custom packages under `packages/`, overlays under `overlays/`, and shell templates under `templates/`. Keep host-specific toggles in `systems/` and shared behavior in modules.

## Build, Test, and Development Commands

Use the helper scripts where possible:

```sh
nix-build [system]        # build and switch a nix-darwin system
nix-update                # update flake inputs
nix-gens                  # list nix-darwin generations
nix-rollback              # switch to a previous generation
```

Direct flake checks are useful before switching:

```sh
nix build .#darwinConfigurations.olisikh-mbair.system --show-trace
nix eval .#darwinConfigurations.olisikh-mini.config.homebrew.casks --json
```

Run `./install.sh` only for initial setup, and `./uninstall.sh` only when removing nix-darwin.

## Coding Style & Naming Conventions

Nix files use two-space indentation, lowercase attribute names, and small focused modules. Module paths should mirror option paths, for example `modules/darwin/apps/repobar/default.nix` defines `olisikh.apps.repobar`. Use `mkBoolOpt false` for enable flags and gate implementation with `mkIf cfg.enable`. Prefer existing patterns over new abstractions.

## Testing Guidelines

There is no separate unit test suite. Validate changes by evaluating the affected option and building at least one impacted Darwin configuration. For new Homebrew modules, confirm generated `homebrew.brews`, `homebrew.casks`, or `homebrew.taps` include the expected entries. New untracked module files must be staged before flake evaluation, because flakes ignore untracked files.

## Commit & Pull Request Guidelines

Commit history uses short imperative subjects, usually lowercase, such as `install repobar and enable everywhere` or `fix bat theme`. Keep commits scoped to one logical change. PRs should describe affected hosts/modules, list validation commands, and call out any manual steps such as macOS permissions, Homebrew taps, or secrets.

## Security & Configuration Tips

Do not commit tokens, certificates, or machine-local secrets. GitHub rate-limit tokens belong in `nix.conf`, not this repo. Company CA setup and Determinate Nix daemon environment notes are documented in `README.md`.
