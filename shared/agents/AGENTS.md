# T3 Code window
All agents, including subagents and delegated agents, must keep the T3 Code application on the monitor and workspace where I put it. 
Never move T3 Code to a virtual monitor, private virtual display, or another monitor or workspace.

# Projects with worktrees
If you are working in a project with a worktree, you should create your own, fresh dev servers.
Don't assume that you can use my, or another agents dev server. 
You should also seed a fresh db, if there is an applicable seed script.

# Runtime modes for delegated models
When you start a model in a delegated task or new thread, such as with `delegate_task`, `t3_thread_launch`, or `create_threads`, set its runtime mode by harness:
- Codex harness: use `auto`, the auto-review classifier.
- Claude harness: use `full-access`.
