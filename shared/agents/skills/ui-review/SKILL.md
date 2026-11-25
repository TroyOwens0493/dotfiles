---
name: ui-review
description: Use when Troy asks for a UI review or names the ui-review skill. Walk Troy through each UI change in a browser, one stop at a time, and collect his feedback for a follow-up thread.
---

# UI review

Walk Troy through the UI changes in a running app.

## Set up

1. Start a fresh dev server. Seed a fresh database if the project has a seed script.
2. Use the browse skill on the machine Troy names. Ask which machine to use if he has not named one.
3. List the UI changes in walkthrough order. Give each change that requires interaction its own stop. Put all of the small static changes in the PR, such as wording, spacing, or a changed symbol, into one stop at the end of the walkthrough, even when they are on different views.

## At each stop

1. Open the relevant view. If the change requires interaction, do not perform it. Give Troy short, numbered steps to try it himself.
2. Briefly describe the change at this stop. Include a screenshot with the changed elements highlighted if they are small or hard to see.
3. For the static-changes stop, show one click-through gallery with `html_render` instead of opening each view. Show one numbered screenshot at a time, cropped to the change with the changed elements highlighted, with its route, a one-line caption, and Previous and Next buttons.
4. Wait for Troy's reply. Record any feedback against the stop, and the screenshot number if there is one, and leave fixes for the follow-up thread. Advance when he says "next" or gives feedback. Stay if he asks a question or asks to stay.

## Finish

1. After Troy responds to the last stop, summarize the feedback by stop and list any open questions.
2. If there are fixes to make, ask Troy to approve starting a follow-up thread. After he approves, start it with the full feedback and the context needed to locate each change.
