import assert from "node:assert/strict";
import test from "node:test";

import { createUndoChoices, previewUserContent } from "./index.ts";

test("previewUserContent normalizes text and preserves image placeholders", () => {
  assert.equal(
    previewUserContent([
      { type: "text", text: "  fix\n\nthis   bug " },
      { type: "image", data: "ignored" },
    ]),
    "fix this bug [image]",
  );
});

test("previewUserContent truncates long prompts", () => {
  const preview = previewUserContent("a".repeat(120));

  assert.equal(preview.length, 100);
  assert.match(preview, /…$/);
});

test("createUndoChoices shows the most recent prompt first", () => {
  assert.deepEqual(
    createUndoChoices([
      { id: "first", content: "First prompt" },
      { id: "second", content: "Second prompt" },
    ]),
    [
      { id: "second", label: "2. Second prompt" },
      { id: "first", label: "1. First prompt" },
    ],
  );
});
