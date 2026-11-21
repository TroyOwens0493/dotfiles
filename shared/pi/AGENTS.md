When working in typescript:

- when adding a package to a project add it with an install command, instead of manually editing the package json
- run check/format/lint commands when your done making a change. if they don't exist, suggest making them for the project you're in
- avoid explicit return types unless absolutely needed
- `as any` should be an absolute last resort. always use real type safety. lean on type inference instead of manually writing new types over and over again

When working in svelte(kit):

- use modern svelte practices, reference the svelte best practicies skill when writing .svelte file code

In general:

- when asking questions, ask them one at a time

# T3 Code window
All agents, including subagents and delegated agents, must keep the T3 Code application on the monitor and workspace where I put it. Never move T3 Code to a virtual monitor, private virtual display, or another monitor or workspace.

# Projects with worktrees
If you are working in a project with a worktree, you should create your own, fresh dev servers.

# Executor
Executor is set up as a CLI, not an MCP server. For tasks you would traditionally do through an MCP server for a connected app or account, such as email, calendars, docs, or issue trackers, use the `executor` CLI in the shell unless another tool is already set up for that service. Read the `executor` skill first, then start with `executor search "<task>"`. Do not add an Executor MCP server.
