# Setup

Pi is part of the shared development config. Ask an agent to follow the root
[install.md](../../install.md) in the config repo. Use the skip-packages scope if
Node and the other tools are installed.

The guide covers links for the reviewed Pi files in `~/.config/pi`, preserves
local credentials and sessions, and provides the `~/.pi/agent` application path.
The `pi` launcher uses the runtime from `package-lock.json`. Open a new terminal
after installation so `~/.local/bin` is on PATH, then sign in with Pi's `/login`.

Use local environment files for API keys. Do not commit credentials. The current
extension set has no Firecrawl extension; `.env.example` is retained as a sample
for setups which add one.

## fd and rg tools

The `file-search` extension registers `fd` and `rg` as model tools. No setup is normally needed: at startup it silently uses a system-installed `fd` (or `fdfind` on Debian/Ubuntu) and `rg` when available, or an existing fallback binary in `~/.pi/agent/bin/`. Only when neither exists does it download an official release binary (macOS/Linux, arm64/x64, over HTTPS) into `~/.pi/agent/bin/` and show a one-time notification. If your platform is unsupported, install `fd` and `rg` with your package manager and restart pi.

## Theme

Add the included theme to `~/.pi/agent/settings.json` while keeping your existing settings:

```json
{
  "theme": "github-dark-default"
}
```

Pi will load the extensions, skills, and theme from their directories the next time it starts.
