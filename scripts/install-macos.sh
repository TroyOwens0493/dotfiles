#!/usr/bin/env bash
# macOS packages and platform-specific configs.
install_platform_packages() {
  [[ "$(uname -s)" == Darwin ]] || { printf 'macOS packages require macOS.\n' >&2; return 1; }
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  brew bundle --file="$REPO_DIR/macos/Brewfile"
}

install_platform_configs() {
  link_tree "$REPO_DIR/macos/aerospace" "$CONFIG_DIR/aerospace"
  link_path "$CONFIG_DIR/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
  link_tree "$REPO_DIR/macos/cmux" "$CONFIG_DIR/cmux"
  link_path "$REPO_DIR/macos/ghostty/config" "$CONFIG_DIR/ghostty/config"
  link_path "$REPO_DIR/macos/shell/profile.sh" "$CONFIG_DIR/shell/macos-profile.sh"
  append_once '[[ ! -r "$HOME/.config/shell/macos-profile.sh" ]] || source "$HOME/.config/shell/macos-profile.sh"' "$HOME/.zprofile"
  if [[ "$DRY_RUN" == 0 && "$(uname -s)" == Darwin ]]; then
    source "$CONFIG_DIR/shell/macos-profile.sh"
  fi
}

apply_platform_configs() {
  # Ghostty loads these on startup; existing apps can use their reload command.
  printf 'Open AeroSpace and grant Accessibility permission if this is a new Mac.\n'
  printf 'Sign in to AI clients and Linear when needed.\n'
}
