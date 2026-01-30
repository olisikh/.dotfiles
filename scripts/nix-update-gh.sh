#!/usr/bin/env bash

set -euo pipefail

SEARCH_DIR="${1:-.}"

if ! command -v gh &>/dev/null; then
    echo "Error: gh (GitHub CLI) is not installed."
    exit 1
fi

get_latest_commit() {
    local owner="$1"
    local repo="$2"
    local rev="$3"

    local ref="HEAD"
    if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
        ref="$rev"
    fi

    gh api "repos/$owner/$repo/commits/$ref" --jq '.sha' 2>/dev/null || echo "Failed"
}

get_latest_hash() {
    local owner="$1"
    local repo="$2"
    local rev="$3"

    local raw_hash
    raw_hash=$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$rev.tar.gz" 2>/dev/null)

    if [[ -n "$raw_hash" && "$raw_hash" != "Failed" ]]; then
        nix hash to-sri --type sha256 "$raw_hash" 2>/dev/null || echo "$raw_hash"
    else
        echo "Failed"
    fi
}

update_file() {
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

echo "Scanning for fetchFromGitHub calls in $SEARCH_DIR..."

mapfile -t files < <(find "$SEARCH_DIR" -name "*.nix" -type f -exec grep -l "fetchFromGitHub" {} \; 2>/dev/null)

if [ ${#files[@]} -eq 0 ]; then
    echo "No fetchFromGitHub calls found in $SEARCH_DIR"
    exit 1
fi

echo "Found ${#files[@]} files with fetchFromGitHub calls"
echo ""

for file in "${files[@]}"; do
    echo "--- File: $file ---"

    in_block=0
    owner=""
    repo=""
    rev=""
    hash_val=""
    hash_key=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"fetchFromGitHub"* ]]; then
            in_block=1
            owner="" repo="" rev="" hash_val="" hash_key=""
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
                    echo "Checking $owner/$repo..."

                    latest_rev=$(get_latest_commit "$owner" "$repo" "$rev")

                    if [[ -n "$latest_rev" && "$latest_rev" != "null" && "$latest_rev" != "Failed" ]]; then
                        if [[ "$rev" != "$latest_rev" ]]; then
                            echo "  Update available: $rev -> $latest_rev"
                            echo "  Fetching new hash..."
                            new_hash=$(get_latest_hash "$owner" "$repo" "$latest_rev")

                            if [[ "$new_hash" != "Failed" ]]; then
                                echo "  Updating file..."
                                update_file "$file" "$owner" "$repo" "$rev" "$latest_rev" "$hash_val" "$new_hash" "$hash_key"
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
    echo ""
done
