#!/usr/bin/env bash
# Install shared preferences and the selected platform's user overrides.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)-$$"
PLATFORM=""
DRY_RUN=0
PACKAGES=1
SYNC=1

usage() {
  cat <<'HELP'
Usage: bash install.sh [--platform macos|omarchy] [--configs-only|--skip-packages] [--dry-run]
  Default          Install packages, link configs, and install config dependencies.
  --configs-only   Link configs using existing tools; no packages or dependency downloads.
  --skip-packages  Link configs and sync dependencies using already installed tools.
  --dry-run        Print the selected links without modifying files or installing anything.
  --platform       Override platform detection (useful for reviewing/testing either profile).
HELP
}

while (($#)); do
  case "$1" in
    --platform) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; PLATFORM="$2"; shift 2 ;;
    --configs-only) PACKAGES=0; SYNC=0; shift ;;
    --skip-packages) PACKAGES=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
if [[ -z "$PLATFORM" ]]; then
  case "$(uname -s)" in
    Darwin) PLATFORM=macos ;;
    Linux) [[ -f /usr/share/omarchy/default/hypr/bootstrap.lua ]] && PLATFORM=omarchy ;;
  esac
fi
case "$PLATFORM" in macos|omarchy) ;; *) printf 'Supported platforms: macos and omarchy.\n' >&2; exit 2 ;; esac
if [[ "$DRY_RUN" == 0 && "$EUID" == 0 ]]; then
  printf 'Run as your normal user. Package commands request elevation when needed.\n' >&2
  exit 1
fi

source "$REPO_DIR/scripts/install-shared.sh"
source "$REPO_DIR/scripts/install-$PLATFORM.sh"
printf 'Installing %s configs from %s\n' "$PLATFORM" "$REPO_DIR"
if [[ "$DRY_RUN" == 0 && "$PACKAGES" == 1 ]]; then install_platform_packages; fi
install_shared_configs
install_platform_configs
if [[ "$DRY_RUN" == 0 ]]; then
  if [[ "$SYNC" == 1 ]]; then sync_shared_dependencies; fi
  apply_platform_configs
  printf '\nConfigured %s. Edit tracked files here, then git add, commit, and push.\n' "$PLATFORM"
  [[ ! -d "$BACKUP_DIR" ]] || printf 'Previous files and restore manifest: %s\n' "$BACKUP_DIR"
else
  printf '\nDry run: no files changed and no software installed.\n'
fi
