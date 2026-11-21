---
name: executor
description: Use the Executor CLI (`executor`) for apps and accounts connected in Executor, such as email, calendars, docs, issue trackers, or custom Executor apps, and to build or deploy Executor apps. Use it for tasks you would otherwise do through an MCP server for a connected service, or when the user names Executor.
---

# Executor

Executor hosts apps that expose tools for connected accounts. Use the
`executor` CLI from the shell. It replaces the Executor MCP server; do not add
one. Credentials stay in Executor. Never ask for them in chat or put them in
commands, files, or source.

## Find and call tools

Commands print JSON on stdout. A failure exits 1 and prints the error, with a
`recovery` hint, on stderr.

1. Find tools: `executor search "<what you need>"`. Narrow with
   `--namespace <app-slug>`, `--limit <n>`, and `--offset <next.offset>`.
   Use the exact `path` from the results, such as `tools.<slug>.<tool>`.
2. Read signatures: `executor describe <path>...` (up to 20 paths). Never guess
   argument names.
3. Call a tool: `executor call <path> --input '<json>'`. For large or quoted
   input, write a JSON file and pass `--input-file <file>`, or `-` for stdin.
   With no path, the input is an array of `{path, input}` calls that run
   concurrently.
4. When one result feeds another, or a result is large, write a JavaScript
   program and run `executor execute --file <file>` (or `--code '<js>'`).
   Tools are async functions such as `tools.github.issues.list(input)`.
   Return only the data you need.

Results that hold images, audio, or files print their paths in a new temporary
directory, or in `--files <dir>`. Read those files; do not ask for base64.
Redirect large output to a file and read only what you need.

## Approvals and input

A paused call prints its pending request, with an `approvalUrl` when the host
gives one. Show the request and link to the user. Continue it with
`executor resume <request-id> --action accept|decline|cancel`, adding
`--content '<json>'` or `--content-file <file>` for requested form fields.
When approvals are answered in the browser, omit `--action`; resume collects
the answer from the `approvalUrl` page. Never run the paused call or program
again to continue it.

## App instructions

Apps ship their own skills. List them with `executor skills`. Read one with
`executor skills --app <slug> --name <skill>`. Start with
`--app executor --name executor`; read `code-mode` for `execute` details and
`app-authoring` before you build an app. Use `executor apps` to create, edit,
deploy, and install apps. Where those skills describe MCP tools, use the
matching CLI command.

## Fix access

- `executor whoami` prints the host, organization, the apps the sign-in
  reaches, and its approval mode.
- If the sign-in is missing or expired, run `executor login` in the background
  and read its output. It prints a link and code that the user must approve in
  a browser. Show both to the user and wait. Do not approve it yourself.
- Do not run `executor` with no arguments; that starts a local server and opens
  its dashboard. Commands use `--host`, then `EXECUTOR_HOST`, then the last
  sign-in, then that local server.
- If `executor` is missing or reports v1, follow the Executor section of
  `~/dotfiles/install.md`, or report that it is not installed.
- If Executor gets in the way or works especially well, send specific feedback
  with the Executor app's `feedback.submit` tool. Never include credentials or
  user data.
