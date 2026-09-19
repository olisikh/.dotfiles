#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
install_script="$repo_root/install.sh"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

mock_bin="$test_dir/bin"
log_file="$test_dir/commands.log"
mkdir -p "$mock_bin"

cat > "$mock_bin/scutil" <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" != --get || "${2:-}" != LocalHostName ]]; then
    exit 1
fi

printf '%s\n' "${TEST_LOCAL_HOSTNAME:?}"
EOF

cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash

printf 'sudo %s\n' "$*" >> "$TEST_LOG"
printf '==> Mock sudo: %s\n' "$*"
EOF

chmod +x "$mock_bin"/*

assert_output_contains() {
    local output="$1"
    local expected="$2"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected install output to contain: $expected" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi
}

: > "$log_file"
install_output="$(
    cd "$repo_root"
    TEST_LOCAL_HOSTNAME=olisikh-mini \
        SUDO_USER='' \
        USER=olisikh \
        SCUTIL_BIN="$mock_bin/scutil" \
        TEST_LOG="$log_file" \
        PATH="$mock_bin:$PATH" \
        "$install_script" -p boring
)"

assert_output_contains "$install_output" "==> Profile: boring"
assert_output_contains "$install_output" "==> System reference: .#darwinConfigurations.olisikh-mini-boring"
assert_output_contains "$install_output" '==> Home reference: .#homeConfigurations."olisikh@olisikh-mini-boring"'
assert_output_contains "$install_output" "==> Mock sudo: nix build .#darwinConfigurations.olisikh-mini-boring.system"
assert_output_contains "$install_output" "==> Mock sudo: ./result/sw/bin/darwin-rebuild switch --flake .#olisikh-mini-boring"

profile_line="$(printf '%s\n' "$install_output" | grep -nF '==> Profile: boring' | cut -d: -f1)"
first_sudo_line="$(printf '%s\n' "$install_output" | grep -nF '==> Mock sudo:' | head -n1 | cut -d: -f1)"
if (( profile_line >= first_sudo_line )); then
    echo "Profile selection must be shown before privileged installation commands." >&2
    printf '%s\n' "$install_output" >&2
    exit 1
fi

if ! grep -Fq -- "nix build .#darwinConfigurations.olisikh-mini-boring.system" "$log_file"; then
    echo "Expected the boring Darwin configuration to be built." >&2
    cat "$log_file" >&2
    exit 1
fi
if ! grep -Fq -- "./result/sw/bin/darwin-rebuild switch --flake .#olisikh-mini-boring" "$log_file"; then
    echo "Expected the boring Darwin configuration to be switched." >&2
    cat "$log_file" >&2
    exit 1
fi

printf '%s\n' "install profile tests passed"
