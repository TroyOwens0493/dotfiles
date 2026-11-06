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

Edit portable custom skills in [shared/agents/skills](shared/agents/skills):

- [PR checklist](shared/agents/skills/pr-checklist/SKILL.md)
- [Code review](shared/agents/skills/code-review/SKILL.md)

Each skill has links in the user skills directories for Codex, Claude Code,
OpenCode, Pi, and `~/.agents/skills/`. All links use the same repo source. Create
new portable skills here and add the links described in
[install.md](install.md#custom-skills). Other harnesses that support Agent Skills
can use the same source through their own skill paths.

[Pi extension skills](shared/pi/skills) stay Pi-only because they require Pi's
background-terminal and subagent tools. Package-managed, plugin, and system
skills stay outside this repo.
