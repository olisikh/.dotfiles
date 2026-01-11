# AGENTS.md - Guidelines for Agentic Coding Agents

This file provides essential information for AI coding agents working in this Nix-based dotfiles repository.

## Build/Lint/Test Commands

### Build Commands
- **Full system build**: `nix build .#darwinConfigurations.${HOSTNAME}.system --show-trace --print-build-logs -vvv`
  - Builds the complete Darwin system configuration
  - Replace `${HOSTNAME}` with actual hostname (e.g., olisikhmac)
- **Apply configuration**: `./result/sw/bin/darwin-rebuild switch --flake .`
  - Switches to the new system configuration (requires sudo)
- **Quick install**: `./install.sh`
  - Convenience script for build + switch
- **Validate flake**: `nix flake check`
  - Verify flake outputs, checks, and CI integrations
- **Uninstall home-manager**: `home-manager uninstall`

### Linting Commands (via lint.nvim)
- **JavaScript/TypeScript/JSON**: `eslint_d`
- **YAML**: `yamllint`
- **Python**: `pylint`
- **Dockerfile**: `hadolint`
- **Terraform**: `tflint`
- **Java**: `checkstyle`
- **Shell**: `shellcheck` (via LSP)

### Formatting Commands (via conform-nvim)
- **Nix**: `nixpkgs_fmt`
- **Lua**: `stylua`
- **Python**: `isort` (imports), `black`
- **Rust**: `rustfmt`
- **Shell**: `shfmt`
- **Go**: `goimports`, `gofumpt`
- **Scala**: `scalafmt`
- **Java**: `google-java-format`
- **Kotlin**: `ktlint`
- **Terraform**: `terraform_fmt`
- **JSON**: `jq`
- **JavaScript/TypeScript**: `prettierd` (fallback from LSP)

### Test Commands
- **Python**: `pytest path/to/test_file.py::test_name -q` or `pytest -q`
- **JavaScript/TypeScript**: `npm test -- path/to/test.spec.ts` or `yarn test path/to/test.spec.ts`
- **Lua/Neovim (Neotest)**: 
  ```bash
  nvim --headless -c 'lua require("neotest").run.run({vim.fn.expand("%")})' -c 'qa!'
  ```
- **Rust**: `cargo test test_name` (run a single test)
- **Go**: `go test ./path/to/package -run TestName`
- **Nix Flake tests**: `nix flake check`
- To run a single Nix-defined test: `nix test .#<testName>`

### Diagnostics & Code Actions (via none-ls)
- **Nix**: `statix` - provides code actions and fixes
- **Spelling**: `codespell`

## Code Style Guidelines

### General Principles
- Follow existing patterns in the codebase
- Prioritize readability and maintainability
- Use tooling and plugins for consistent formatting

### Imports
- **Nix files**: Use `inherit (lib) mkIf mkOption types;` for common functions
  - Namespace custom imports as `lib.${namespace}`
  - Group related imports together
- **Lua files**: Use `require("module")`
  - Localize requires at the top: `local module = require("module")`

### Formatting
- **Indentation**: 2 spaces (no tabs)
  - Expand tabs to spaces automatically
- **Line length**: ~120 characters (colorcolumn set to 121)
- **Trailing whitespace**: remove
- **Language-specific**:
  - **Nix**: Multi-line lists/attributes with consistent indentation; sort packages alphabetically; use `mkIf` for conditionals
  - **Lua**: 2-space indentation; double quotes for strings unless escaping

### Types
- **Nix**: Strict typing; use `types.str`, `types.bool`, `types.int`, etc.; define options via `mkOpt`; avoid `types.any`
- **Lua**: Dynamic typing; use local variables; annotate complex logic with comments

### Naming Conventions
- **Nix**: camelCase for variables/functions; snake_case for option names (`enable`, `extra_packages`);
  modules should be descriptive (e.g., `modules/home/git/default.nix`)
- **Lua**: camelCase for variables/functions; plugin configs follow plugin naming (e.g., `copy_file`)

### Error Handling
- **Nix**: Use `mkIf` for conditional configuration; assert critical invariants with `assert condition "message"`;
  graceful degradation via `mkIf`
- **Lua**: Use `assert()` for runtime checks; inspect return values in file ops; warn via `vim.notify(..., vim.log.levels.WARN)`

### Comments & Documentation
- **Nix**: Prefix with `# NOTE:`, `# TODO:`, `# WARN:`
- **Lua**: Prefix with `-- NOTE:`, `-- TODO:`, `-- WARN:`
- Keep comments concise and actionable; document non-obvious logic

### Booleans & Values
- Consistently use `true`/`false`
- Prefer double quotes for strings
- List elements one-per-line for readability
- Define helper functions as `local` in Lua

### File Organization
- Follow existing directory structure
- Group related functionality
- Use descriptive filenames

## Cursor/Copilot Rules
No existing Cursor or Copilot rules detected in this repository.
- No `.cursor/rules/` directory
- No `.cursorrules` file
- No `.github/copilot-instructions.md` file

If adding rules in the future, place them in the appropriate location and update this section.
