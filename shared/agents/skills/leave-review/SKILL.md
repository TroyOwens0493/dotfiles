---
name: leave-review
description: Use when Troy asks you to leave review comments on a pull request on his behalf. Save the comments in a draft review for him to edit and submit.
---

# Leave a PR review

## Write the comments

- Write one inline comment for each finding Troy has agreed to fix. Anchor it to the relevant line in the current PR diff.
- Match Troy's voice. Look at his prior review comments to the PR author when available. Keep each comment direct and concise.
- State the problem and propose a fix. Omit how you tested the code or found the issue.

## Save the review as a draft

Preserve existing drafts and skip comments that already cover the same finding.

1. Prefer the Linear MCP when it can access the PR diff and save drafts. Use `get_diff_threads` to check existing drafts, then save each new comment with `save_diff_comment` and `draft: true`.
2. If Linear is unavailable for this PR, use the GitHub CLI. Use `gh api` to find the authenticated user's `PENDING` review. If none exists, create one with `gh api graphql` and `addPullRequestReview`, omitting `event`. Verify the review is `PENDING`, then add comments with `addPullRequestReviewThread` using that review's node ID as `pullRequestReviewId`. See [GitHub's pull request GraphQL reference](https://docs.github.com/en/graphql/reference/pulls).
3. Verify the comments are saved as drafts or belong to the pending review. Report where Troy can edit them and flag any comments that could not be saved.

Never submit or publish the review or its comments. Troy edits and submits the review himself.
