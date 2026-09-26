#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd -P)"
build_script="$repo_root/modules/home/core/user/scripts/nix-build"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

mock_bin="$test_dir/bin"
log_file="$test_dir/commands.log"
error_file="$test_dir/error.log"
mkdir -p "$mock_bin"

cat > "$mock_bin/scutil" <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" != --get || "${2:-}" != LocalHostName ]]; then
    exit 1
fi

printf '%s\n' "${TEST_LOCAL_HOSTNAME:?}"
EOF

cat > "$mock_bin/darwin-rebuild" <<'EOF'
#!/usr/bin/env bash

printf 'darwin-rebuild %s\n' "$*" >> "$TEST_LOG"
EOF

cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash

printf 'sudo %s\n' "$*" >> "$TEST_LOG"
"$@"
EOF

cat > "$mock_bin/yabai" <<'EOF'
#!/usr/bin/env bash

printf 'yabai %s\n' "$*" >> "$TEST_LOG"
EOF

chmod +x "$mock_bin"/*

assert_log_contains() {
    local expected="$1"
    if ! grep -Fq -- "$expected" "$log_file"; then
        echo "Expected command was not recorded: $expected" >&2
        cat "$log_file" >&2
        exit 1
    fi
}

assert_output_contains() {
    local output="$1"
    local expected="$2"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected build output to contain: $expected" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi
}

default_home="$test_dir/default-home"
mkdir -p "$default_home"

: > "$log_file"
build_output="$(TEST_LOCAL_HOSTNAME=olisikh-mini \
    SUDO_USER='' \
    USER=olisikh \
    HOME="$default_home" \
    NIX_DOTFILES_ROOT="$repo_root" \
    TEST_LOG="$log_file" \
    PATH="$mock_bin:$PATH" \
    "$build_script" --skip-gc --show-trace)"
assert_output_contains "$build_output" "==> Profile: default"
assert_output_contains "$build_output" "==> Profile source: default (no state file at $default_home/.config/dotfiles/.env)"
assert_output_contains "$build_output" "==> System reference: .#darwinConfigurations.olisikh-mini"
assert_output_contains "$build_output" '==> Home reference: .#homeConfigurations."olisikh@olisikh-mini"'
assert_log_contains "darwin-rebuild switch --flake $repo_root#olisikh-mini --show-trace"
if grep -Fq -- "yabai" "$log_file"; then
    echo "The default mini profile must not load yabai's scripting addition." >&2
    cat "$log_file" >&2
    exit 1
fi

explicit_home="$test_dir/explicit-home"
mkdir -p "$explicit_home"

: > "$log_file"
build_output="$(TEST_LOCAL_HOSTNAME=olisikh-mini \
    SUDO_USER='' \
    USER=olisikh \
    HOME="$explicit_home" \
    NIX_DOTFILES_ROOT="$repo_root" \
    TEST_LOG="$log_file" \
    PATH="$mock_bin:$PATH" \
    "$build_script" -p boring --skip-gc)"
assert_output_contains "$build_output" "==> Profile: boring"
assert_output_contains "$build_output" "==> Profile source: command line"
assert_output_contains "$build_output" "==> System reference: .#darwinConfigurations.olisikh-mini-boring"
assert_output_contains "$build_output" '==> Home reference: .#homeConfigurations."olisikh@olisikh-mini-boring"'
assert_log_contains "darwin-rebuild switch --flake $repo_root#olisikh-mini-boring"
if grep -Fq -- "yabai" "$log_file"; then
    echo "The boring profile must not load yabai's scripting addition." >&2
    cat "$log_file" >&2
    exit 1
fi

state_home="$test_dir/state-home"
mkdir -p "$state_home/.config/dotfiles"
printf '%s\n' "DOTFILES_PROFILE=boring" > "$state_home/.config/dotfiles/.env"

: > "$log_file"
build_output="$(TEST_LOCAL_HOSTNAME=olisikh-mini \
    SUDO_USER='' \
    USER=olisikh \
    HOME="$state_home" \
    NIX_DOTFILES_ROOT="$repo_root" \
    TEST_LOG="$log_file" \
    PATH="$mock_bin:$PATH" \
    "$build_script" --skip-gc)"
assert_output_contains "$build_output" "==> Profile: boring"
assert_output_contains "$build_output" "==> Profile source: $state_home/.config/dotfiles/.env"
assert_output_contains "$build_output" "==> System reference: .#darwinConfigurations.olisikh-mini-boring"
assert_log_contains "darwin-rebuild switch --flake $repo_root#olisikh-mini-boring"

: > "$log_file"
if TEST_LOCAL_HOSTNAME=olisikh-mbair \
    NIX_DOTFILES_ROOT="$repo_root" \
    TEST_LOG="$log_file" \
    PATH="$mock_bin:$PATH" \
    "$build_script" --profile boring --skip-gc >"$error_file" 2>&1; then
    echo "An unsupported profile unexpectedly succeeded." >&2
    exit 1
fi
if grep -Fq -- "sudo " "$log_file"; then
    echo "An unsupported profile must be rejected before sudo." >&2
    cat "$log_file" >&2
    exit 1
fi
if ! grep -Fq -- "profile 'boring' is not available for system 'olisikh-mbair'" "$error_file"; then
    echo "The unsupported profile error was not clear." >&2
    cat "$error_file" >&2
    exit 1
fi

printf '%s\n' "nix-build profile tests passed"
