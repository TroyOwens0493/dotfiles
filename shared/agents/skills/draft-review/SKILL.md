---
name: draft-review
description: Use when Troy asks you to leave review comments on a pull request on his behalf. Save the comments in a draft review for him to edit and submit.
---

# Draft a PR review

## Write the comments

- Write one comment for each finding Troy has agreed to fix. Attach it to the relevant line or file in the current PR diff.
- Match Troy's voice. Look at his prior review comments to the PR author when available. Keep each comment direct and concise.
- State the problem and propose a fix. Omit how you tested the code or found the issue.

## Save the review as a draft

Preserve existing drafts and skip comments that already cover the same finding.

1. Use Linear MCP `get_diff` to get the diff's `slugId` and full `headSha`. Use `get_diff_threads` to check existing drafts and comments for duplicates.
2. Save each new comment with `save_diff_comment`, using the `slugId` as `urlOrId` and setting `draft: true`. Use a line anchor when you know the schema. If Linear rejects the line anchor or the schema is unknown, use this file anchor and omit `anchorContent`.

   ```json
   { "type": "file", "path": "<repo-relative path>", "commit": "<full headSha>" }
   ```

3. Use `get_diff_threads` to verify that the comments appear as drafts. Report where Troy can edit them. If Linear is unavailable or cannot save a comment with a valid file anchor, report the error and ask Troy before saving any drafts on GitHub.

Never submit or publish the review or its comments. Troy edits and submits the review himself.
