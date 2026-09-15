# My Personal config files
## Many of these files are just the default configs, but Neovim, Aerospace, and iterm have been customized.

## Install

Clone this repository to `~/.config`, then run the installer:

```sh
git clone git@github.com-personal:TroyOwens0493/config_files.git ~/.config
~/.config/install.sh
```

The installer uses Homebrew to install iTerm2, Helium, AeroSpace, AI CLIs, and the dev tools used by these configs. It also links tmux and AeroSpace configs, installs tmux plugins, and backs up existing files before replacing them.

After the script finishes, open AeroSpace once and grant macOS Accessibility permissions. Sign into app and AI CLIs manually where needed.

## Tracking config files

The root `.gitignore` ignores all root-level entries by default with `/*`. Approved app directories, such as `!/nvim/`, include their files and subdirectories recursively. Installing a new app does not expose its configs or credentials to Git unless its directory is approved.

To approve another app, add one entry such as `!/new-app/` to `.gitignore`. New files inside an approved directory need no additional entries; add them normally with `git add`. Standalone root files need their own entry, such as `!/Brewfile`.

Shared exclusions keep common credentials, sessions, logs, backups, and dependencies local, with a few app-specific exclusions for generated state. Nested `.gitignore` files also apply. Approval covers the whole app directory, so credentials with other names inside an approved app need an exclusion before staging.

Use `git check-ignore -v --no-index path/to/file` to see which rule applies. Avoid `git add -f`, which bypasses ignore rules. To stop tracking an existing file, add an exclusion and run `git rm --cached -- path/to/file`; this keeps the local copy but does not remove earlier versions from Git history.
