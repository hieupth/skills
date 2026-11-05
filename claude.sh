#!/usr/bin/env bash
#
# claude.sh — manage symlinks from this repo's src/ into a Claude
# config directory (.claude).
#
# What gets linked (one symlink per item, never the whole directory, so this
# collection can coexist with your own skills/agents):
#
#   src/CLAUDE.md      ->  $TARGET/CLAUDE.md
#   src/skills/<name>  ->  $TARGET/skills/<name>
#   src/agents/<name>  ->  $TARGET/agents/<name>
#
# $TARGET = $PROJECT_DIR/.claude. PROJECT_DIR defaults to $HOME, so with no
# arguments everything is linked into the user-level ~/.claude.
#
# Usage:
#   ./claude.sh [install] [PROJECT_DIR] [--force]
#   ./claude.sh uninstall [PROJECT_DIR]
#   ./claude.sh --help
#
# PROJECT_DIR     A project root to install into (uses its .claude/).
#                 Defaults to $HOME (i.e. ~/.claude).
# --force / -f    Overwrite existing files/symlinks at the target. Real
#                 directories are never deleted automatically — remove them
#                 by hand if that is really what you want.
#
# uninstall removes only symlinks whose target lives under this repo's src/,
# plus any broken symlink (missing target) in the paths it manages.

set -euo pipefail

# --- locate the repo (this script's directory) ------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_DIR="$(cd "$SCRIPT_DIR/src" 2>/dev/null && pwd -P)" || {
    echo "fatal: could not find '$SCRIPT_DIR/src' — is the script inside the repo?" >&2
    exit 1
}

# --- pretty output (disabled when stdout is not a tty) ----------------------
if [[ -t 1 ]]; then
    C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
    C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_RST=""
fi
ok()   { printf '%s==>%s %s\n'  "$C_OK"   "$C_RST" "$*"; }
warn() { printf '%s!!%s  %s\n' "$C_WARN" "$C_RST" "$*" >&2; }
err()  { printf '%sxx%s  %s\n' "$C_ERR"  "$C_RST" "$*" >&2; }
die()  { err "$*"; exit 1; }

COUNT_LINKED=0
COUNT_REMOVED=0

usage() {
    cat <<'EOF'
claude.sh — symlink this repo's src/ into a Claude .claude directory.

Usage:
  claude.sh [install] [PROJECT_DIR] [--force]
  claude.sh uninstall [PROJECT_DIR]
  claude.sh --help

Arguments:
  PROJECT_DIR   Project root to install into (uses <PROJECT_DIR>/.claude).
                Defaults to $HOME, i.e. the user-level ~/.claude.
  install       Link src/ items into the target (default action).
  uninstall     Remove symlinks pointing back into this repo's src/, plus
                broken symlinks (missing target) in the managed paths.
  --force, -f   Overwrite existing files/symlinks (never deletes real dirs).
EOF
}

# --- argument parsing -------------------------------------------------------
ACTION="install"
FORCE=0
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        install|uninstall) ACTION="$1"; shift ;;
        -f|--force)        FORCE=1; shift ;;
        -h|--help)         usage; exit 0 ;;
        --)                shift; [[ $# -gt 0 ]] && PROJECT_DIR="$1" ;;
        -*)                die "unknown option: $1 (see --help)" ;;
        *)                 PROJECT_DIR="$1"; shift ;;
    esac
done

PROJECT_DIR="${PROJECT_DIR:-$HOME}"
TARGET_DIR="$PROJECT_DIR/.claude"

# Resolve to an absolute, canonical path so symlinks survive cwd changes.
if [[ "$ACTION" == "install" ]]; then
    mkdir -p "$TARGET_DIR" || die "cannot create target dir: $TARGET_DIR"
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd -P)"
elif [[ ! -d "$TARGET_DIR" ]]; then
    ok "target does not exist, nothing to uninstall: $TARGET_DIR"
    exit 0
else
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd -P)"
fi

rel() { printf '%s' "${1#"$TARGET_DIR"/}"; }   # path relative to TARGET_DIR

# --- create one symlink: dest -> src ----------------------------------------
link_one() {
    local src="$1" dest="$2"
    # src is always under the already-canonical SRC_DIR, so it is absolute.
    if [[ -L "$dest" ]]; then
        local cur
        cur="$(readlink -f "$dest" 2>/dev/null || true)"
        if [[ "$cur" == "$src" ]]; then
            ok "already linked: $(rel "$dest")"
            return 0
        fi
        if [[ "$FORCE" -eq 1 ]]; then
            rm -f "$dest"
        else
            warn "skip (symlink exists, not ours): $(rel "$dest")"
            return 0
        fi
    elif [[ -e "$dest" ]]; then
        if [[ "$FORCE" -eq 1 ]]; then
            if [[ -d "$dest" ]]; then
                warn "refusing to overwrite real directory: $(rel "$dest")"
                return 0
            fi
            rm -f "$dest"
        else
            warn "skip (exists, not a symlink): $(rel "$dest")"
            return 0
        fi
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    ok "linked: $(rel "$dest") ${C_DIM}-> $src${C_RST}"
    COUNT_LINKED=$((COUNT_LINKED + 1))
}

# --- remove dest if it is a symlink we created ------------------------------
unlink_if_ours() {
    local dest="$1"
    [[ -L "$dest" ]] || return 0
    local cur raw
    cur="$(readlink -f "$dest" 2>/dev/null || true)"
    raw="$(readlink "$dest")"

    # Ours if either the resolved target or the raw link text is under SRC_DIR
    # (raw check also catches dangling links to a since-removed source item).
    case "$cur/" in "$SRC_DIR/"*) ;; *)
        case "$raw" in "$SRC_DIR"*) ;; *)
            warn "keep (not ours): $(rel "$dest")"; return 0 ;;
        esac
    esac

    rm -f "$dest"
    ok "removed: $(rel "$dest")"
    COUNT_REMOVED=$((COUNT_REMOVED + 1))
}

# --- remove one entry: broken symlinks, then symlinks we created ------------
handle_unlink() {
    local dest="$1"
    if [[ -L "$dest" && ! -e "$dest" ]]; then
        rm -f "$dest"
        ok "removed broken symlink: $(rel "$dest")"
        COUNT_REMOVED=$((COUNT_REMOVED + 1))
        return 0
    fi
    unlink_if_ours "$dest"
}

# --- actions ----------------------------------------------------------------
do_install() {
    ok "install $SRC_DIR -> $TARGET_DIR"
    [[ -f "$SRC_DIR/CLAUDE.md" ]] && link_one "$SRC_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

    for sub in skills agents; do
        local src_sub="$SRC_DIR/$sub"
        [[ -d "$src_sub" ]] || continue
        while IFS= read -r -d '' item; do
            local name
            name="$(basename "$item")"
            [[ "$name" == .* ]] && continue          # skip .gitkeep etc.
            link_one "$item" "$TARGET_DIR/$sub/$name"
        done < <(find "$src_sub" -mindepth 1 -maxdepth 1 -print0)
    done
}

do_uninstall() {
    ok "uninstall from $TARGET_DIR"
    handle_unlink "$TARGET_DIR/CLAUDE.md"

    for sub in skills agents; do
        local target_sub="$TARGET_DIR/$sub"
        [[ -d "$target_sub" ]] || continue
        while IFS= read -r -d '' entry; do
            handle_unlink "$entry"
        done < <(find "$target_sub" -mindepth 1 -maxdepth 1 -type l -print0)
    done
}

case "$ACTION" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    *)         die "unknown action: $ACTION" ;;
esac

if [[ "$ACTION" == "install" ]]; then
    ok "done — $COUNT_LINKED linked."
else
    ok "done — $COUNT_REMOVED removed."
fi
