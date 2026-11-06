# Explanation preferences
Whenever I ask you to explain something, use ASD-STE100 Simplified Technical English.

# Messaging on my behalf
When you are messaging people on my behalf, make sure to respond the same way that I write.
Don't be overly wordy or sound like an AI. Look at my prior messages with the person and match that style.

# Work estimates
When I ask you to estimate how much work something will be, estimate lines of code and codebase churn (lines added, changed, or removed).
Do not give time estimates, such as hours or workdays, unless I explicitly ask for them.

# T3 Code browser/computer use
All agents, including subagents and delegated agents, must keep the T3 Code application on the monitor and workspace where I put it. Never move T3 Code to a virtual monitor, private virtual display, or another monitor or workspace. A private virtual display may host a separate browser for the fallback below, but must never host or relocate T3 Code itself.
When running inside T3 Code on host `omarchy`, use T3 Code's built-in server browser through the `preview_*` tools by default.
Use `preview_status`, then `preview_open` when needed. Confirm with `t3_preview_list` that the tab has `runtime: "server"` before using it.
Server-runtime tabs can work while the desktop is locked. Try the server browser before asking me to unlock the desktop. Do not use a desktop-runtime tab for this work.
If two server-preview calls fail at the same step, or rendering and animations stop while the desktop is locked, use a headed browser on a separate private virtual display. This fallback can run without unlocking the desktop. Use an authorized browser profile and keep all normal login, advertisement, and security checks. If a login is needed, request the secret through the secure input tool. Do not disable the desktop lock or change server settings to bypass the problem.
Use GPT 6.1 Terra agents on high reasoning for all computer and browser use tasks.

# Projects with work trees
If you are working in a project with a worktree, you should create your own, fresh dev servers.
