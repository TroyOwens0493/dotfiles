import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

export interface PiUsage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  reasoning?: number;
  totalTokens: number;
}

export interface PiContentBlock {
  type: string;
  text?: string;
  thinking?: string;
  id?: string;
  name?: string;
  arguments?: unknown;
}

export interface PiMessage {
  role: string;
  content?: string | PiContentBlock[];
  timestamp?: number;
  provider?: string;
  model?: string;
  usage?: PiUsage;
  toolCallId?: string;
  toolName?: string;
  isError?: boolean;
}

export interface PiSessionHeader {
  id: string;
  timestamp: string;
  cwd: string;
}

export interface PiSessionEntry {
  type: string;
  timestamp?: string;
  provider?: string;
  modelId?: string;
  message?: PiMessage;
}

interface CodexTokenUsage {
  input_tokens: number;
  cached_input_tokens: number;
  cache_write_input_tokens: number;
  output_tokens: number;
  reasoning_output_tokens: number;
  total_tokens: number;
}

interface CodexRecord {
  timestamp: string;
  type: string;
  payload: Record<string, unknown>;
  ordinal: number;
}

export interface ExportedSession {
  header: PiSessionHeader;
  records: CodexRecord[];
  outputPath: string;
}

const ZERO_USAGE: CodexTokenUsage = {
  input_tokens: 0,
  cached_input_tokens: 0,
  cache_write_input_tokens: 0,
  output_tokens: 0,
  reasoning_output_tokens: 0,
  total_tokens: 0,
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNumber(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function parseUsage(value: unknown): PiUsage | undefined {
  if (!isRecord(value)) return undefined;

  return {
    input: asNumber(value.input),
    output: asNumber(value.output),
    cacheRead: asNumber(value.cacheRead),
    cacheWrite: asNumber(value.cacheWrite),
    reasoning: asNumber(value.reasoning),
    totalTokens: asNumber(value.totalTokens),
  };
}

function parseContent(value: unknown) {
  if (typeof value === "string") return value;
  if (!Array.isArray(value)) return undefined;

  return value.filter(isRecord).map((block) => ({
    type: typeof block.type === "string" ? block.type : "unknown",
    text: typeof block.text === "string" ? block.text : undefined,
    thinking: typeof block.thinking === "string" ? block.thinking : undefined,
    id: typeof block.id === "string" ? block.id : undefined,
    name: typeof block.name === "string" ? block.name : undefined,
    arguments: block.arguments,
  }));
}

export function coercePiMessage(value: unknown): PiMessage | undefined {
  if (!isRecord(value) || typeof value.role !== "string") return undefined;

  return {
    role: value.role,
    content: parseContent(value.content),
    timestamp:
      typeof value.timestamp === "number" ? value.timestamp : undefined,
    provider: typeof value.provider === "string" ? value.provider : undefined,
    model: typeof value.model === "string" ? value.model : undefined,
    usage: parseUsage(value.usage),
    toolCallId:
      typeof value.toolCallId === "string" ? value.toolCallId : undefined,
    toolName: typeof value.toolName === "string" ? value.toolName : undefined,
    isError: typeof value.isError === "boolean" ? value.isError : undefined,
  };
}

export function coercePiSessionEntry(
  value: unknown,
): PiSessionEntry | undefined {
  if (!isRecord(value) || typeof value.type !== "string") return undefined;

  return {
    type: value.type,
    timestamp:
      typeof value.timestamp === "string" ? value.timestamp : undefined,
    provider: typeof value.provider === "string" ? value.provider : undefined,
    modelId: typeof value.modelId === "string" ? value.modelId : undefined,
    message: coercePiMessage(value.message),
  };
}

export function parsePiSessionJsonl(contents: string) {
  let header: PiSessionHeader | undefined;
  const entries: PiSessionEntry[] = [];

  for (const line of contents.split("\n")) {
    if (!line.trim()) continue;
    const parsed: unknown = JSON.parse(line);
    if (!isRecord(parsed) || typeof parsed.type !== "string") continue;

    if (parsed.type === "session") {
      if (
        typeof parsed.id === "string" &&
        typeof parsed.timestamp === "string" &&
        typeof parsed.cwd === "string"
      ) {
        header = {
          id: parsed.id,
          timestamp: parsed.timestamp,
          cwd: parsed.cwd,
        };
      }
      continue;
    }

    const entry = coercePiSessionEntry(parsed);
    if (entry) entries.push(entry);
  }

  if (!header) throw new Error("Pi session is missing a valid session header");
  return { header, entries };
}

export function codexSessionsRoot() {
  return join(homedir(), ".codex", "sessions");
}

function filenameTimestamp(timestamp: string) {
  return timestamp.replaceAll(":", "-").replace(/\.\d{3}Z$/, "Z");
}

export function outputPathForSession(
  header: PiSessionHeader,
  root = codexSessionsRoot(),
) {
  const date = new Date(header.timestamp);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid Pi session timestamp: ${header.timestamp}`);
  }

  const year = date.getUTCFullYear().toString().padStart(4, "0");
  const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  const day = date.getUTCDate().toString().padStart(2, "0");
  return join(
    root,
    year,
    month,
    day,
    `rollout-${filenameTimestamp(header.timestamp)}-${header.id}.jsonl`,
  );
}

function isoTimestamp(message: PiMessage, fallback: string) {
  if (message.timestamp !== undefined) {
    return new Date(message.timestamp).toISOString();
  }
  return fallback;
}

function textContent(content: PiMessage["content"]) {
  if (typeof content === "string") return content;
  if (!content) return "";
  return content
    .filter((block) => block.type === "text")
    .map((block) => block.text ?? "")
    .join("\n");
}

function contentOutput(output: string) {
  return [{ type: "output_text", text: output }];
}

function addUsage(total: CodexTokenUsage, usage: CodexTokenUsage) {
  return {
    input_tokens: total.input_tokens + usage.input_tokens,
    cached_input_tokens: total.cached_input_tokens + usage.cached_input_tokens,
    cache_write_input_tokens:
      total.cache_write_input_tokens + usage.cache_write_input_tokens,
    output_tokens: total.output_tokens + usage.output_tokens,
    reasoning_output_tokens:
      total.reasoning_output_tokens + usage.reasoning_output_tokens,
    total_tokens: total.total_tokens + usage.total_tokens,
  };
}

function toCodexUsage(usage: PiUsage): CodexTokenUsage {
  return {
    // Pi reports uncached input separately, while Codex treats cached input as
    // a subset of input_tokens.
    input_tokens: usage.input + usage.cacheRead + usage.cacheWrite,
    cached_input_tokens: usage.cacheRead,
    cache_write_input_tokens: usage.cacheWrite,
    output_tokens: usage.output,
    reasoning_output_tokens: usage.reasoning ?? 0,
    total_tokens: usage.totalTokens,
  };
}

function rateLimits() {
  return {
    limit_id: "codex",
    limit_name: null,
    primary: null,
    secondary: null,
    credits: null,
    individual_limit: null,
    spend_control_reached: null,
    plan_type: null,
    rate_limit_reached_type: null,
  };
}

function codexProvider(provider: string) {
  if (
    provider === "openai" ||
    provider === "openai-codex" ||
    provider === "cli-proxy-api"
  ) {
    return "openai";
  }
  return provider;
}

function sessionMeta(header: PiSessionHeader, provider: string) {
  return {
    session_id: header.id,
    id: header.id,
    timestamp: header.timestamp,
    cwd: header.cwd,
    originator: "Pi",
    cli_version: "pi-codex-log-export/1",
    source: "cli",
    thread_source: "user",
    model_provider: codexProvider(provider),
    history_mode: "full",
  };
}

function turnContext(header: PiSessionHeader, model: string, provider: string) {
  return {
    turn_id: header.id,
    cwd: header.cwd,
    current_date: new Date(header.timestamp).toISOString().slice(0, 10),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    model,
    model_provider: codexProvider(provider),
    effort: null,
    summary: null,
    approval_policy: "never",
    sandbox_policy: { type: "danger-full-access" },
  };
}

export function buildCodexRecords(
  header: PiSessionHeader,
  entries: PiSessionEntry[],
) {
  let ordinal = 0;
  let cumulative = { ...ZERO_USAGE };
  let provider = "pi";
  let model = "unknown";
  const records: CodexRecord[] = [];

  const push = (
    timestamp: string,
    type: string,
    payload: Record<string, unknown>,
  ) => {
    records.push({ timestamp, type, payload, ordinal: ordinal++ });
  };

  const firstAssistant = entries.find(
    (entry) => entry.type === "message" && entry.message?.role === "assistant",
  )?.message;
  provider = firstAssistant?.provider ?? provider;
  model = firstAssistant?.model ?? model;

  push(header.timestamp, "session_meta", sessionMeta(header, provider));
  push(header.timestamp, "event_msg", {
    type: "task_started",
    turn_id: header.id,
  });
  push(header.timestamp, "turn_context", turnContext(header, model, provider));

  for (const entry of entries) {
    const timestamp = entry.timestamp ?? header.timestamp;
    if (entry.type === "model_change") {
      provider = entry.provider ?? provider;
      model = entry.modelId ?? model;
      push(timestamp, "turn_context", turnContext(header, model, provider));
      continue;
    }

    if (entry.type !== "message" || !entry.message) continue;
    const message = entry.message;
    const messageTimestamp = isoTimestamp(message, timestamp);

    if (message.role === "user") {
      push(messageTimestamp, "response_item", {
        type: "message",
        role: "user",
        content: [{ type: "input_text", text: textContent(message.content) }],
      });
      continue;
    }

    if (message.role === "toolResult") {
      push(messageTimestamp, "response_item", {
        type: "custom_tool_call_output",
        call_id: message.toolCallId ?? "unknown",
        output: contentOutput(textContent(message.content)),
      });
      continue;
    }

    if (message.role !== "assistant") continue;
    provider = message.provider ?? provider;
    model = message.model ?? model;
    push(
      messageTimestamp,
      "turn_context",
      turnContext(header, model, provider),
    );

    const blocks = Array.isArray(message.content) ? message.content : [];
    for (const block of blocks) {
      if (block.type === "thinking" && block.thinking) {
        push(messageTimestamp, "response_item", {
          type: "reasoning",
          summary: [{ type: "summary_text", text: block.thinking }],
          encrypted_content: null,
        });
      } else if (block.type === "text" && block.text) {
        push(messageTimestamp, "response_item", {
          type: "message",
          role: "assistant",
          phase: "final_answer",
          content: contentOutput(block.text),
        });
      } else if (block.type === "toolCall") {
        push(messageTimestamp, "response_item", {
          type: "custom_tool_call",
          id: block.id ?? "unknown",
          call_id: block.id ?? "unknown",
          name: block.name ?? "unknown",
          input: JSON.stringify(block.arguments ?? {}),
          status: "completed",
        });
      }
    }

    if (message.usage) {
      const last = toCodexUsage(message.usage);
      cumulative = addUsage(cumulative, last);
      push(messageTimestamp, "event_msg", {
        type: "token_count",
        info: {
          total_token_usage: cumulative,
          last_token_usage: last,
          model_context_window: null,
        },
        rate_limits: rateLimits(),
      });
    }
  }

  const finalTimestamp =
    [...entries].reverse().find((entry) => entry.timestamp)?.timestamp ??
    header.timestamp;
  push(finalTimestamp, "event_msg", {
    type: "task_complete",
    turn_id: header.id,
  });

  return records;
}

export function serializeRecords(records: CodexRecord[]) {
  return `${records.map((record) => JSON.stringify(record)).join("\n")}\n`;
}

export async function writeCodexSession(
  header: PiSessionHeader,
  entries: PiSessionEntry[],
  root = codexSessionsRoot(),
): Promise<ExportedSession> {
  const records = buildCodexRecords(header, entries);
  const outputPath = outputPathForSession(header, root);
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, serializeRecords(records), "utf8");
  return { header, records, outputPath };
}

export async function exportPiSessionFile(
  inputPath: string,
  root = codexSessionsRoot(),
) {
  const contents = await readFile(inputPath, "utf8");
  const { header, entries } = parsePiSessionJsonl(contents);
  return writeCodexSession(header, entries, root);
}
