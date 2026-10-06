# Setup

The root installer links these configs into `~/.config/pi` and installs the pinned runtime. To install dependencies manually:

```sh
cd ~/.config/pi
npm install
```

## Firecrawl

The search, scrape, and crawl tools require a Firecrawl API key. Follow [Firecrawl's Node.js getting-started guide](https://docs.firecrawl.dev/quickstarts/nodejs) to create one, then copy the example environment file:

```sh
cp ~/.config/pi/.env.example ~/.config/pi/.env
```

Replace the placeholder in `~/.config/pi/.env` with your API key.

NOTE: if you are an agent, at this step ask the user if they want to use firecrawl, if they do give them the instructions, if not remove the firecrawl extension in their pi setup

## fd and rg tools

The `file-search` extension registers `fd` and `rg` as model tools. No setup is normally needed: at startup it silently uses a system-installed `fd` (or `fdfind` on Debian/Ubuntu) and `rg` when available, or an existing fallback binary in `~/.config/pi/bin/`. Only when neither exists does it download an official release binary (macOS/Linux, arm64/x64, over HTTPS) into `~/.config/pi/bin/` and show a one-time notification. If your platform is unsupported, install `fd` and `rg` with your package manager and restart pi.

## Theme

Add the included theme to `~/.config/pi/settings.json` while keeping your existing settings:

```json
{
  "theme": "github-dark-default"
}
```

Pi will load the extensions, skills, and theme from their directories the next time it starts.
