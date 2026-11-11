
#!/usr/bin/env bash
# Install skills from this repository into Codex.
# Only individual skills are linked; existing directories are preserved.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_DIR="$(cd "$SCRIPT_DIR/src/skills" 2>/dev/null && pwd -P)" || {
    echo "error: src/skills not found" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage:
  ./codex.sh [install] [PROJECT_DIR] [--force]
  ./codex.sh uninstall [PROJECT_DIR]
  ./codex.sh --help

Without PROJECT_DIR: install to ~/.agents/skills.
With PROJECT_DIR: install to PROJECT_DIR/.agents/skills.
--force: replace conflicting files or symlinks, not real directories.
EOF
}

ACTION="install"
FORCE=0
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        install|uninstall) ACTION="$1" ;;
        -f|--force) FORCE=1 ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "error: unknown option $1" >&2; exit 1 ;;
        *)
            if [[ -n "$PROJECT_DIR" ]]; then
                echo "error: multiple project directories" >&2
                exit 1
            fi
            PROJECT_DIR="$1"
            ;;
    esac
    shift
done

# Git Bash on Windows must use real symbolic links for installation.
if [[ "$ACTION" == "install" && -n "${MSYSTEM:-}" && "${MSYS:-}" != *winsymlinks:nativestrict* ]]; then
    echo "error: Git Bash requires native symlink mode." >&2
    echo "Run: MSYS=winsymlinks:nativestrict bash codex.sh install" >&2
    exit 1
fi

if [[ -n "$PROJECT_DIR" ]]; then
    TARGET_DIR="$PROJECT_DIR/.agents/skills"
else
    TARGET_DIR="$HOME/.agents/skills"
fi

if [[ "$ACTION" == "install" ]]; then
    mkdir -p "$TARGET_DIR"
elif [[ ! -d "$TARGET_DIR" ]]; then
    echo "nothing to uninstall"
    exit 0
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd -P)"

is_ours() {
    local dest="$1" raw resolved
    [[ -L "$dest" ]] || return 1

    raw="$(readlink "$dest")"
    resolved="$(readlink -f "$dest" 2>/dev/null || true)"

    case "$resolved" in
        "$SRC_DIR"/*) return 0 ;;
    esac
    case "$raw" in
        "$SRC_DIR"/*) return 0 ;;
    esac
    return 1
}

install_one() {
    local src="$1" dest="$2"

    if [[ -L "$dest" ]]; then
        if [[ "$(readlink -f "$dest" 2>/dev/null || true)" == "$src" ]]; then
            echo "already linked: ${dest##*/}"
            return
        fi
        if (( ! FORCE )); then
            echo "skip existing symlink: $dest" >&2
            return
        fi
        rm -f "$dest"
    elif [[ -e "$dest" ]]; then
        if [[ -d "$dest" ]]; then
            echo "skip real directory: $dest" >&2
            return
        fi
        if (( ! FORCE )); then
            echo "skip existing file: $dest" >&2
            return
        fi
        rm -f "$dest"
    fi

    ln -s "$src" "$dest"
    echo "linked: $dest"
}

if [[ "$ACTION" == "install" ]]; then
    while IFS= read -r -d '' item; do
        name="$(basename "$item")"
        [[ "$name" == .* ]] && continue
        [[ -d "$item" && -f "$item/SKILL.md" ]] || continue

        install_one "$item" "$TARGET_DIR/$name"
    done < <(find "$SRC_DIR" -mindepth 1 -maxdepth 1 -print0)
else
    while IFS= read -r -d '' entry; do
        if is_ours "$entry"; then
            rm -f "$entry"
            echo "removed: $entry"
        fi
    done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type l -print0)
fi

echo "done: $ACTION"
