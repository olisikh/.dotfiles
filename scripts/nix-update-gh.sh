#!/usr/bin/env bash

set -euo pipefail

SEARCH_DIR="${1:-.}"
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
CURRENT_SYSTEM="${NIX_UPDATE_SYSTEM:-$(nix eval --impure --raw --expr 'builtins.currentSystem' 2>/dev/null || echo "aarch64-darwin")}"

if ! command -v gh &>/dev/null; then
    echo "Error: gh (GitHub CLI) is not installed."
    exit 1
fi

gh_api_jq() {
    local endpoint="$1"
    local jq_filter="$2"

    local attempt
    for attempt in 1 2 3; do
        local result=""
        if result=$(gh api "$endpoint" --jq "$jq_filter" </dev/null 2>/dev/null) && [[ -n "$result" && "$result" != "null" ]]; then
            echo "$result"
            return 0
        fi

        sleep "$attempt"
    done

    return 1
}

get_latest_commit() {
    local owner="$1"
    local repo="$2"
    local rev="$3"

    local ref="HEAD"
    if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
        ref="$rev"
    fi

    gh_api_jq "repos/$owner/$repo/commits/$ref" '.sha' || echo "Failed"
}

get_latest_hash() {
    local owner="$1"
    local repo="$2"
    local rev="$3"

    local raw_hash
    raw_hash=$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$rev.tar.gz" </dev/null 2>/dev/null)

    if [[ -n "$raw_hash" && "$raw_hash" != "Failed" ]]; then
        nix hash to-sri --type sha256 "$raw_hash" 2>/dev/null || echo "$raw_hash"
    else
        echo "Failed"
    fi
}

get_fetchurl_hash() {
    local url="$1"

    local raw_hash
    raw_hash=$(nix-prefetch-url "$url" </dev/null 2>/dev/null)

    if [[ -n "$raw_hash" && "$raw_hash" != "Failed" ]]; then
        nix hash to-sri --type sha256 "$raw_hash" 2>/dev/null || echo "$raw_hash"
    else
        echo "Failed"
    fi
}

get_latest_release_tag() {
    local owner="$1"
    local repo="$2"

    gh_api_jq "repos/$owner/$repo/releases/latest" '.tag_name' || true
}

resolve_sourceinfo_target() {
    local owner="$1"
    local repo="$2"
    local current_rev="$3"

    local latest_tag=""
    local latest_rev=""

    latest_tag=$(get_latest_release_tag "$owner" "$repo")

    if [[ -n "$latest_tag" && "$latest_tag" != "null" ]]; then
        latest_rev=$(get_latest_commit "$owner" "$repo" "$latest_tag")
    else
        latest_rev=$(get_latest_commit "$owner" "$repo" "$current_rev")
        latest_tag=""
    fi

    printf '%s\t%s\n' "$latest_rev" "$latest_tag"
}

resolve_fetchurl_url() {
    local file="$1"
    local url="$2"

    local resolved="$url"
    local name=""
    local value=""

    while IFS=$'\t' read -r name value; do
        resolved="${resolved//\$\{$name\}/$value}"
    done < <(sed -nE 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_-]*)[[:space:]]*=[[:space:]]*"([^"]*)"[[:space:]]*;.*/\1\t\2/p' "$file")

    printf '%s\n' "$resolved"
}

update_fetch_from_github_block() {
    local file="$1"
    local owner="$2"
    local repo="$3"
    local old_rev="$4"
    local new_rev="$5"
    local old_hash="$6"
    local new_hash="$7"
    local hash_key="$8"

    export PERL_OWNER="$owner"
    export PERL_REPO="$repo"
    export PERL_OLD_REV="$old_rev"
    export PERL_NEW_REV="$new_rev"
    export PERL_OLD_HASH="$old_hash"
    export PERL_NEW_HASH="$new_hash"
    export PERL_HASH_KEY="$hash_key"

    perl -0777 -pi -e '
        my $owner = quotemeta($ENV{PERL_OWNER});
        my $repo = quotemeta($ENV{PERL_REPO});
        my $old_rev = quotemeta($ENV{PERL_OLD_REV});
        my $new_rev = $ENV{PERL_NEW_REV};
        my $old_hash = quotemeta($ENV{PERL_OLD_HASH});
        my $new_hash = $ENV{PERL_NEW_HASH};
        my $hash_key = quotemeta($ENV{PERL_HASH_KEY});

        s/(fetchFromGitHub\s*\{[^}]*?"?owner"?\s*=\s*"?$owner"?\s*;[^}]*?"?repo"?\s*=\s*"?$repo"?\s*;[^}]*?\})
        /
        my $block = $1;
        $block =~ s|("?rev"?\s*=\s*")($old_rev)(")|${1}$new_rev${3}|g;
        $block =~ s|("$hash_key"\s*=\s*")($old_hash)(")|${1}$new_hash${3}|g;
        $block =~ s|([^"]$hash_key\s*=\s*")($old_hash)(")|${1}$new_hash${3}|g;
        $block
        /gex' "$file"
}

update_fetchurl_block() {
    local file="$1"
    local url="$2"
    local old_hash="$3"
    local new_hash="$4"
    local hash_key="$5"

    export PERL_URL="$url"
    export PERL_OLD_HASH="$old_hash"
    export PERL_NEW_HASH="$new_hash"
    export PERL_HASH_KEY="$hash_key"

    perl -0777 -pi -e '
        my $url = quotemeta($ENV{PERL_URL});
        my $old_hash = quotemeta($ENV{PERL_OLD_HASH});
        my $new_hash = $ENV{PERL_NEW_HASH};
        my $hash_key = quotemeta($ENV{PERL_HASH_KEY});

        s/((?:pkgs\.)?fetchurl\s*\{[^}]*?\burl\b\s*=\s*"$url"\s*;[^}]*?\})/
        my $block = $1;
        $block =~ s|(\b$hash_key\b\s*=\s*")($old_hash)(")|${1}$new_hash${3}|g;
        $block
        /gexs' "$file"
}

update_sourceinfo_block() {
    local file="$1"
    local owner="$2"
    local repo="$3"
    local old_rev="$4"
    local new_rev="$5"
    local old_hash="$6"
    local new_hash="$7"
    local old_pnpm_hash="${8:-}"
    local new_pnpm_hash="${9:-}"
    local latest_tag="${10:-}"

    export PERL_OWNER="$owner"
    export PERL_REPO="$repo"
    export PERL_OLD_REV="$old_rev"
    export PERL_NEW_REV="$new_rev"
    export PERL_OLD_HASH="$old_hash"
    export PERL_NEW_HASH="$new_hash"
    export PERL_OLD_PNPM_HASH="$old_pnpm_hash"
    export PERL_NEW_PNPM_HASH="$new_pnpm_hash"
    export PERL_LATEST_TAG="$latest_tag"

    perl -0777 -pi -e '
        my $owner = quotemeta($ENV{PERL_OWNER});
        my $repo = quotemeta($ENV{PERL_REPO});
        my $old_rev = quotemeta($ENV{PERL_OLD_REV});
        my $new_rev = $ENV{PERL_NEW_REV};
        my $old_hash = quotemeta($ENV{PERL_OLD_HASH});
        my $new_hash = $ENV{PERL_NEW_HASH};
        my $old_pnpm_hash = quotemeta($ENV{PERL_OLD_PNPM_HASH});
        my $new_pnpm_hash = $ENV{PERL_NEW_PNPM_HASH};
        my $latest_tag = $ENV{PERL_LATEST_TAG};

        s/(sourceInfo\s*=\s*\{[^}]*?\bowner\b\s*=\s*"?$owner"?\s*;[^}]*?\brepo\b\s*=\s*"?$repo"?\s*;[^}]*?\})/
        my $block = $1;
        $block =~ s|(\brev\b\s*=\s*")($old_rev)(")|${1}$new_rev${3}|g;
        $block =~ s|(\bhash\b\s*=\s*")($old_hash)(")|${1}$new_hash${3}|g;

        if (length $old_pnpm_hash && length $new_pnpm_hash) {
            $block =~ s|(\bpnpmDepsHash\b\s*=\s*")($old_pnpm_hash)(")|${1}$new_pnpm_hash${3}|g;
        }

        if (length $latest_tag) {
            $block =~ s|(#\s*Release tag\s+)v[^\s]+(\s+currently points at this commit\.)|${1}$latest_tag${2}|g;
        }

        $block
        /gexs' "$file"
}

get_openclaw_pnpm_hash() {
    local search_dir="$1"
    local file="$2"
    local owner="$3"
    local repo="$4"
    local old_rev="$5"
    local new_rev="$6"
    local old_hash="$7"
    local new_hash="$8"
    local old_pnpm_hash="$9"
    local latest_tag="${10:-}"

    local tmp_overlay
    tmp_overlay="$(mktemp -t nix-openclaw-overlay.XXXXXX.nix)"
    cp "$file" "$tmp_overlay"

    update_sourceinfo_block \
        "$tmp_overlay" \
        "$owner" \
        "$repo" \
        "$old_rev" \
        "$new_rev" \
        "$old_hash" \
        "$new_hash" \
        "$old_pnpm_hash" \
        "$FAKE_HASH" \
        "$latest_tag"

    local nix_expr
    nix_expr=$(cat <<EOF
let
  flake = builtins.getFlake "path:$search_dir";
  pkgs = import flake.inputs.nixpkgs {
    system = "$CURRENT_SYSTEM";
    overlays = [
      flake.inputs.nix-openclaw.overlays.default
      (import "$tmp_overlay" { inputs = flake.inputs; })
    ];
    config.allowUnfree = true;
  };
in
pkgs.openclawPackages.openclaw-gateway
EOF
)

    local build_log=""
    if build_log=$(nix build --impure --expr "$nix_expr" -L </dev/null 2>&1); then
        rm -f "$tmp_overlay"
        echo "Failed"
        return 1
    fi

    rm -f "$tmp_overlay"

    local updated_hash
    updated_hash=$(printf '%s\n' "$build_log" | sed -nE 's/.*got:[[:space:]]*(sha256-[^[:space:]]+).*/\1/p' | tail -n 1)

    if [[ -n "$updated_hash" ]]; then
        echo "$updated_hash"
    else
        echo "Failed"
        return 1
    fi
}

get_sourceinfo_dep_hash() {
    local search_dir="$1"
    local file="$2"
    local owner="$3"
    local repo="$4"
    local old_rev="$5"
    local new_rev="$6"
    local old_hash="$7"
    local new_hash="$8"
    local dep_key="$9"
    local dep_value="${10}"
    local latest_tag="${11:-}"

    case "$owner/$repo:$dep_key" in
    openclaw/openclaw:pnpmDepsHash)
        get_openclaw_pnpm_hash \
            "$search_dir" \
            "$file" \
            "$owner" \
            "$repo" \
            "$old_rev" \
            "$new_rev" \
            "$old_hash" \
            "$new_hash" \
            "$dep_value" \
            "$latest_tag"
        ;;
    *)
        echo "$dep_value"
        ;;
    esac
}

process_fetchurl_file() {
    local file="$1"

    local in_block=0
    local url=""
    local hash_val=""
    local hash_key=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ (^|[^A-Za-z0-9_-])((pkgs\.)?fetchurl)[[:space:]]*\{ ]]; then
            in_block=1
            url=""
            hash_val=""
            hash_key=""
        fi

        if [[ $in_block -eq 1 ]]; then
            if [[ "$line" =~ url[[:space:]]*= ]]; then
                url=$(echo "$line" | sed -E 's/.*url[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')
            elif [[ "$line" =~ (hash|sha256)[[:space:]]*= ]]; then
                hash_key=$(echo "$line" | sed -E 's/.*(hash|sha256)[[:space:]]*=.*/\1/')
                hash_val=$(echo "$line" | sed -E 's/.*(hash|sha256)[[:space:]]*=[[:space:]]*"([^"]+)".*/\2/')
            elif [[ "$line" == *"}"* ]]; then
                if [[ -n "$url" && -n "$hash_val" && -n "$hash_key" ]]; then
                    local resolved_url
                    resolved_url=$(resolve_fetchurl_url "$file" "$url")

                    if [[ "$resolved_url" == *'${'* ]]; then
                        echo "Checking fetchurl $url..."
                        echo "  Skipping: unresolved interpolation in URL: $resolved_url"
                        in_block=0
                        continue
                    fi

                    echo "Checking fetchurl $resolved_url..."
                    echo "  Fetching hash..."

                    local new_hash
                    new_hash=$(get_fetchurl_hash "$resolved_url")

                    if [[ "$new_hash" == "Failed" ]]; then
                        echo "  Error: Failed to fetch hash."
                    elif [[ "$hash_val" != "$new_hash" ]]; then
                        echo "  Hash update available: $hash_val -> $new_hash"
                        echo "  Updating file..."
                        update_fetchurl_block "$file" "$url" "$hash_val" "$new_hash" "$hash_key"
                        echo "  Done."
                    else
                        echo "  Up to date."
                    fi
                fi

                in_block=0
            fi
        fi
    done <"$file"
}

process_fetch_from_github_file() {
    local file="$1"

    local in_block=0
    local owner=""
    local repo=""
    local rev=""
    local hash_val=""
    local hash_key=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"fetchFromGitHub"* ]]; then
            in_block=1
            owner=""
            repo=""
            rev=""
            hash_val=""
            hash_key=""
        fi

        if [[ $in_block -eq 1 ]]; then
            if [[ "$line" =~ owner[[:space:]]*= ]]; then
                owner=$(echo "$line" | sed -E 's/.*owner[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ repo[[:space:]]*= ]]; then
                repo=$(echo "$line" | sed -E 's/.*repo[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ rev[[:space:]]*= ]]; then
                rev=$(echo "$line" | sed -E 's/.*rev[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ (hash|sha256)[[:space:]]*= ]]; then
                hash_key=$(echo "$line" | sed -E 's/.*(hash|sha256)[[:space:]]*=.*/\1/')
                hash_val=$(echo "$line" | sed -E 's/.*(hash|sha256)[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\2/')
            elif [[ "$line" == *"}"* ]]; then
                if [[ -n "$owner" && -n "$repo" ]]; then
                    echo "Checking fetchFromGitHub $owner/$repo..."

                    local latest_rev
                    latest_rev=$(get_latest_commit "$owner" "$repo" "$rev")

                    if [[ -n "$latest_rev" && "$latest_rev" != "null" && "$latest_rev" != "Failed" ]]; then
                        if [[ "$rev" != "$latest_rev" ]]; then
                            echo "  Update available: $rev -> $latest_rev"
                            echo "  Fetching new hash..."

                            local new_hash
                            new_hash=$(get_latest_hash "$owner" "$repo" "$latest_rev")

                            if [[ "$new_hash" != "Failed" ]]; then
                                echo "  Updating file..."
                                update_fetch_from_github_block "$file" "$owner" "$repo" "$rev" "$latest_rev" "$hash_val" "$new_hash" "$hash_key"
                                echo "  Done."
                            else
                                echo "  Error: Failed to fetch new hash."
                            fi
                        else
                            echo "  Up to date."
                        fi
                    else
                        echo "  Error: Could not reach GitHub for $owner/$repo"
                    fi
                fi

                in_block=0
            fi
        fi
    done <"$file"
}

process_sourceinfo_file() {
    local file="$1"

    local in_block=0
    local owner=""
    local repo=""
    local rev=""
    local hash_val=""
    local pnpm_hash=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ sourceInfo[[:space:]]*= ]]; then
            in_block=1
            owner=""
            repo=""
            rev=""
            hash_val=""
            pnpm_hash=""
        fi

        if [[ $in_block -eq 1 ]]; then
            if [[ "$line" =~ owner[[:space:]]*= ]]; then
                owner=$(echo "$line" | sed -E 's/.*owner[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ repo[[:space:]]*= ]]; then
                repo=$(echo "$line" | sed -E 's/.*repo[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ rev[[:space:]]*= ]]; then
                rev=$(echo "$line" | sed -E 's/.*rev[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ hash[[:space:]]*= ]]; then
                hash_val=$(echo "$line" | sed -E 's/.*hash[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ pnpmDepsHash[[:space:]]*= ]]; then
                pnpm_hash=$(echo "$line" | sed -E 's/.*pnpmDepsHash[[:space:]]*=[[:space:]]*"?([^"; ]+)"?.*/\1/')
            elif [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*\; ]]; then
                if [[ -n "$owner" && -n "$repo" && -n "$rev" && -n "$hash_val" ]]; then
                    echo "Checking sourceInfo $owner/$repo..."

                    local latest_rev=""
                    local latest_tag=""
                    IFS=$'\t' read -r latest_rev latest_tag < <(resolve_sourceinfo_target "$owner" "$repo" "$rev")

                    if [[ -n "$latest_rev" && "$latest_rev" != "null" && "$latest_rev" != "Failed" ]]; then
                        if [[ "$rev" != "$latest_rev" ]]; then
                            if [[ -n "$latest_tag" ]]; then
                                echo "  Update available via latest release $latest_tag: $rev -> $latest_rev"
                            else
                                echo "  Update available: $rev -> $latest_rev"
                            fi

                            echo "  Fetching new source hash..."
                            local new_hash=""
                            new_hash=$(get_latest_hash "$owner" "$repo" "$latest_rev")

                            if [[ "$new_hash" == "Failed" ]]; then
                                echo "  Error: Failed to fetch new source hash."
                                in_block=0
                                continue
                            fi

                            local new_pnpm_hash="$pnpm_hash"
                            if [[ -n "$pnpm_hash" ]]; then
                                echo "  Fetching updated pnpmDepsHash..."
                                new_pnpm_hash=$(get_sourceinfo_dep_hash \
                                    "$SEARCH_DIR" \
                                    "$file" \
                                    "$owner" \
                                    "$repo" \
                                    "$rev" \
                                    "$latest_rev" \
                                    "$hash_val" \
                                    "$new_hash" \
                                    "pnpmDepsHash" \
                                    "$pnpm_hash" \
                                    "$latest_tag")

                                if [[ "$new_pnpm_hash" == "Failed" ]]; then
                                    echo "  Error: Failed to fetch updated pnpmDepsHash."
                                    in_block=0
                                    continue
                                fi
                            fi

                            echo "  Updating file..."
                            update_sourceinfo_block \
                                "$file" \
                                "$owner" \
                                "$repo" \
                                "$rev" \
                                "$latest_rev" \
                                "$hash_val" \
                                "$new_hash" \
                                "$pnpm_hash" \
                                "$new_pnpm_hash" \
                                "$latest_tag"
                            echo "  Done."
                        else
                            echo "  Up to date."
                        fi
                    else
                        echo "  Error: Could not reach GitHub for $owner/$repo"
                    fi
                fi

                in_block=0
            fi
        fi
    done <"$file"
}

echo "Scanning Nix files in $SEARCH_DIR..."

mapfile -t files < <(find "$SEARCH_DIR" -name "*.nix" -type f 2>/dev/null | sort)

if [ ${#files[@]} -eq 0 ]; then
    echo "No Nix files found in $SEARCH_DIR"
    exit 1
fi

echo "Found ${#files[@]} Nix files"
echo ""

for file in "${files[@]}"; do
    if grep -q "fetchFromGitHub" "$file" || grep -q "sourceInfo[[:space:]]*=" "$file" || grep -Eq '(^|[^A-Za-z0-9_-])((pkgs\.)?fetchurl)[[:space:]]*\{' "$file"; then
        echo "--- File: $file ---"

        if grep -q "fetchFromGitHub" "$file"; then
            process_fetch_from_github_file "$file"
        fi

        if grep -Eq '(^|[^A-Za-z0-9_-])((pkgs\.)?fetchurl)[[:space:]]*\{' "$file"; then
            process_fetchurl_file "$file"
        fi

        if grep -q "sourceInfo[[:space:]]*=" "$file"; then
            process_sourceinfo_file "$file"
        fi

        echo ""
    fi
done
