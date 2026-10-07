import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  buildCodexRecords,
  exportPiSessionFile,
  outputPathForSession,
  parsePiSessionJsonl,
} from "./src/codex-log.ts";

const header = {
  id: "019-test-session",
  timestamp: "2026-09-21T15:55:53.652Z",
  cwd: "/tmp/project",
};

test("maps Pi usage to cumulative Codex token_count records", () => {
  const records = buildCodexRecords(header, [
    {
      type: "message",
      timestamp: "2026-09-21T15:56:00.000Z",
      message: {
        role: "assistant",
        provider: "openai",
        model: "gpt-5.6-sol",
        timestamp: Date.parse("2026-09-21T15:56:00.000Z"),
        content: [{ type: "text", text: "First" }],
        usage: {
          input: 100,
          output: 20,
          cacheRead: 40,
          cacheWrite: 5,
          reasoning: 3,
          totalTokens: 165,
        },
      },
    },
    {
      type: "message",
      timestamp: "2026-09-21T15:57:00.000Z",
      message: {
        role: "assistant",
        provider: "openai",
        model: "gpt-5.6-sol",
        timestamp: Date.parse("2026-09-21T15:57:00.000Z"),
        content: [{ type: "text", text: "Second" }],
        usage: {
          input: 200,
          output: 30,
          cacheRead: 60,
          cacheWrite: 0,
          reasoning: 7,
          totalTokens: 290,
        },
      },
    },
  ]);

  const counts = records.filter(
    (record) =>
      record.type === "event_msg" && record.payload.type === "token_count",
  );
  assert.equal(counts.length, 2);
  assert.deepEqual(counts[0]?.payload.info, {
    total_token_usage: {
      input_tokens: 145,
      cached_input_tokens: 40,
      cache_write_input_tokens: 5,
      output_tokens: 20,
      reasoning_output_tokens: 3,
      total_tokens: 165,
    },
    last_token_usage: {
      input_tokens: 145,
      cached_input_tokens: 40,
      cache_write_input_tokens: 5,
      output_tokens: 20,
      reasoning_output_tokens: 3,
      total_tokens: 165,
    },
    model_context_window: null,
  });
  assert.deepEqual(
    (counts[1]?.payload.info as { total_token_usage: unknown })
      .total_token_usage,
    {
      input_tokens: 405,
      cached_input_tokens: 100,
      cache_write_input_tokens: 5,
      output_tokens: 50,
      reasoning_output_tokens: 10,
      total_tokens: 455,
    },
  );
});

test("translates Pi messages and tool calls into Codex response items", () => {
  const records = buildCodexRecords(header, [
    {
      type: "message",
      timestamp: header.timestamp,
      message: { role: "user", content: "Run the tests" },
    },
    {
      type: "message",
      timestamp: header.timestamp,
      message: {
        role: "assistant",
        content: [
          { type: "thinking", thinking: "I should inspect the project." },
          {
            type: "toolCall",
            id: "call-1",
            name: "bash",
            arguments: { command: "npm test" },
          },
        ],
      },
    },
    {
      type: "message",
      timestamp: header.timestamp,
      message: {
        role: "toolResult",
        toolCallId: "call-1",
        toolName: "bash",
        content: [{ type: "text", text: "Tests passed" }],
      },
    },
  ]);

  const items = records
    .filter((record) => record.type === "response_item")
    .map((record) => record.payload.type);
  assert.deepEqual(items, [
    "message",
    "reasoning",
    "custom_tool_call",
    "custom_tool_call_output",
  ]);
});

test("exports a Pi JSONL file to a deterministic Codex rollout path", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-codex-logs-"));
  const input = join(root, "pi.jsonl");
  const outputRoot = join(root, "codex");
  await writeFile(
    input,
    `${JSON.stringify({ type: "session", version: 3, ...header })}\n${JSON.stringify(
      {
        type: "message",
        id: "abc",
        parentId: null,
        timestamp: header.timestamp,
        message: { role: "user", content: "Hello", timestamp: 1 },
      },
    )}\n`,
  );

  const parsed = parsePiSessionJsonl(await readFile(input, "utf8"));
  assert.equal(parsed.entries.length, 1);

  const result = await exportPiSessionFile(input, outputRoot);
  assert.equal(result.outputPath, outputPathForSession(header, outputRoot));
  const output = await readFile(result.outputPath, "utf8");
  assert.match(output, /"type":"session_meta"/);
  assert.match(output, /"originator":"Pi"/);
});
