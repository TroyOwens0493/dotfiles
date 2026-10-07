#!/usr/bin/env bash
# Shared linking helpers. Sourced by install.sh (compatible with macOS Bash 3.2).

# Record every changed target, including newly created links, for exact restoration.
record_target() {
  local target="$1" relative
  relative="${target#"$HOME/"}"
  [[ "$relative" != "$target" ]] || { printf 'Target is outside HOME: %s\n' "$target" >&2; return 1; }
  mkdir -p "$BACKUP_DIR/files/$(dirname "$relative")"
  printf '%s\n' "$relative" >> "$BACKUP_DIR/paths"
  if [[ -e "$target" || -L "$target" ]]; then
    mv "$target" "$BACKUP_DIR/files/$relative"
  fi
}

# Preserve content before moving a relative symlink away from its original base.
save_for_edit() {
  local target="$1" copy="$BACKUP_DIR/edit-copy"
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$target" ]]; then cp -pL "$target" "$copy"; fi
  record_target "$target"
  if [[ -f "$copy" ]]; then mv "$copy" "$target"; fi
}

# Link a reviewed config, saving the previous file and leaving correct links alone.
link_path() {
  local source="$1" target="$2"
  # Compatibility links can refer to targets that this dry run would create.
  if [[ ! -e "$source" ]]; then
    [[ "$DRY_RUN" == 1 && "$source" == "$CONFIG_DIR"/* ]] || { printf 'Missing source: %s\n' "$source" >&2; return 1; }
  fi
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then return; fi
  printf 'Link %s -> %s\n' "$target" "$source"
  [[ "$DRY_RUN" == 0 ]] || return 0
  record_target "$target"
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
}

# Link files recursively so untracked local settings and app state stay in place.
link_tree() {
  local source="$1" target="$2" entry
  for entry in "$source"/* "$source"/.[!.]*; do
    [[ -e "$entry" ]] || continue
    if [[ -d "$entry" ]]; then
      link_tree "$entry" "$target/$(basename "$entry")"
    else
      link_path "$entry" "$target/$(basename "$entry")"
    fi
  done
}

# Preserve shell customization while adding one stable, sourceable profile include.
append_once() {
  local line="$1" target="$2"
  if [[ -f "$target" ]] && LC_ALL=C awk -v text="$line" '$0 == text { found=1 } END { exit !found }' "$target"; then return; fi
  printf 'Add profile include to %s\n' "$target"
  [[ "$DRY_RUN" == 0 ]] || return 0
  save_for_edit "$target"
  printf '\n%s\n' "$line" >> "$target"
}

# Keep mutable Pi credentials, sessions, dependencies, and stock resources local.
install_shared_configs() {
  local name entry global_config
  link_path "$REPO_DIR/shared/nvim" "$CONFIG_DIR/nvim"
  link_path "$REPO_DIR/shared/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
  link_path "$CONFIG_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_path "$REPO_DIR/shared/git/ignore" "$CONFIG_DIR/git/ignore"
  link_path "$REPO_DIR/shared/ghostty/common.conf" "$CONFIG_DIR/ghostty/common.conf"
  link_tree "$REPO_DIR/shared/opencode" "$CONFIG_DIR/opencode"
  link_tree "$REPO_DIR/shared/NuGet" "$CONFIG_DIR/NuGet"
  link_path "$CONFIG_DIR/NuGet/NuGet.Config" "$HOME/.nuget/NuGet/NuGet.Config"
  link_tree "$REPO_DIR/shared/shopify" "$CONFIG_DIR/shopify"
  for name in AGENTS.md README.md SETUP.md .env.example settings.json models.json mcp.json package.json package-lock.json tsconfig.json; do
    link_path "$REPO_DIR/shared/pi/$name" "$CONFIG_DIR/pi/$name"
  done
  for name in extensions assets; do link_path "$REPO_DIR/shared/pi/$name" "$CONFIG_DIR/pi/$name"; done
  for entry in "$REPO_DIR/shared/pi/skills"/* "$REPO_DIR/shared/pi/themes"/*; do
    link_path "$entry" "$CONFIG_DIR/pi/${entry#"$REPO_DIR/shared/pi/"}"
  done
  if [[ "$DRY_RUN" == 0 ]]; then
    # Linked extensions resolve imports relative to their real checkout paths.
    # Expose local dependencies there without putting them under Git control.
    if [[ ! -e "$REPO_DIR/shared/pi/node_modules" && ! -L "$REPO_DIR/shared/pi/node_modules" ]]; then
      ln -s "$CONFIG_DIR/pi/node_modules" "$REPO_DIR/shared/pi/node_modules"
    elif [[ ! -L "$REPO_DIR/shared/pi/node_modules" || "$(readlink "$REPO_DIR/shared/pi/node_modules")" != "$CONFIG_DIR/pi/node_modules" ]]; then
      link_path "$REPO_DIR/shared/pi/node_modules" "$CONFIG_DIR/pi/node_modules"
    fi
  fi
  link_path "$CONFIG_DIR/pi" "$HOME/.pi/agent"
  for entry in "$REPO_DIR/shared/bin"/*; do link_path "$entry" "$HOME/.local/bin/$(basename "$entry")"; done
  if [[ "$DRY_RUN" == 0 ]]; then
    mkdir -p "$CONFIG_DIR/git"
    # Back up Git preferences before changing just the exclusions path.
    if [[ "$(git config --global --get core.excludesFile || true)" != "$CONFIG_DIR/git/ignore" ]]; then
      global_config="${GIT_CONFIG_GLOBAL:-$HOME/.gitconfig}"
      if [[ -z "${GIT_CONFIG_GLOBAL:-}" && ! -f "$HOME/.gitconfig" && -f "$CONFIG_DIR/git/config" ]]; then
        global_config="$CONFIG_DIR/git/config"
      fi
      save_for_edit "$global_config"
      git config --global core.excludesFile "$CONFIG_DIR/git/ignore"
    fi
  fi
}

# Download only config dependencies; the pinned Pi CLI is supplied by its lockfile.
sync_shared_dependencies() {
  local label
  command -v npm >/dev/null || { printf 'npm is required. Install packages or use --configs-only.\n' >&2; return 1; }
  if [[ ! -f "$CONFIG_DIR/pi/.dotfiles-package-lock" ]] || ! cmp -s "$REPO_DIR/shared/pi/package-lock.json" "$CONFIG_DIR/pi/.dotfiles-package-lock"; then
    npm ci --prefix "$CONFIG_DIR/pi" --no-audit --no-fund
    cp "$REPO_DIR/shared/pi/package-lock.json" "$CONFIG_DIR/pi/.dotfiles-package-lock"
  fi
  if command -v tmux >/dev/null; then
    if [[ ! -d "$CONFIG_DIR/tmux/plugins/tpm/.git" ]]; then
      git clone https://github.com/tmux-plugins/tpm.git "$CONFIG_DIR/tmux/plugins/tpm"
    fi
    # TPM uses TMUX to locate its server. Keep setup separate from active sessions.
    label="dotfiles-installer-$$"
    (
      trap 'tmux -L "$label" kill-server 2>/dev/null || true' EXIT
      tmux -L "$label" -f "$CONFIG_DIR/tmux/tmux.conf" new-session -d -s setup
      export TMUX
      TMUX="$(tmux -L "$label" display-message -p '#{socket_path},#{pid},0')"
      "$CONFIG_DIR/tmux/plugins/tpm/bin/install_plugins"
    )
  fi
  if command -v git-lfs >/dev/null; then git lfs install; fi
  if command -v nvim >/dev/null; then nvim --headless '+Lazy! restore' +qa; fi
}
