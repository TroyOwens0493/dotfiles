---
name: computer-use
description: Use for any browser or computer-use task, such as opening or testing a web app in a browser, clicking through a UI, filling in forms, or taking screenshots of a page. For the Browse extension, use the browse skill instead.
---

# Computer use

## Who does the work

Use the newest GPT Terra agents on high reasoning for all computer and browser use tasks. If you are already that agent, do the work yourself.

## Keep T3 Code in place

All agents, including subagents and delegated agents, must keep the T3 Code application on the monitor and workspace where Troy put it. Never move T3 Code to a virtual monitor, private virtual display, or another monitor or workspace. A private virtual display may host a separate browser for the fallback below, but must never host or relocate T3 Code itself.

## Use the server browser

On host `omarchy`, use T3 Code's built-in server browser through the `preview_*` tools by default.

1. Use `preview_status`, then `preview_open` when needed.
2. Confirm with `t3_preview_list` that the tab has `runtime: "server"` before you use it. Do not use a desktop-runtime tab for this work.

Server-runtime tabs can work while the desktop is locked. Try the server browser before you ask Troy to unlock the desktop.

## Fallback

If two server-preview calls fail at the same step, or rendering and animations stop while the desktop is locked, use a headed browser on a separate private virtual display. This fallback can run without unlocking the desktop.

- Use an authorized browser profile and keep all normal login, advertisement, and security checks.
- If a login is needed, request the secret through the secure input tool.
- Do not disable the desktop lock or change server settings to bypass the problem.
