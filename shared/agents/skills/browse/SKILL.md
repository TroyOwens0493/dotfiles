---
name: browse
description: Use the Browse browser extension and relay when the user asks for Browse, "opencode browse", or control of a browser connected through Browse on another machine such as work-mac. Diagnose and repair missing tools, relay failures, pairing, and extension connections. Do not select for ordinary web search.
---

# Browse

Browse is Anomaly's Chrome-family browser extension, relay, and MCP server.
It runs Playwright in the user's real browser with its existing login state.
The local relay can connect to a browser on another computer, such as work-mac.

"Opencode browse" names this browser tool. It does not request the OpenCode
agent harness. Use the current harness; do not launch OpenCode or change provider
to obtain Browse. Keep model requirements separate from tool choice.

## Use

- Discover `mcp__browse__*` tools and call `status` first. Read the connected
  browser names and IDs; select the requested browser when you create a session.
- Use your own session, pass its ID, and set an origin allowlist. Read `execute`
  help. Inspect with `snapshot()`, act with refs or accessible locators, and verify.
- If MCP tools are absent, use the same relay through the `browse` CLI:
  `browse --help`, `browse status --json`, then `browse execute --file script.js`
  with an explicit session. No OpenCode process is required.
- Keep requested walkthrough tabs open; use `keepVisible` when needed. Otherwise
  clean up your own session. Remote `localhost` means the browser's computer.
  Use a reachable address. T3 environment links are separate from Browse pairing.

## Fix the connection

1. Run `browse status --json`. Read the exact error, browser identity, pairing
   state, protocol compatibility, and `nextStep` before changing anything.
2. Missing tools, working CLI: fix the current harness's MCP entry to run
   `browse mcp`, then reconnect the MCP client.
3. Stale or unavailable relay: check `browse relay --help`, then use
   `browse relay restart` if needed. It can interrupt other sessions.
4. Offline browser: check that it is running, its extension is enabled, and its
   relay address is correct. Preserve existing pairing. For version mismatch,
   use `browse update --check`, then align relay and extension versions.
5. Missing pairing: use `browse pair` and the extension's pairing flow. Handle
   codes through secure input, not chat. `browse install --remote` changes relay
   exposure; reserve it for new remote setup. Do not erase pairing as a routine fix.
6. Check status again and verify a page in the intended browser. If it still
   fails, report the exact failure and next action. Connection alone does not
   prove that the requested page is ready.
