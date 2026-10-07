# My Personal config files
## Many of these files are just the default configs, but Neovim, Aerospace, and iterm have been customized.

## Install

Clone this repository to `~/.config`, then run the installer:

```sh
git clone git@github.com-personal:TroyOwens0493/config_files.git ~/.config
~/.config/install.sh
```

The installer uses Homebrew to install Ghostty, Helium, AeroSpace, AI CLIs, and the dev tools used by these configs. It also links tmux and AeroSpace configs, installs tmux plugins, and backs up existing files before replacing them.

After the script finishes, open AeroSpace once and grant macOS Accessibility permissions. Sign into app and AI CLIs manually where needed.

## Omarchy Git sync

On this Mac, run `omarchy` to open the remote `nomp` tmux session. Use
`omarchy SESSION` for another session. Detach from tmux to return to the Mac
and sync committed changes. These aliases are in `~/.dotfiles/.zsh_aliases`.
Open a new terminal or run `source ~/.dotfiles/.zsh_aliases` after setup.

Run `omarchy-sync` for a manual sync, or `omarchy-sync --dry-run` to inspect
the proposed updates without fetching or changing checkouts.

`omarchy/settings.json` selects the SSH host, default session, and directories.
The SSH host `omarchy` is configured locally in `~/.ssh/config`; its private
key is not stored in this repository. Both machines need Git and Python 3.

The script matches checkouts under `~/ProgrammingDocs` and `~/dataThink` by
relative path. It fetches directly from Omarchy, then matches the checked-out
branch and commit. It also creates missing repositories and linked worktrees.
New `nomp` worktrees select and verify the Firebase staging project.

Checkouts with local file changes, conflicting branch history, an active Git
operation, or a detached remote HEAD are skipped and reported. Remote edits
that have not been committed are not copied. Local-only directories and
branches are retained. Dependencies and environment files are not copied.
The command returns status 1 if any checkout was skipped.

Automatic sync runs after a normal exit from the `omarchy` command. A plain
`ssh` connection does not start it. After a lost connection, run
`omarchy-sync` when Omarchy is reachable again. Processes can keep changing
remote files after you detach; the sync captures the committed state when
it starts.

Run the checks with `python3 -m unittest discover -s ~/.config/omarchy`.

## Tracking config files

The root `.gitignore` ignores all root-level entries by default with `/*`. Approved app directories, such as `!/nvim/`, include their files and subdirectories recursively. Installing a new app does not expose its configs or credentials to Git unless its directory is approved.

To approve another app, add one entry such as `!/new-app/` to `.gitignore`. New files inside an approved directory need no additional entries; add them normally with `git add`. Standalone root files need their own entry, such as `!/Brewfile`.

Shared exclusions keep common credentials, sessions, logs, backups, and dependencies local, with a few app-specific exclusions for generated state. Nested `.gitignore` files also apply. Approval covers the whole app directory, so credentials with other names inside an approved app need an exclusion before staging.

Use `git check-ignore -v --no-index path/to/file` to see which rule applies. Avoid `git add -f`, which bypasses ignore rules. To stop tracking an existing file, add an exclusion and run `git rm --cached -- path/to/file`; this keeps the local copy but does not remove earlier versions from Git history.
