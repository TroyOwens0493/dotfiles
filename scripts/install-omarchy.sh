#!/usr/bin/env bash
# Apply user overrides while continuing to load Omarchy's packaged defaults.
install_platform_packages() {
  command -v omarchy >/dev/null || { printf 'Install Omarchy first.\n' >&2; return 1; }
  local packages=() name
  while IFS= read -r name; do
    [[ -z "$name" || "$name" == \#* ]] || packages+=("$name")
  done < "$REPO_DIR/omarchy/packages.txt"
  omarchy pkg add "${packages[@]}"
  command -v mise >/dev/null || { printf 'Omarchy must provide mise.\n' >&2; return 1; }
  # Install without rewriting a user's other global mise settings.
  mise trust "$REPO_DIR/omarchy/mise/config.toml"
  (cd "$HOME" && MISE_GLOBAL_CONFIG_FILE="$REPO_DIR/omarchy/mise/config.toml" mise install)
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
}

install_platform_configs() {
  link_tree "$REPO_DIR/omarchy/bash" "$CONFIG_DIR/shell/omarchy"
  link_path "$REPO_DIR/omarchy/bash/.bashrc" "$HOME/.bashrc"
  link_path "$REPO_DIR/omarchy/starship.toml" "$CONFIG_DIR/starship.toml"
  link_tree "$REPO_DIR/omarchy/hypr" "$CONFIG_DIR/hypr"
  link_tree "$REPO_DIR/omarchy/omarchy" "$CONFIG_DIR/omarchy"
  link_path "$REPO_DIR/omarchy/ghostty/config" "$CONFIG_DIR/ghostty/config"
  retire_path "$CONFIG_DIR/ghostty/config.ghostty"
  link_path "$REPO_DIR/omarchy/mise/config.toml" "$CONFIG_DIR/mise/config.toml"
}

print_platform_next_steps() {
  printf 'Reload Hyprland when ready: hyprctl reload; hyprctl configerrors\n'
  printf 'Restart Ghostty and other apps to load their settings.\n'
  printf 'Keep monitor settings in ~/.config/hypr/monitors.lua.\n'
  printf 'Sign in to AI clients and configure Git identity and SSH access.\n'
}
