# Install the dotfiles with an agent

Follow this guide when the user asks you to install or update these dotfiles.
Do the work on the target machine. Do not only print a list of commands.
Use the files in this checkout as the source for packages and settings.
Apply the steps directly. This guide is the installation procedure; there is no
install script. It uses `scripts/restore-nvim.lua` to restore pinned Neovim plugins
and `scripts/restore.sh` to undo config changes from a backup.

## 1. Check the machine and the requested scope

- Use the normal user account. Use administrator access only for package commands
  that need it.
- Use the actual, absolute checkout path as `REPO_DIR`. Use `~/.config` as
  `CONFIG_DIR`. If `XDG_CONFIG_HOME` points elsewhere, stop and report the conflict.
- Check `git status --short`. Preserve all existing edits. Do not pull, reset,
  commit, or push unless the user asks for that operation.
- On macOS, use `shared/` and `macos/`.
- On Linux, use `shared/` and `omarchy/` only if Omarchy is installed and
  `/usr/share/omarchy/default/hypr/bootstrap.lua` exists. This repo requires the
  Lua Hyprland config format. Do not install a desktop or convert another Linux
  system to Omarchy as part of this guide.
- For a new checkout, use `~/dotfiles`, outside `~/.config`. Keep the checkout at
  that path after setup because the config links use absolute paths.

Use the scope requested by the user:

| Scope | Work to do |
| --- | --- |
| Full setup (default) | Install packages, link configs, install config dependencies, and check the result. |
| Configs only | Link configs and check links. Do not install packages or download dependencies. |
| Skip packages | Link configs and install config dependencies with the tools already installed. |
| Preview / dry run | Inspect the machine and report planned changes. Do not create backups, links, files, or downloads. |

Check Pi state before any change. If `~/.pi/agent` and `~/.config/pi` are both
directories and refer to different directories, stop. Report that their local
state must be combined first. Do not choose one and hide the other.

## 2. Preserve existing files

Before each change, inspect the destination. Leave a link alone if it already
points to the correct source. Do not use `ln -sf` over an existing config.

For this run, use one backup directory under
`~/.dotfiles-backup/<date>-<unique-suffix>/`. Create it only when needed.
Keep it compatible with `scripts/restore.sh`:

- Append each changed destination to `paths`, as a path relative to the user's
  home directory, once and before its first change.
- Move each existing file, directory, or link to `files/<relative-path>` inside
  that backup directory. Record new destinations too, but leave their backup
  file absent. This lets restoration remove a newly created link.
- If an ancestor directory is a link to another checkout, first copy its contents
  to a real local directory. Preserve nested links. Back up the ancestor link,
  record it before its children, then put the local copy in its place. Do not
  write through the ancestor link into the other checkout.
- For files that need an edit, such as `.zprofile` or the global Git config,
  copy their resolved contents before you move the old path. Edit the local copy.
  This also preserves contents when the old path was a relative link.

Keep credentials, sessions, SSH files, Git identity, monitor settings, private
extensions, and local overrides. Do not copy their contents into the repo or
print secret values. The optional local override paths are listed in
[readme.md](readme.md#local-files-and-backups).

## 3. Install platform packages

Skip this section for configs-only, skip-packages, and preview requests.

### macOS

1. Check that Apple's command line tools and Git are available. If the tools are
   missing, start `xcode-select --install` and report any user action needed.
2. Install Homebrew if needed with its official installer. Load its environment
   from `/opt/homebrew/bin/brew shellenv` on Apple Silicon or
   `/usr/local/bin/brew shellenv` on Intel.
3. If Ghostty, Helium, or cmux already exists in `/Applications` but is not
   managed by Homebrew, use `brew install --cask --adopt` with `ghostty`,
   `helium-browser`, or `cmux`, as applicable.
4. If `brew list --formula opencode` succeeds, remove that old formula with
   `brew uninstall opencode`. The Brewfile installs OpenCode 2, which supplies
   the same command.
5. Run `brew bundle --file="$REPO_DIR/macos/Brewfile"`.

Use the Brewfile as the package list. Do not maintain another copy in this guide.

### Omarchy

1. On a new machine, run `omarchy update -y` before adding packages. The offline
   ISO needs the online package databases.
2. Read `omarchy/packages.txt`. Ignore empty lines and comment lines. Pass the
   remaining package names to `omarchy pkg add`.
3. Check that `mise` is available. Trust the repo config and install its tools
   before replacing the user's global config link:

   ```sh
   mise trust "$REPO_DIR/omarchy/mise/config.toml"
   (cd "$HOME" && MISE_GLOBAL_CONFIG_FILE="$REPO_DIR/omarchy/mise/config.toml" mise install)
   export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
   ```

Do not replace the user's other mise settings just to install the tools.

## 4. Link shared configs

Create absolute symbolic links with the backup rules above. Paths in the source
column are relative to `REPO_DIR`, unless they start with `~`.

| Source | Destination |
| --- | --- |
| `shared/nvim` | `~/.config/nvim` (whole directory) |
| `shared/shell/colors.sh` | `~/.config/shell/colors.sh` |
| `shared/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `shared/tmux/colors.sh` | `~/.config/tmux/colors.sh` |
| `~/.config/tmux/tmux.conf` | `~/.tmux.conf` |
| `shared/git/ignore` | `~/.config/git/ignore` |
| `shared/ghostty/common.conf` | `~/.config/ghostty/common.conf` |
| Files under `shared/opencode/` | Matching paths under `~/.config/opencode/` |
| Files under `shared/NuGet/` | Matching paths under `~/.config/NuGet/` |
| `~/.config/NuGet/NuGet.Config` | `~/.nuget/NuGet/NuGet.Config` |
| Files under `shared/shopify/` | Matching paths under `~/.config/shopify/` |
| Each launcher in `shared/bin/` | Same name under `~/.local/bin/` |

For a file tree, create real destination directories and link its reviewed files
one by one. Include reviewed hidden files. Keep unrelated destination files.
Exclude `.git`, `.gitignore`, `node_modules`, `__pycache__`, `sessions`,
`auth.json`, `credentials.json`, `trust.json`, `.env`, `.env.*`, logs, and backups.
Only use reviewed repo sources; do not install local generated files.

Set only the global Git exclusion path:

```sh
git config --global core.excludesFile "$HOME/.config/git/ignore"
```

Back up the effective global config first if this value needs to change. Respect
`GIT_CONFIG_GLOBAL` when set; otherwise check `~/.gitconfig` and
`~/.config/git/config`. Preserve all other Git settings.

### Pi

Keep `~/.config/pi` as a real directory for local state. If only `~/.pi/agent`
exists, copy its contents, including hidden files, into `~/.config/pi` before
replacing its old path with a link. Preserve credentials and sessions.

Link these files from `shared/pi/` into `~/.config/pi/`:

```text
AGENTS.md  README.md  SETUP.md  .env.example  settings.json  models.json
mcp.json  package.json  package-lock.json  tsconfig.json
```

Also link reviewed files under `shared/pi/extensions/` one by one. Link
`shared/pi/assets` as a directory. Link each immediate entry in
`shared/pi/skills/` and `shared/pi/themes/` to its matching destination. Keep
stock resources and private extensions that have other names.

Set up dependency access for the linked extensions:

- If `shared/pi/node_modules` is absent, link that repo path to
  `~/.config/pi/node_modules`. Keep the link untracked.
- If it already links to that local dependency directory, leave it alone.
- If it is an existing dependency directory, preserve it and link
  `~/.config/pi/node_modules` to it, with the normal destination backup rules.
  For another layout, inspect and resolve it without losing local data or
  creating a link cycle.

Finally, link `~/.pi/agent` to `~/.config/pi`, unless both paths already refer to
the same directory.

## 5. Link configs for the selected platform

Use the same file-tree and backup rules as in section 4.

### macOS

| Source | Destination |
| --- | --- |
| Files under `macos/aerospace/` | Matching paths under `~/.config/aerospace/` |
| Files under `macos/cmux/` | Matching paths under `~/.config/cmux/` |
| `macos/ghostty/config` | `~/.config/ghostty/config` |
| `macos/zsh/.zshrc` | `~/.zshrc` |
| Files under `macos/omarchy-sync/` | Matching paths under `~/.config/omarchy-sync/` |
| `macos/shell/profile.sh` | `~/.config/shell/macos-profile.sh` |

Back up and retire `~/.aerospace.toml` and
`~/.config/ghostty/config.ghostty` if present, including broken links. They
conflict with the selected config paths.

Preserve `~/.zprofile`. Append this exact line once if it is absent:

```sh
[[ ! -r "$HOME/.config/shell/macos-profile.sh" ]] || source "$HOME/.config/shell/macos-profile.sh"
```

### Omarchy

| Source | Destination |
| --- | --- |
| Files under `omarchy/bash/` | Matching paths under `~/.config/shell/omarchy/`, including hidden files |
| `omarchy/bash/.bashrc` | `~/.bashrc` |
| `omarchy/starship.toml` | `~/.config/starship.toml` |
| Files under `omarchy/hypr/` | Matching paths under `~/.config/hypr/` |
| Files under `omarchy/omarchy/` | Matching paths under `~/.config/omarchy/` |
| `omarchy/ghostty/config` | `~/.config/ghostty/config` |
| `omarchy/mise/config.toml` | `~/.config/mise/config.toml` |

Back up and retire `~/.config/ghostty/config.ghostty` if present.
Keep the machine's `monitors.lua` and `local.lua`. Keep Omarchy's packaged
defaults under `/usr/share/omarchy`; the repo configs load those defaults.

## 6. Install config dependencies

Skip this section for configs-only and preview requests. Report missing required
tools if packages were skipped. Do not silently mark an incomplete setup as done.

### Pi runtime

Use npm and the checked-in lockfile. Run the following if the local Pi executable
is missing, or if the saved lock marker is absent or differs from the repo lock:

```sh
npm ci --prefix "$HOME/.config/pi" --no-audit --no-fund
cp "$REPO_DIR/shared/pi/package-lock.json" "$HOME/.config/pi/.dotfiles-package-lock"
```

Check `~/.config/pi/node_modules/.bin/pi` and compare the marker with
`shared/pi/package-lock.json`. Copy the marker only after npm succeeds.
Do not install a different global Pi version.

### tmux and Git LFS

Clone `https://github.com/tmux-plugins/tpm.git` to
`~/.config/tmux/plugins/tpm` if it is not already a Git checkout.
Run TPM with a separate tmux server so existing sessions stay active:

```sh
(
  set -e
  label="dotfiles-setup-$$"
  trap 'tmux -L "$label" kill-server 2>/dev/null || true' EXIT
  tmux -L "$label" -f "$HOME/.config/tmux/tmux.conf" new-session -d -s setup
  export TMUX
  TMUX="$(tmux -L "$label" display-message -p '#{socket_path},#{pid},0')"
  "$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
)
git lfs install
```

### Neovim

Restore the commits in `shared/nvim/lazy-lock.json`. Do not use a plugin update
command or let startup replace the input pins. Use the retained Lua restore
helper with a snapshot and a disposable working lock:

```sh
(
  set -e
  staging=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-nvim-lock.XXXXXX")
  trap 'rm -rf "$staging"' EXIT
  cp "$REPO_DIR/shared/nvim/lazy-lock.json" "$staging/input.json"
  cp "$staging/input.json" "$staging/working.json"
  DOTFILES_NVIM_LOCK_SNAPSHOT="$staging/input.json" \
    DOTFILES_NVIM_LOCKFILE="$staging/working.json" \
    DOTFILES_NVIM_RESTORE_SCRIPT="$REPO_DIR/scripts/restore-nvim.lua" \
    nvim --headless '+lua local ok, err = pcall(dofile, vim.env.DOTFILES_NVIM_RESTORE_SCRIPT); if not ok then vim.api.nvim_err_writeln(err); vim.cmd("cquit 1") end' +qa
)
```

The helper fetches missing pinned commits from shallow caches and checks the
installed commits. If it fails, report the failure and keep the tracked lockfile.

### Omarchy System Pulse widget

On Omarchy only, if
`~/.config/omarchy/plugins/lucas.system-pulse/manifest.json` is absent, run:

```sh
omarchy plugin add https://github.com/lucaslus/omarchy-statusline.git --yes
```

Then run:

```sh
omarchy plugin validate "$HOME/.config/omarchy/plugins/lucas.system-pulse"
```

Do not pass `--enable`. The tracked `shell.json` already places and enables the
widget. That option would change the tracked settings through their link.

## 7. Check the result and report

- Check that the selected links resolve to this checkout and that no required
  link is broken. Do not install the other platform's settings.
- Check that local state and override files are still available. Do not print
  credential contents.
- For dependency setup, check `pi --version`, `tmux -V`, `nvim --version`, and
  `git lfs version`. Check that Neovim restoration and plugin validation passed.
  Use `~/.local/bin/pi` if the current shell does not yet include that path.
- Check `git status --short` again. Setup must not change tracked source files
  or overwrite the user's existing edits.
- Report what was installed, the backup path, failures, and remaining user steps.
  Do not restart the desktop, terminal, or active sessions without a request.

On macOS, tell the user to open a new terminal and grant AeroSpace Accessibility
permission if needed. Git identity, SSH access, and app sign-ins require local
setup. For remote sessions, configure the `omarchy` SSH host and follow the
[project sync instructions](readme.md#mac-to-omarchy-project-sync), including the
`ssh-auto-forward` tool.

On Omarchy, tell the user to open a new terminal and restart apps as needed.
When the user is ready to reload the desktop, use `hyprctl reload`, then
`hyprctl configerrors`. Keep monitor settings local.

To undo config changes, use the backup path from this run:

```sh
bash "$REPO_DIR/scripts/restore.sh" "$BACKUP_DIR"
```

Restore the newest run first. This restores configs; it keeps installed packages
and dependencies. The restore script saves replaced current files for recovery.
