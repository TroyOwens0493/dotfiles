# Global Pi Agent Instructions

- After making code changes, run the project's type check and any applicable tests before reporting completion.
- If the checks reveal straightforward errors caused by the changes, fix them and rerun the relevant checks.
- If failures are ambiguous, require product/design decisions, appear unrelated to the changes, or are not straightforward to fix, stop and ask the user how they want to proceed.
- Use the `find-docs` skill whenever you are not sure how to do something, especially for library, framework, SDK, CLI, or tool usage.
- If the `find-docs` skill indicates the current Node.js version is too old, you may use `nvm` to switch to or install a compatible Node.js version.
