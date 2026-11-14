---
name: distribute-across-fleet
description: Use when you are told to update my dotfiles or configs.
---

# Distribute Across Fleet

Keep the local config current. When the user asks you to push dotfiles or config
changes to the remote, also update every other machine you can access after the
push succeeds. This is part of the requested push; do not ask again for permission
to start the update threads.

## Update the other machines

Use T3 Code's linked-environment and thread tools for this work. If these tools
are not available, report that you cannot start the remote update threads.

1. Confirm that the push succeeded. Record the repository remote, branch, and
   pushed commit.
2. Call `t3_environment_links` to find the other machines. Exclude the current
   machine. Start one new top-level thread on each accessible machine with
   `t3_thread_launch`, using that machine's `environmentId`. Find its local
   dotfiles project and bind the thread to its existing checkout. Do not assume
   project IDs or filesystem paths are the same on different machines.
3. Give each thread the remote, branch, pushed commit, and the instructions below.
4. Wait for each thread to finish. Check its result. Report the state of each
   machine and link to its thread with the returned thread link. Report machines
   that are unreachable, have expired access, or could not be updated. Do not
   claim that all machines are current unless each update is verified.
5. Settle each machine's update thread after its update and checks succeed without
   issues. Use `t3_thread_organize` with `action: "settle"`, that machine's
   `environmentId`, and its update `threadId` if the thread has not already settled
   itself. Leave threads with issues or incomplete updates active and report them.
   Apply this only to threads used for this distribution, not unrelated threads.

## Instructions for each machine's thread

- Update this machine only. Do not push or start update threads on other machines.
- Read the repository instructions and `install.md`, if present. Use the skills
  that apply to this machine and the changed config.
- Check the checkout, remote, branch, and local changes before you pull. Preserve
  local edits and machine-specific settings. Do not discard changes, force a
  reset, or change to an unrelated branch to make the pull succeed. If local
  changes or divergent history prevent a safe update, report the blocker.
- Pull the latest changes from the specified remote branch with a fast-forward
  update. Verify that the checkout contains the pushed commit.
- Apply all config setup steps that this machine needs from the updated repo.
  Create or fix symlinks, install required config dependencies, run applicable
  migrations, and reload affected apps or services. Use this machine's platform
  instructions. A successful Git pull alone does not complete the update.
- Check that the applicable configs and links are current and valid. Report the
  installed commit, what you applied, the checks you ran, and any remaining
  blockers. If a required step cannot be completed, report the update as incomplete.
- If the update and all checks succeed without issues, settle this update thread
  with `t3_thread_organize` and `action: "settle"` before your final reply. Omit
  `threadId` to settle your current thread at turn end. If you encounter any issue
  or cannot complete the update, leave the thread active and report the issue.
