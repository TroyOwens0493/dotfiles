---
name: ui-review
description: Use when Troy asks for a UI review or names the ui-review skill. Walk Troy through each UI change in a browser, one stop at a time, and collect his feedback for a follow-up thread.
---

# UI review

Walk Troy through the UI changes in a running app. Each page or view with changes is a stop.

## Set up

1. Start a fresh dev server for the changes. Seed a fresh database if the project has a seed script.
2. Use the browse skill on the machine that Troy names. If he does not name one, ask him which machine to use.
3. Find all of the UI changes and put them in order. This is the list of stops.

## At each stop

1. Navigate to the stop.
2. Give a brief summary of what changed on this page.
3. If the changes are small or hard to see, include a screenshot. Highlight the changed UI elements in the screenshot.
4. Wait for Troy to reply:
   - If he says "next", go to the next stop.
   - If he gives feedback, write it down with the stop that it applies to. Do not make changes to fix it now. Then wait for him to say "next".

## Finish

1. After the last stop, show Troy the list of feedback, grouped by stop, and open questions (if any.)
2. Once given the go ahead, start a new thread to make the changes. Give it the full feedback list and the context it needs to find each change.
