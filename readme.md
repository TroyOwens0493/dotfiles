# Personal configs for Omarchy and macOS

One repository contains the preferences shared by both machines and their
platform-specific settings. The installer links the selected files into
`~/.config`, so editing an active config also edits its tracked source.

```text
shared/       Neovim, tmux, Pi, OpenCode, Git ignore, NuGet, Shopify,
              common Ghostty options, and launchers
omarchy/      Hyprland, shell/bar plugin, Linux Ghostty, mise, Arch packages
macos/        AeroSpace, cmux, Mac Ghostty, shell paths, Homebrew packages
scripts/      Platform installers, shared linking, and restoration
tests/        Installer preservation, isolation, and restoration checks
install.sh    Selects the platform and installs the appropriate profile
```

## Set up a machine

On an existing Omarchy installation or a Mac with Git available:

```sh
git clone https://github.com/TroyOwens0493/config_files.git ~/.config/config-files/repository
cd ~/.config/config-files/repository
bash install.sh --dry-run
bash install.sh
```

Run the installer as your normal user in a regular terminal. The package tools
request administrator access when needed. Platform selection is automatic; use
`--platform omarchy` or `--platform macos` to select it explicitly. Omarchy uses
its existing Lua Hyprland configuration and packaged defaults; this script does
not install the operating system.

The default installer installs the platform packages, links configs, installs the
pinned Pi runtime, tmux plugins, and Neovim plugins, and enables Git LFS.
Omarchy runtimes and development CLIs come from mise; macOS uses
[`macos/Brewfile`](macos/Brewfile). Erlang 28 is selected for erlang-ls compatibility.
Pi's runtime and SDK are pinned together to the working 0.87.1 version.

If the tools are already installed:

```sh
bash install.sh --skip-packages  # Link configs and install config dependencies.
bash install.sh --configs-only  # Only link configs and reload available apps.
```

`--dry-run` never installs packages or changes files. Repeated installs leave
correct links alone. Replaced files are saved beneath `~/.dotfiles-backup/`, with
the specific backup directory printed by the installer.

The checkout can live elsewhere, including an existing checkout at `~/.config`;
the installer always uses its own location. Keep it in place after installation
because the active configs link to it. A dedicated subdirectory makes the
checkout easier to distinguish from other applications' settings.

On a new Mac, open AeroSpace and grant Accessibility permission. Open Ghostty
and the installed applications as needed. Sign into AI clients and Linear MCP
separately on each machine; Pi uses `/login`. App permissions, account tokens,
GPG private keys, and sessions are local state.

## Edit and push changes

Edit the source in this repository or the linked path used by the application:

```sh
nvim ~/.config/nvim/lua/first/remap.lua
# The same file is shared/nvim/lua/first/remap.lua in this checkout.

cd ~/.config/config-files/repository
git status --short
git diff
git add shared/nvim/lua/first/remap.lua
git commit -m "Update Neovim keybindings"
git push origin main
```

Shared edits apply on both platforms after pulling. Put Linux-only edits under
`omarchy/` and Mac-only edits under `macos/`. For Ghostty, shared appearance
options belong in `shared/ghostty/common.conf`; platform font, integration, and
keybinding settings belong in the selected platform's `ghostty/config`.

On the other machine:

```sh
cd ~/.config/config-files/repository
git pull --ff-only
bash install.sh --skip-packages
```

The installer links new files and updates config dependencies when needed.
Rerun the default installer instead if the tracked package lists changed and
you want to install those packages. Reload the affected application after
editing: Hyprland uses `hyprctl reload` followed by `hyprctl configerrors`;
Ghostty uses its reload command, or `omarchy restart terminal` on Linux;
Neovim picks up configuration changes on restart.

GitHub pushing requires Git authentication on that machine. HTTPS clones work
with GitHub CLI authentication (`gh auth login`, then `gh auth setup-git`), or
you can change the origin to your configured SSH URL.

## Machine-specific settings and private state

Keep monitor settings in `~/.config/hypr/monitors.lua`; the installer preserves
that existing Omarchy file. Optional overrides in `~/.config/hypr/local.lua`
load after the tracked Hyprland settings. Optional `~/.config/ghostty/local.conf`
loads after shared and platform Ghostty options.

Pi keeps credentials, sessions, caches, and existing stock skills in
`~/.config/pi`. The installer links its tracked preferences and extensions
individually. Local npm dependencies remain excluded from Git. Existing Git
identity and signing preferences are preserved; only the global ignore path
is selected. Other unrelated app config files are left in place.

Compatibility links provide `~/.tmux.conf`, `~/.pi/agent`,
`~/.nuget/NuGet/NuGet.Config`, and, on macOS, `~/.aerospace.toml`.
The Pi and tmux-sessionizer launchers are linked into `~/.local/bin`.

The root `.gitignore` allows only the source directories shown above and the
installer, README, and tests. Local overrides, common credential files,
sessions, logs, and dependencies are excluded. Add another application's
preferences to the appropriate platform or shared directory, add its link to
the installer, and exclude any private or generated files before staging.
Review `git diff --cached` before committing. To inspect an exclusion:

```sh
git check-ignore -v --no-index path/to/file
```

## Restore an installation

Use the backup directory printed by that installation:

```sh
bash scripts/restore.sh ~/.dotfiles-backup/<installation-directory>
```

This restores previous files and removes links that were newly created by that
run. Replaced current files are saved in another recovery directory. Installed
packages and dependencies are retained. Reload the affected applications after
restoring. Each backup describes one run; restore the newest run first if
undoing several installations.

## Verify the installer

```sh
python3 -m unittest discover -s tests -v
```

The tests use temporary homes and checkouts, cover both platform profiles,
preserve credentials and machine settings, exercise repeated runs, and verify
restoration. Platform package installation still requires the actual operating
system and, where requested, administrator access.
