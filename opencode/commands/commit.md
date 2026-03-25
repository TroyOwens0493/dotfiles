---
description: Create a commit msg and desc, then push changes.
agent: build
model: openrouter/openai/gpt-5-nano
---

You are to git add . every file.
Then you should review the changes with git diff --staged.
Once you have a feel for what features/changes are introduced with those changes, you must make a commit.
Use git commit -m "Title" -m $'Description... \nAnother descriptive line' in order to make your commit message and description all in one go.
Make sure to follow all standards and conventions for commit naming.
Keep commits short and don't write descriptions unless they are needed.
