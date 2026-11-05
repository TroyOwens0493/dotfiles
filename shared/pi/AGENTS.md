When working in typescript:

- when adding a package to a project add it with an install command, instead of manually editing the package json
- run check/format/lint commands when your done making a change. if they don't exist, suggest making them for the project you're in
- avoid explicit return types unless absolutely needed
- `as any` should be an absolute last resort. always use real type safety. lean on type inference instead of manually writing new types over and over again

When working in svelte(kit):

- use modern svelte practices, reference the svelte best practicies skill when writing .svelte file code

In general:

- when asking questions, ask them one at a time

# T3 Code browser on this machine

When running inside T3 Code on host `omarchy`, use T3 Code's built-in server browser through the `preview_*` tools by default. Prefer server-runtime tabs over desktop-runtime tabs. Browser work must not require a connected physical display or moving T3 Code's main window to a virtual monitor. If the server browser is unavailable, state the limitation instead of silently switching browser systems.
