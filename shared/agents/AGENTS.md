# T3 Code window
All agents, including subagents and delegated agents, must keep the T3 Code application on the monitor and workspace where I put it. 
Never move T3 Code to a virtual monitor, private virtual display, or another monitor or workspace.

# Projects with worktrees
If you are working in a project with a worktree, you should create your own, fresh dev servers.
Don't assume that you can use my, or another agents dev server. 
You should also seed a fresh db, if there is an applicable seed script.

# Executor
Executor is set up as a CLI, not an MCP server. For tasks you would traditionally do through an MCP server for a connected app or account, such as email, calendars, docs, or issue trackers, use the `executor` CLI in the shell unless another tool is already set up for that service. Read the `executor` skill first, then start with `executor search "<task>"`. Do not add an Executor MCP server.

# Runtime modes for delegated models
When you start a model in a delegated task or new thread, such as with `delegate_task`, `t3_thread_launch`, or `create_threads`, set its runtime mode by harness:
- Codex harness: use `auto`, the auto-review classifier.
- Claude harness: use `full-access`.
