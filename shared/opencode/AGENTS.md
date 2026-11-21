# Agent Documentation Guidance

When you need documentation or are unsure about an API, library, or framework detail, use the `find-docs` skill, which fetches up-to-date docs and examples through the authenticated `ctx7` CLI. This should be your default source for resolving uncertainty and confirming usage.

# Coding Rules

## Types

- Use types for everything you write: function parameters, variables when inference is not enough, component props, loader/action data, and object shapes.
- Avoid `any`. Prefer precise unions, generics, utility types, and narrowed domain types.
- Define a type inline only when it is local to a single file and will not be reused.
- When a type may be shared across files, move it to a shared type module instead of redefining it.
- Never write explicit return types for functions, when using TypeScript they should always be inferred.

## Functions

- Add a doc comment to every function you write, including exported helpers, server utilities, loaders, actions, React components, and small local helpers.
- Keep doc comments concise and useful. Describe the function's purpose and include important behavior when it is not obvious from the name/signature.
- Try to keep write functions that only do one thing. If you are considering writing a function that does lots of tasks, consider refactoring.

## Comments

- Write inline comments for code that is complex, surprising, or otherwise hard to follow.
- Do not add comments for straightforward code or comments that only restate the code.
- Prefer comments that explain why the code exists, what edge case it handles, or what assumption it relies on.

# Searching

## Prefer `ripgrep` (`rg`) over `grep`
- All agents and scripts should default to using **`ripgrep` (`rg`)** instead of traditional `grep` for text search operations.

# T3 Code window
All agents, including subagents and delegated agents, must keep the T3 Code application on the monitor and workspace where I put it. Never move T3 Code to a virtual monitor, private virtual display, or another monitor or workspace.

# Projects with worktrees
If you are working in a project with a worktree, you should create your own, fresh dev servers.

# Executor
Executor is set up as a CLI, not an MCP server. For tasks you would traditionally do through an MCP server for a connected app or account, such as email, calendars, docs, or issue trackers, use the `executor` CLI in the shell unless another tool is already set up for that service. Read the `executor` skill first, then start with `executor search "<task>"`. Do not add an Executor MCP server.

# Runtime modes for delegated models
When you start a model in a delegated task or new thread, such as with `delegate_task`, `t3_thread_launch`, or `create_threads`, set its runtime mode by harness:
- Codex harness: use `auto`, the auto-review classifier.
- Claude harness: use `full-access`.
