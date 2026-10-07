#!/usr/bin/env bash
# Restore a single install manifest, retaining the replaced configs for recovery.
set -euo pipefail
[[ $# == 1 && -f "$1/paths" ]] || { printf 'Usage: bash scripts/restore.sh <backup-directory>\n' >&2; exit 2; }
backup="$(cd "$1" && pwd -P)"
recovery="$HOME/.dotfiles-backup/before-restore-$(date +%Y%m%d-%H%M%S)-$$"
while IFS= read -r relative; do
  case "$relative" in ''|/*|../*|*/../*) printf 'Invalid backup path: %s\n' "$relative" >&2; exit 1 ;; esac
  target="$HOME/$relative"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$recovery/$(dirname "$relative")"
    mv "$target" "$recovery/$relative"
  fi
  if [[ -e "$backup/files/$relative" || -L "$backup/files/$relative" ]]; then
    mkdir -p "$(dirname "$target")"
    cp -RPp "$backup/files/$relative" "$target"
  fi
done < "$backup/paths"
printf 'Restored configs. Replaced files are saved in %s.\n' "$recovery"
printf 'Packages are retained. Reload the affected apps after restoring.\n'
