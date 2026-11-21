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

Personal Hyprland settings use Omarchy's split configuration files under
`omarchy/hypr/`, loaded after its packaged defaults. Monitor settings and final
machine-specific overrides stay local in `~/.config/hypr/monitors.lua` and
`local.lua`.

Omarchy shell plugins are separate Git repositories installed with
`omarchy plugin add` and updated with `omarchy plugin update`:
[My Workspaces](https://github.com/TroyOwens0493/omarchy-workspaces) (private;
requires GitHub SSH access) and
[System Pulse](https://github.com/lucaslus/omarchy-statusline).
Plugin folders contain real files, with no symlinks. See `install.md` for setup.

Keep the repo at `~/dotfiles` so the links continue to work.

[browse](https://github.com/anomalyco/browse) is included in setup for both
platforms. OpenCode and Pi use its shared MCP entries; setup adds it to Codex,
Claude Code, Gemini CLI, and Copilot CLI. Each machine needs the browser
extension and local pairing. See [install.md](install.md#browse).

[Executor](https://executor.sh) is used through its v2 CLI, not an MCP server.
Setup installs `executor` on both platforms, removes old Executor MCP entries,
and each machine signs in with `executor login`. The
[executor skill](shared/agents/skills/executor/SKILL.md) tells agents how to
search, call, and resume Executor tools from the shell.
See [install.md](install.md#executor).

## Custom skills

Edit portable custom skills in [shared/agents/skills](shared/agents/skills):

- [PR checklist](shared/agents/skills/pr-checklist/SKILL.md)
- [Code review](shared/agents/skills/code-review/SKILL.md)
- [Explain](shared/agents/skills/explain/SKILL.md): explanations in Simplified Technical English
- [Write as Troy](shared/agents/skills/write-as-troy/SKILL.md): messages on Troy's behalf
- [Estimate work](shared/agents/skills/estimate-work/SKILL.md): estimates in lines of code and churn
- [Computer use](shared/agents/skills/computer-use/SKILL.md): browser and computer-use rules
- [Executor](shared/agents/skills/executor/SKILL.md): connected apps through the Executor CLI

Short global rules for all agents are in
[shared/agents/AGENTS.md](shared/agents/AGENTS.md). Codex and Claude Code link to
it; OpenCode and Pi keep a copy at the end of their own instruction files.

Three [tstack skills](https://github.com/t3dotgg/tstack) are also included:
`full-send`, `full-stop`, and `sol-loop`. Each includes its upstream commit in
`SOURCE.md` and its MIT license. `full-send` reviews with `sol-loop`, like
upstream, and has local changes so it needs no other tstack skills. Keep these
changes and upstream supporting files when updating.

The tstack skills require authenticated `gh` for pull request work. `sol-loop`
also requires access to GPT Sol, and to Claude Opus when an OpenAI model runs
`full-send`, through T3 Code or another harness that supports those models.

Each skill has links in the user skills directories for Codex, Claude Code,
OpenCode, Pi, and `~/.agents/skills/`. All links use the same repo source. Create
new portable skills here and add the links described in
[install.md](install.md#custom-skills). Other harnesses that support Agent Skills
can use the same source through their own skill paths.

[Pi extension skills](shared/pi/skills) stay Pi-only because they require Pi's
background-terminal and subagent tools. Package-managed, plugin, and system
skills stay outside this repo.
