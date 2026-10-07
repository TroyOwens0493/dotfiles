# Personal configs for Mac and Omarchy

One repo holds the shared application settings and the settings for each operating
system. `install.sh` detects the platform and links the selected files into their
normal locations. Keep new checkouts outside `~/.config`.

```text
shared/       Neovim, tmux, Pi, OpenCode, Git ignore, NuGet, Shopify,
              shared Ghostty appearance, and command launchers
macos/        AeroSpace, cmux, Ghostty, Zsh, Homebrew, and Omarchy project sync
omarchy/      Hyprland, workspace bar plugin, Ghostty, Bash, Starship,
              mise runtimes, and extra Arch packages
scripts/      Install helpers and backup restoration
tests/       Installer checks with temporary home folders
```

The shell files from the old `dotfiles` repo are included. That repo is no longer
required. The Omarchy settings were imported from the running Omarchy 4.0.4
machine, including its custom AeroSpace-style workspace controls and Bash prompt.
The installer requires an existing Omarchy installation with Lua Hyprland configs;
it does not install Linux or support older `.conf`-based Omarchy desktops.

## New Mac

Install Apple's command line tools if Git is not available. Then clone the repo
using HTTPS, or use your own configured SSH URL:

```sh
git clone https://github.com/TroyOwens0493/config_files.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run
./install.sh
```

The installer installs Homebrew when needed, installs `macos/Brewfile`, links the
shared and Mac settings, and installs Pi dependencies, tmux plugins, and Neovim
plugins. The Zsh config loads the included aliases, paths, and prompt. Homebrew
paths support both Apple Silicon and Intel Macs.

Open a new terminal after installation. Grant AeroSpace Accessibility permission.
Sign into your applications and AI tools. Configure Git identity, signing keys,
and SSH access on this machine. Existing Git identity and signing settings are
preserved. Secrets and permissions are not restored from this repo.

## New Omarchy machine

Install Omarchy first. Use the same clone and install commands shown above.
The installer selects `omarchy/` automatically, installs its extra packages and
mise tools, and links the shared and Linux configs. It keeps Omarchy's packaged
Hyprland and Bash defaults and loads your settings after them.

The package list covers this development setup. It is not a full backup of all
installed applications, drivers, services, or hardware settings.

Open a new terminal. When ready, reload the desktop:

```sh
hyprctl reload
hyprctl configerrors
```

Restart Ghostty and other applications to load their settings. The installer does
not restart your running desktop or terminal. Complete application sign-ins and
restore your SSH access separately.

Keep `~/.config/hypr/monitors.lua` on each machine. The installer does not replace
it. See `omarchy/hypr/AEROSPACE.md` for the shared workspace controls.

## Install options

```sh
./install.sh --dry-run         # Preview links; no files or packages change.
./install.sh --configs-only    # Link configs; no dependency downloads.
./install.sh --skip-packages   # Link configs and install config dependencies.
./install.sh --platform macos --dry-run
./install.sh --platform omarchy --dry-run
```

Run the installer as your normal user. Package commands request administrator
access when needed. Run the full installer when package lists change. The
installer does not pull, commit, or push this repo automatically.

It uses its own directory, so an existing checkout at `~/.config` still works.
For a new checkout, use `~/dotfiles`. Do not move a checkout without running its
installer again: the active configs use absolute links to it. These configs use
`~/.config`; a different `XDG_CONFIG_HOME` is rejected before installation.

## Edit and share settings

Edit a file in the repo, or edit the linked application file. Both paths refer to
the same settings. Put settings for both machines in `shared/`, Mac settings in
`macos/`, and Omarchy settings in `omarchy/`.

For example, `~/.config/nvim` links to `shared/nvim`. Pi's reviewed files are linked
into `~/.config/pi`, and `~/.pi/agent` provides its normal application path.
Credentials, sessions, and custom Pi extensions remain local. The `pi` command in
`~/.local/bin` uses the runtime from the Pi lockfile.

For Ghostty, edit shared appearance in `shared/ghostty/common.conf`. Edit platform
options in `macos/ghostty/config` or `omarchy/ghostty/config`.

Commit and push reviewed edits. On the other machine, pull the changes and run:

```sh
cd ~/dotfiles
git pull --ff-only
./install.sh --skip-packages
```

Use the actual checkout path if it differs. Existing links use updated files
immediately. Run the installer to add new links, then reload the affected apps.
A shared file has one owner; do not add a second platform config for the same
application path unless the application can include both files.

## Local files and backups

Use these optional files for private or machine-specific overrides:

- Mac shell: `~/.zshrc.local`
- Omarchy shell: `~/.bashrc.local`
- Omarchy desktop: `~/.config/hypr/local.lua`
- Ghostty: `~/.config/ghostty/local.conf`

Before replacing a config, the installer saves it under
`~/.dotfiles-backup/<installation-directory>/`. It prints the backup path.
Correct links are left alone when you run it again. Shell files are backed up
before replacement; move any additional private shell settings into the local
files above.

If both `~/.pi/agent` and `~/.config/pi` contain separate Pi installations, setup
stops before changing files. Combine their local state first. A single existing
Pi installation is preserved automatically.

To undo one config installation, use the backup path printed by that run:

```sh
bash scripts/restore.sh ~/.dotfiles-backup/<installation-directory>
```

Restore the newest run first. The script restores replaced files and removes new
links. It retains packages, dependencies, and local application data. Reload apps
after restoration. The replaced current files are also saved for recovery.

Only reviewed source folders are allowed by `.gitignore`. Credentials, sessions,
local overrides, dependencies, and backups are excluded. Add new source files
inside the appropriate group and update the install helper for their target paths.
Always review staged changes before committing.

## Mac-to-Omarchy project sync

The Mac shell includes these aliases:

```sh
omarchy                 # Connect to the remote nomp tmux session.
omarchy SESSION         # Connect to another remote session.
omarchy-sync            # Copy committed project changes to this Mac.
omarchy-sync --dry-run  # Inspect proposed changes without fetching.
```

Configure the `omarchy` SSH host in the Mac's `~/.ssh/config` and authorize its key
on the Linux machine. Both machines need Git and Python 3; Omarchy also needs tmux.
The installer does not configure SSH or open firewall ports.

Settings live in `macos/omarchy-sync/settings.json`. The script copies committed
Git state from `~/ProgrammingDocs` and `~/dataThink` on Omarchy to the same relative
paths on the Mac. Both remote root directories must exist. New `nomp` worktrees
also need the Firebase CLI and staging-project access on the Mac.

Sync runs after a normal detach from the `omarchy` command. It does not run after
plain SSH or a lost connection. Run `omarchy-sync` manually after reconnecting.
Local changes, conflicting history, active Git operations, and detached remote
checkouts are skipped. Uncommitted remote files, dependency folders, and private
environment files are not transferred. This is one-way project sync; use Git
push/pull to share this config repo.

## Checks

```sh
python3 -m unittest discover -s tests -v
python3 -m unittest discover -s macos/omarchy-sync -v
lua omarchy/tests/aerospace-layout.lua
```

Installer tests use temporary homes and checkouts. They check both platform
profiles, backups, restoration, local data, and repeated installs. Package
installation requires the actual operating system and is not run by these tests.
