---
name: pr-checklist
description: "Run an existing pull request's checklist, retry transient Playwright failures, and report whether it is ready for review. Use when asked to run the PR checklist or check PR readiness. Leave Slack messages to the user."
---

# PR Checklist

Complete the PR checklist except for Slack messages, which the user will send. End with a clear readiness result.

## Find the checklist and PR

- Use the PR and worktree from the conversation or current branch. If more than one PR could be the target, ask which one while reading the local checklist and task definitions.
- Read the applicable `AGENTS.md` files, the PR body, and the repository's current PR template. Use these as the source of the checklist; do not rely on a copied list in this skill.
- Read the actual commands behind named tasks, including `.vscode/tasks.json`, package scripts, and test configuration. For nomp, the template is `.github/pull_request_template.md`, and the named tasks include `PR - Frontend`, `PR - Backend`, and `PR - Playwright`.
- Inspect the PR diff and base branch so you can assess whether test failures relate to the changes. Use `gh` when available. If T3 Code exposes PR linking tools, register the PR when starting and verify that it is linked before finishing.

## Run the checks

- Work through all applicable checklist items except Slack. Run the required local tests even if CI has passed. Inspect CI results when available as additional evidence.
- Check branch freshness against the current remote base. Follow repository instructions for any required branch update, and preserve the user's existing work. Verify the resulting code if an update or formatting task changes it.
- When merging `main` into an existing PR branch, push the merge commit to the PR's existing remote branch after verification. The user authorizes this push as part of running this skill, as an exception to their general "don't push until I ask" preference; no separate approval is needed. An explicit instruction not to push for the current run still takes precedence. Verify that the remote PR head includes the updated `main` before checking the branch-freshness item.
- Use the intended PR worktree. Follow repository rules if a new worktree is needed. In nomp, use the Linear ticket number as the directory name, use Direnv, and run `firebase use staging` from the new worktree's `frontend/` directory. Verify that the active Firebase project is `nomp-staging`.
- When tests or manual checks need a development server, start your own instance on an available port and point the checks at it. Do not use the user's server. Stop the servers, emulators, and other services you start when finished, including after failures.
- Keep this task focused on completing the checklist. Do not create or merge a PR, deploy, or send messages to other people as part of this skill.

## Handle Playwright failures

- Expect some first-run failures from timeouts. Inspect the failure output and rerun the failed tests before drawing a conclusion. Prefer a targeted retry over rerunning the full suite.
- Allow up to two retries after the initial failure, counting automatic Playwright retries toward that limit. Stop retrying when the test passes or the limit is reached. Do not increase timeouts, weaken assertions, skip tests, or change application behavior merely to obtain a pass.
- Flag a Playwright failure as a PR issue only when it fails repeatedly and evidence connects it to the PR changes. Use the failure details, changed code, and, when needed, a comparison with the base branch to establish that connection.
- Do not list recovered timeouts or confirmed unrelated failures as PR defects. Keep the report brief. If unrelated failures remain, state that the test suite is not fully green without presenting them as defects caused by this PR.
- If the cause is unknown, report the verification limit without claiming a regression. A test that could not run is unverified, not passed.

## Update the checklist and report

- Update the checklist on the GitHub PR itself: change completed items from `- [ ]` to `- [x]` only when the evidence supports them. This GitHub update is part of the requested work. Preserve the PR body's sections and description; do not repeat checklist results in the description.
- Use `gh pr edit <PR> --body-file <file>` or the available GitHub API to save the updated PR body. Read the current body before editing, then fetch it again after saving to verify that the checklist changes appear on GitHub. If the update fails, report that it was not saved.
- Preserve the Slack checkbox exactly as it appears in the current PR body. The user sends the message and checks this item. Do not check or uncheck it, including when it is already checked. Leave any other incomplete or unverified item unchecked. In particular, do not check an item that says all tests pass if failures remain, even when those failures are unrelated to the PR.
- State whether the PR is ready for review, ready with a stated test limitation, or not ready. Give a short summary of checks and any remaining work. Reserve PR-related Playwright defect reports for failures that meet both conditions above.
- Mention that Slack remains for the user only if its checkbox is unchecked. When explaining results, use ASD-STE100 Simplified Technical English.
