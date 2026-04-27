#!/usr/bin/env bash

# Update doom config package pins to the latest git commit
# Usage: doom-pin-update.sh [--dry-run]

set -euo pipefail

EMACS_DIR="${HOME}/.config/emacs/.local/straight/repos"
CONFIG_FILE="${HOME}/src/github.com/taheris/dotfiles/home/emacs/config.org"
DRY_RUN=false

update_all_packages() {
    local -A packages
    local updates=0
    local temp_file pkg_name old_pin

    load_pinned_packages packages

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "⚠ No pinned packages found in config.org"
        echo ""
        echo "────────────────────────────────────────"
        echo "✓ Nothing to update"
        return 0
    fi

    temp_file=$(mktemp)
    cp "$CONFIG_FILE" "$temp_file"

    for pkg_name in "${!packages[@]}"; do
        old_pin="${packages[$pkg_name]}"
        if update_package "$pkg_name" "$old_pin" "$temp_file"; then
            ((updates++)) || true
        fi
    done

    if [[ $updates -eq 0 ]]; then
        echo "✓ All pins are up to date!"
        rm "$temp_file"
    else
        echo "Found $updates package(s) with updated commits"
        if [[ "$DRY_RUN" == true ]]; then
            rm "$temp_file"
        else
            mv "$temp_file" "$CONFIG_FILE"
            rm -f "${temp_file}.bak"
            echo "✓ Updated $CONFIG_FILE"
        fi
    fi

    return "$updates"
}

update_package() {
    local pkg_name="$1"
    local old_pin="$2"
    local temp_file="$3"
    local repo_dir new_pin

    repo_dir=$(find_repo_dir "$pkg_name")

    if [[ -z "$repo_dir" ]]; then
        echo "⚠ $pkg_name: no matching repo found in $EMACS_DIR"
        return 1
    fi

    # Fetch latest changes from remote
    echo "🔄 Fetching $pkg_name..."
    if ! fetch_repo "$EMACS_DIR/$repo_dir"; then
        echo "⚠ $pkg_name: failed to fetch from remote"
        return 1
    fi

    # Get the latest commit from remote tracking branch
    new_pin=$(get_latest_commit "$EMACS_DIR/$repo_dir")

    if [[ -z "$new_pin" ]]; then
        echo "⚠ $pkg_name: could not get git hash from $repo_dir"
        return 1
    fi

    if [[ "$old_pin" != "$new_pin" ]]; then
        echo "📦 $pkg_name"
        if [[ "$repo_dir" != "$pkg_name" ]]; then
            echo "   Repo: $repo_dir"
        fi
        echo "   Old: $old_pin"
        echo "   New: $new_pin"
        echo ""

        if [[ "$DRY_RUN" == false ]]; then
            update_pin_in_file "$temp_file" "$old_pin" "$new_pin"
        fi
        return 0
    else
        echo "✓ $pkg_name (up to date)"
        return 1
    fi
}

# Fetch latest changes for a repository
fetch_repo() {
    local repo_path="$1"
    git -C "$repo_path" fetch --quiet 2>/dev/null
}

# Get the latest commit hash from remote tracking branch
get_latest_commit() {
    local repo_path="$1"
    # Try to get the latest commit from the remote tracking branch
    git -C "$repo_path" rev-parse origin/HEAD 2>/dev/null || \
        git -C "$repo_path" rev-parse origin/main 2>/dev/null || \
        git -C "$repo_path" rev-parse origin/master 2>/dev/null || \
        git -C "$repo_path" rev-parse '@{u}' 2>/dev/null || \
        echo ""
}

# Update package pin in file
update_pin_in_file() {
    local temp_file="$1"
    local old_pin="$2"
    local new_pin="$3"

    sed -i.bak "s/:pin \"$old_pin\"/:pin \"$new_pin\"/" "$temp_file"
}

find_repo_dir() {
    local pkg_name="$1"
    local cache_file repo_name

    # First, try to find the mapping in straight.el's cache file
    cache_file=$(find "${HOME}/.config/emacs/.local/straight" -maxdepth 1 -name "build-*-cache.el" 2>/dev/null | head -1)
    if [[ -n "$cache_file" && -f "$cache_file" ]]; then
        repo_name=$(extract_repo_from_cache "$pkg_name" "$cache_file")

        if [[ -n "$repo_name" && -d "$EMACS_DIR/$repo_name" ]]; then
            echo "$repo_name"
            return 0
        fi
    fi

    # Fallback: exact directory name match
    if [[ -d "$EMACS_DIR/$pkg_name" ]]; then
        echo "$pkg_name"
        return 0
    fi

    # Fallback: try common naming patterns
    local suffix
    for suffix in ".el" "-mode"; do
        if [[ -d "$EMACS_DIR/${pkg_name}${suffix}" ]]; then
            echo "${pkg_name}${suffix}"
            return 0
        fi
    done

    return 1
}

# Extract repository name from straight.el cache file
extract_repo_from_cache() {
    local pkg_name="$1"
    local cache_file="$2"

    awk -v pkg="$pkg_name" '
    {
        # Find the package entry by searching for "pkg-name" (
        pos = index($0, "\"" pkg "\" (")
        if (pos > 0) {
            # Start after the opening paren
            rest = substr($0, pos + length(pkg) + 4)
            depth = 1
            entry = ""

            # Extract the full entry by tracking paren depth
            for (i = 1; i <= length(rest); i++) {
                c = substr(rest, i, 1)
                entry = entry c
                if (c == "(") depth++
                if (c == ")") {
                    depth--
                    if (depth == 0) break
                }
            }

            # Now extract :local-repo from the entry
            if (entry ~ /:local-repo "[^"]*"/) {
                temp = entry
                sub(/.*:local-repo "/, "", temp)
                sub(/".*/, "", temp)
                print temp
            }
            exit
        }
    }
    ' "$cache_file"
}

# Populate associative array with pinned packages
load_pinned_packages() {
    local -n packages_ref=$1
    local pkg_name pin_hash

    while IFS='|' read -r pkg_name pin_hash; do
        if [[ -n "$pkg_name" && -n "$pin_hash" ]]; then
            packages_ref["$pkg_name"]="$pin_hash"
        fi
    done < <(parse_pinned_packages)
}

# Parse config.org and extract pinned packages
parse_pinned_packages() {
    awk '
        /^\(package!/ {
            # Start of package declaration
            in_package = 1
            pkg_line = $0

            # Extract package name using sub/gsub
            temp = $0
            sub(/.*\(package! +/, "", temp)
            sub(/ .*/, "", temp)
            sub(/\).*/, "", temp)
            pkg_name = temp

            # Check if :pin is on same line
            if ($0 ~ /:pin +"[a-f0-9]+"/) {
                temp = $0
                sub(/.*:pin +"/, "", temp)
                sub(/".*/, "", temp)
                print pkg_name "|" temp
                in_package = 0
                next
            }
        }

        in_package && /:pin/ {
            # :pin on a different line
            if ($0 ~ /:pin +"[a-f0-9]+"/) {
                temp = $0
                sub(/.*:pin +"/, "", temp)
                sub(/".*/, "", temp)
                print pkg_name "|" temp
                in_package = 0
            }
        }

        in_package && /^\)/ {
            # End of package declaration without pin
            in_package = 0
        }
    ' "$CONFIG_FILE"
}

parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                DRY_RUN=true
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $arg" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}

usage() {
    cat <<EOF
Usage: doom-pin-update.sh [--dry-run]

Options:
  --dry-run    Show what would be updated
  --help       Show this help message
EOF
}

main() {
    parse_args "$@"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: config.org not found at $CONFIG_FILE" >&2
        exit 1
    elif [[ ! -d "$EMACS_DIR" ]]; then
        echo "Error: Emacs straight repos directory not found at $EMACS_DIR" >&2
        exit 1
    fi

    echo "Scanning config.org for pinned packages..."
    echo ""

    update_all_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
