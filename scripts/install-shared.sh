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

# Replace a parent-directory link with a copy before editing its children. This
# preserves local state without writing into a different dotfiles checkout.
prepare_directory() {
  local directory="$1" copy
  [[ "$directory" != "$HOME" ]] || return 0
  case "$directory" in "$HOME"/*) ;; *) printf 'Directory is outside HOME: %s\n' "$directory" >&2; return 1 ;; esac
  prepare_directory "$(dirname "$directory")"
  if [[ -L "$directory" ]]; then
    printf 'Preserve linked directory as local files: %s\n' "$directory"
    [[ "$DRY_RUN" == 0 ]] || return 0
    copy="$BACKUP_DIR/directory-copy"
    mkdir -p "$copy"
    if [[ -d "$directory" ]]; then cp -RPp "$directory/." "$copy/"; fi
    record_target "$directory"
    mv "$copy" "$directory"
  elif [[ -e "$directory" && ! -d "$directory" ]]; then
    printf 'Expected a directory: %s\n' "$directory" >&2
    return 1
  elif [[ "$DRY_RUN" == 0 ]]; then
    mkdir -p "$directory"
  fi
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
  prepare_directory "$(dirname "$target")"
  record_target "$target"
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
}

# Retire an obsolete filename without losing the previous config.
retire_path() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  printf 'Back up obsolete config: %s\n' "$target"
  [[ "$DRY_RUN" == 0 ]] || return 0
  prepare_directory "$(dirname "$target")"
  record_target "$target"
}

# Link files recursively so untracked local settings and app state stay in place.
link_tree() {
  local source="$1" target="$2" entry
  for entry in "$source"/* "$source"/.[!.]*; do
    [[ -e "$entry" ]] || continue
    case "$(basename "$entry")" in
      .git|.gitignore|node_modules|__pycache__|sessions|auth.json|credentials.json|trust.json|.env|.env.*|*.log|*.bak.*|*.backup.*) continue ;;
    esac
    if [[ -d "$entry" ]]; then
      link_tree "$entry" "$target/$(basename "$entry")"
    else
      link_path "$entry" "$target/$(basename "$entry")"
    fi
  done
}

# Do not hide credentials from an existing Pi installation behind a new link.
check_pi_directory() {
  if [[ -d "$HOME/.pi/agent" && -d "$CONFIG_DIR/pi" && ! "$HOME/.pi/agent" -ef "$CONFIG_DIR/pi" ]]; then
    printf 'Two Pi data directories exist: ~/.pi/agent and ~/.config/pi. Combine their local state before installing. No files were changed.\n' >&2
    return 1
  fi
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
  if [[ -d "$HOME/.pi/agent" && ! -e "$CONFIG_DIR/pi" ]]; then
    printf 'Preserve existing Pi state in %s/pi\n' "$CONFIG_DIR"
    if [[ "$DRY_RUN" == 0 ]]; then
      prepare_directory "$CONFIG_DIR/pi"
      cp -RPp "$HOME/.pi/agent/." "$CONFIG_DIR/pi/"
    fi
  fi
  link_path "$REPO_DIR/shared/nvim" "$CONFIG_DIR/nvim"
  link_path "$REPO_DIR/shared/shell/colors.sh" "$CONFIG_DIR/shell/colors.sh"
  link_path "$REPO_DIR/shared/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
  link_path "$REPO_DIR/shared/tmux/colors.sh" "$CONFIG_DIR/tmux/colors.sh"
  link_path "$CONFIG_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_path "$REPO_DIR/shared/git/ignore" "$CONFIG_DIR/git/ignore"
  link_path "$REPO_DIR/shared/ghostty/common.conf" "$CONFIG_DIR/ghostty/common.conf"
  prepare_directory "$CONFIG_DIR/pi"
  link_tree "$REPO_DIR/shared/opencode" "$CONFIG_DIR/opencode"
  link_tree "$REPO_DIR/shared/NuGet" "$CONFIG_DIR/NuGet"
  link_path "$CONFIG_DIR/NuGet/NuGet.Config" "$HOME/.nuget/NuGet/NuGet.Config"
  link_tree "$REPO_DIR/shared/shopify" "$CONFIG_DIR/shopify"
  for name in AGENTS.md README.md SETUP.md .env.example settings.json models.json mcp.json package.json package-lock.json tsconfig.json; do
    link_path "$REPO_DIR/shared/pi/$name" "$CONFIG_DIR/pi/$name"
  done
  link_tree "$REPO_DIR/shared/pi/extensions" "$CONFIG_DIR/pi/extensions"
  link_path "$REPO_DIR/shared/pi/assets" "$CONFIG_DIR/pi/assets"
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
  if [[ ! "$CONFIG_DIR/pi" -ef "$HOME/.pi/agent" ]]; then
    link_path "$CONFIG_DIR/pi" "$HOME/.pi/agent"
  fi
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
  if [[ ! -x "$CONFIG_DIR/pi/node_modules/.bin/pi" || ! -f "$CONFIG_DIR/pi/.dotfiles-package-lock" ]] || ! cmp -s "$REPO_DIR/shared/pi/package-lock.json" "$CONFIG_DIR/pi/.dotfiles-package-lock"; then
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
