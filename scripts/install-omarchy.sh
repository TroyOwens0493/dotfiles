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
  MISE_CONFIG_FILE="$REPO_DIR/omarchy/mise/config.toml" mise install
}

install_platform_configs() {
  link_tree "$REPO_DIR/omarchy/hypr" "$CONFIG_DIR/hypr"
  link_tree "$REPO_DIR/omarchy/omarchy" "$CONFIG_DIR/omarchy"
  link_path "$REPO_DIR/omarchy/ghostty/config" "$CONFIG_DIR/ghostty/config"
  link_path "$REPO_DIR/omarchy/mise/config.toml" "$CONFIG_DIR/mise/config.toml"
}

apply_platform_configs() {
  if command -v hyprctl >/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload
    local errors
    errors="$(hyprctl configerrors)"
    [[ -z "${errors//[[:space:]]/}" ]] || { printf '%s\n' "$errors" >&2; return 1; }
    omarchy restart terminal
    if command -v ghostty >/dev/null; then
      ghostty +validate-config
      omarchy default terminal ghostty
    fi
  fi
}
