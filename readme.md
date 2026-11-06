# Dotfiles for Mac and Omarchy

My opinionated config files for me mac and Omarchy machines, updated regularly. Meant to be easy to get a new machine running quickly.

## Install

Clone the repo into your home directory:

```sh
git clone https://github.com/TroyOwens0493/dotfiles.git ~/dotfiles
```

Then point your agent at [install.md](install.md) and ask:

> Read ~/dotfiles/install.md and install these dotfiles on this machine.

## Files and links

```text
shared/    Application configs used on both platforms
macos/     Mac configs and Homebrew packages
omarchy/   Omarchy configs and extra packages
```

Setup links configs from this repo into their application paths, mostly under
`~/.config`. For example, `~/.config/nvim` links to `~/dotfiles/shared/nvim`.
Editing either path changes the same file. Credentials and app data stay local.

Keep the repo at `~/dotfiles` so the links continue to work.

## Custom skills

Edit custom skills here; their application paths link to these directories:

- [PR checklist](shared/codex/skills/pr-checklist/SKILL.md): `~/.codex/skills/pr-checklist`
- [Code review](shared/agents/skills/code-review/SKILL.md): `~/.agents/skills/code-review`, also linked from Codex, Claude, and OpenCode
- [Pi skills](shared/pi/skills): `~/.config/pi/skills/`

Create new custom skills in the matching repo directory, then link each skill to
its application path. See [install.md](install.md#custom-skills) for the link rules.
Package-managed, plugin, and system skills stay outside this repo.
