# AGENTS.md - Guidelines for Agentic Coding Agents

This file provides essential information for AI coding agents working in this Nix-based dotfiles repository.

## Build/Lint/Test Commands

### Build Commands
- **Full system build**: `nix build .#darwinConfigurations.${HOSTNAME}.system --show-trace --print-build-logs -vvv`
  - Builds the complete Darwin system configuration
  - Replace `${HOSTNAME}` with actual hostname (e.g., olisikhmac)
- **Apply configuration**: `./result/sw/bin/darwin-rebuild switch --flake .`
  - Switches to the new system configuration (requires sudo)
- **Quick install**: `./install.sh` - Convenience script for build + switch
- **Validate flake**: `nix flake check` - Verify flake outputs and checks
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

### Diagnostics & Code Actions (via none-ls)
- **Nix**: `statix` - Code actions for improvements
- **Spelling**: `codespell`

No automated test suite; verify changes via `./install.sh` and manual testing.

## Code Style Guidelines

### General Principles
- Follow existing patterns in the codebase
- Prioritize readability and maintainability
- Use tools/plugins for consistent formatting

### Imports
- **Nix files**: Use `inherit (lib) mkIf mkOption types;` for common functions
  - Namespace custom imports: `lib.${namespace}`
  - Group related imports together
- **Lua files**: Use `require('module')` for imports
  - Localize requires at top of file: `local module = require('module')`

### Formatting
- **Indentation**: 2 spaces (no tabs)
  - Expand tabs to spaces automatically
- **Line Length**: ~120 characters
  - Colorcolumn set to "121" in Neovim config
- **Whitespace**: Trim trailing whitespace
  - List characters configured but disabled by default
- **Language-Specific**:
  - **Nix**: Multi-line lists/attrs with consistent indentation
    - Sort packages alphabetically where possible
    - Use `mkIf` for conditional blocks
  - **Lua**: Consistent 2-space indentation
    - Use double quotes for strings unless escaping required

### Types
- **Nix**: Strict typing required
  - Use `types.str`, `types.bool`, `types.int`, etc.
  - Define options with `mkOpt` helper
  - Avoid `types.any` unless necessary
- **Lua**: Dynamic typing
  - Use local variables consistently
  - Type hints via comments if complex

### Naming Conventions
- **Nix**: camelCase for variables and functions
  - Options use snake_case: `enable`, `nightly`, `extra_packages`
  - Module names: descriptive, e.g., `modules/home/git/default.nix`
- **Lua**: camelCase for variables and functions
  - Examples: `copy_file`, `folder_exists`
  - Plugin configs: follow plugin naming

### Error Handling
- **Nix**: Use `mkIf` for conditional configuration
  - Asserts for critical validation: `assert condition "message";`
  - Graceful degradation with `mkIf`
- **Lua**: Use `assert()` for error checking
  - File operations: check return values
  - Notify for warnings: `vim.notify("message", vim.log.levels.WARN)`

### Comments and Documentation
- **Nix**: `# NOTE:`, `# TODO:`, `# WARN:` prefixes
- **Lua**: `-- NOTE:`, `-- TODO:`, `-- WARN:` prefixes
- Keep comments concise and actionable
- Document complex logic or non-obvious decisions

### Booleans and Values
- Use `true`/`false` consistently
- Prefer double quotes for strings
- Lists/arrays: one item per line for readability
- Functions: local in Lua, concise in Nix

### File Organization
- Follow existing directory structure
- Group related functionality
- Use descriptive filenames

## Cursor/Copilot Rules
No existing Cursor or Copilot rules found in this repository.
- No `.cursor/rules/` directory
- No `.cursorrules` file
- No `.github/copilot-instructions.md` file

If adding rules in the future, place them in the appropriate locations and update this section.
