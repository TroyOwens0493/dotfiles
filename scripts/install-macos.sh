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
  local spec cask app
  for spec in 'ghostty:Ghostty.app' 'helium-browser:Helium.app' 'cmux:cmux.app'; do
    cask="${spec%%:*}"; app="${spec#*:}"
    if [[ -d "/Applications/$app" ]] && ! brew list --cask "$cask" >/dev/null 2>&1; then
      brew install --cask --adopt "$cask"
    fi
  done
  brew bundle --file="$REPO_DIR/macos/Brewfile"
}

install_platform_configs() {
  link_tree "$REPO_DIR/macos/aerospace" "$CONFIG_DIR/aerospace"
  link_path "$CONFIG_DIR/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
  link_tree "$REPO_DIR/macos/cmux" "$CONFIG_DIR/cmux"
  link_path "$REPO_DIR/macos/ghostty/config" "$CONFIG_DIR/ghostty/config"
  # Ghostty reads both names; keeping both would include common.conf twice.
  retire_path "$CONFIG_DIR/ghostty/config.ghostty"
  link_path "$REPO_DIR/macos/zsh/.zshrc" "$HOME/.zshrc"
  link_tree "$REPO_DIR/macos/omarchy-sync" "$CONFIG_DIR/omarchy-sync"
  link_path "$REPO_DIR/macos/shell/profile.sh" "$CONFIG_DIR/shell/macos-profile.sh"
  append_once '[[ ! -r "$HOME/.config/shell/macos-profile.sh" ]] || source "$HOME/.config/shell/macos-profile.sh"' "$HOME/.zprofile"
}

print_platform_next_steps() {
  # Ghostty loads these on startup; existing apps can use their reload command.
  printf 'Open AeroSpace and grant Accessibility permission if this is a new Mac.\n'
  printf 'Sign in to AI clients and Linear when needed.\n'
  printf 'Open a new terminal to load the merged shell settings.\n'
  printf 'Configure the SSH host omarchy before using the remote-session aliases.\n'
}
