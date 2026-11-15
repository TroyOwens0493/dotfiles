---
name: work-recap
description: Prepare Troy's NOMP work descriptions from verified work evidence and maintain NOMP entries through the Keep Hours MCP when requested or authorized by the daily recap schedule.
---

# NOMP work recap

## Scope

Include only work Troy did in `legrande-health/nomp`, including its worktrees. Locate the existing NOMP checkout on this machine; the usual location is `~/dataThink/nomp`. Verify each item against NOMP Git history or direct evidence of Troy's NOMP work.

Exclude other projects, including BudgetTogether, Keep Hours development or invoicing administration, personal tasks, desktop configuration, and general agent or skill setup. Activity in the same chat, folder, or day is not proof that work belongs to NOMP. Omit items with unclear project scope or attribution. Handle any separately requested project outside the NOMP description.

## Find the work

- Read applicable AGENTS.md instructions. Locate an existing checkout and inspect its worktrees without changing branches or starting services.
- Use the requested dates in America/Boise, with the correct UTC offsets. Identify Troy from Git configuration and author history.
- Inspect local branches, remote-tracking branches, and reflogs. Use `git log --all --reflog` as a starting point, then inspect full messages, author and committer dates, changed files, and relevant diffs.
- Count each change once across worktrees, rebases, cherry-picks, and squashes. Do not credit other authors' work to Troy. A routine merge alone does not prove implementation or review.

## Write the description

Use ASD-STE100 Simplified Technical English. Use short sentences, past-tense actions, and terms the client can understand. Group related changes by their practical result. Claim tests, deployments, meetings, or measured benefits only when evidence supports them.

When correcting an existing description, remove unrelated work and preserve verified NOMP work. Do not invent replacement work to fill the removed text.

## Keep Hours

- Use the Keep Hours MCP. Resolve the organization, call `get_week` for the target date, and use `list_projects` for valid project/task IDs. Currently NOMP uses DataThink's Application Development project for Legrande; verify the current tools' results.
- Check existing entries and locked periods before writing. Update descriptions with `update_time_entry`, passing only the ID, organization when needed, and corrected description. Preserve duration, date, project/task, start/end times, and payment status.
- Do not duplicate entries, delete entries, or reset durations Troy has corrected. If the match is unclear, report the ambiguity.
- For an authorized daily scheduled recap, use one new entry of 60 minutes for the whole local day. This is Troy's temporary value for later adjustment, not an estimate from Git. Skip days without attributable NOMP work. Follow the scheduler's target date and do not backfill unless requested.
- Do not assume a manual recap request authorizes new time entries or a duration. Follow the user's requested action.
- Locked or paid entries can reject corrections. Report the exact date and rejected change; do not bypass the lock or alter invoices.
- Inspect every write result. Read entries again after an uncertain result before retrying. Report only confirmed writes and list blocked corrections.
- Do not send invoices, message clients, or create schedules as part of a recap.
