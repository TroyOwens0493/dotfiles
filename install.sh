#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO="git@github.com-personal:TroyOwens0493/config_files.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"
BREWFILE="$DOTFILES_DIR/Brewfile"

log() {
  printf '\n==> %s\n' "$1"
}

warn() {
  printf '\nWarning: %s\n' "$1" >&2
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This installer only supports macOS.\n' >&2
    exit 1
  fi
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return
  fi

  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew installed, but brew was not found in an expected location.\n' >&2
    exit 1
  fi
}

ensure_dotfiles_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Updating dotfiles repository"
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not fast-forward dotfiles. Continuing with local files."
    return
  fi

  if [[ -e "$DOTFILES_DIR" ]]; then
    warn "$DOTFILES_DIR exists but is not a Git repository. Leaving it untouched."
    return
  fi

  log "Cloning dotfiles repository"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

install_brew_bundle() {
  if [[ ! -f "$BREWFILE" ]]; then
    printf 'Brewfile not found at %s\n' "$BREWFILE" >&2
    exit 1
  fi

  log "Installing apps, AI CLIs, and dev tools"
  brew bundle --file="$BREWFILE"
}

adopt_cask_app() {
  local cask="$1"
  local app="$2"

  if brew list --cask "$cask" >/dev/null 2>&1; then
    return
  fi

  if [[ -d "/Applications/$app" ]]; then
    log "Adopting existing $app into Homebrew cask $cask"
    brew install --cask --adopt "$cask" || warn "Could not adopt $app. brew bundle may ask you to remove or reinstall it."
  fi
}

adopt_existing_apps() {
  adopt_cask_app "iterm2" "iTerm.app"
  adopt_cask_app "helium-browser" "Helium.app"
}

backup_path() {
  local path="$1"

  mkdir -p "$BACKUP_DIR"
  mv "$path" "$BACKUP_DIR/$(basename "$path")"
  printf 'Backed up %s to %s\n' "$path" "$BACKUP_DIR"
}

link_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    warn "Skipping missing source: $source"
    return
  fi

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_path "$target"
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

append_once() {
  local line="$1"
  local file="$2"

  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '%s\n' "$line" >>"$file"
  fi
}

configure_shell() {
  log "Configuring shell paths"

  append_once 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
  append_once 'export PATH="$HOME/flutter/bin:$PATH"' "$HOME/.zprofile"
  append_once 'export PATH="$HOME/.gem/bin:$PATH"' "$HOME/.zprofile"
}

link_dotfiles() {
  log "Linking dotfiles"

  link_path "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_path "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.aerospace.toml"

  if [[ -f "$HOME/.gitconfig" ]]; then
    warn "Leaving existing ~/.gitconfig in place because it contains identity and signing settings."
  fi
}

install_tmux_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  log "Installing tmux plugin manager and plugins"
  if [[ ! -d "$tpm_dir/.git" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  "$tpm_dir/bin/install_plugins" || warn "tmux plugin install failed. Open tmux and press prefix + I to retry."
}

install_git_lfs() {
  log "Configuring Git LFS"
  git lfs install || warn "Git LFS setup failed."
}

install_opencode_dependencies() {
  local opencode_dir="$DOTFILES_DIR/opencode"

  if [[ ! -f "$opencode_dir/package.json" ]]; then
    return
  fi

  log "Installing OpenCode config dependencies"
  if [[ -f "$opencode_dir/package-lock.json" ]]; then
    npm ci --prefix "$opencode_dir" || warn "OpenCode npm dependency install failed."
  else
    npm install --prefix "$opencode_dir" || warn "OpenCode npm dependency install failed."
  fi
}

install_neovim_plugins() {
  if [[ ! -f "$DOTFILES_DIR/nvim/init.lua" ]]; then
    return
  fi

  log "Syncing Neovim plugins"
  nvim --headless "+Lazy! sync" +qa || warn "Neovim plugin sync failed. Open nvim once to retry."
}

print_next_steps() {
  log "Setup complete"
  printf '%s\n' "Manual steps that macOS may still require:"
  printf '%s\n' "- Open AeroSpace once and grant Accessibility permissions."
  printf '%s\n' "- Sign into GitHub/AI CLIs as needed: gh, opencode, codex, claude, gemini, pi."
  printf '%s\n' "- Import or configure your GPG private key before relying on signed commits."
  printf '%s\n' "- Open iTerm2 and Helium once so macOS finishes first-launch setup."
}

main() {
  ensure_macos
  install_homebrew
  ensure_dotfiles_repo
  adopt_existing_apps
  install_brew_bundle
  configure_shell
  link_dotfiles
  install_tmux_plugins
  install_git_lfs
  install_opencode_dependencies
  install_neovim_plugins
  print_next_steps
}

main "$@"
