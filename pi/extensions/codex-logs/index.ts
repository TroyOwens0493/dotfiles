import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  coercePiMessage,
  coercePiSessionEntry,
  type PiMessage,
  type PiSessionEntry,
  writeCodexSession,
} from "./src/codex-log.ts";

function messageIdentity(message: PiMessage) {
  return [
    message.role,
    message.timestamp ?? "",
    message.toolCallId ?? "",
    message.model ?? "",
  ].join(":");
}

function snapshotEntries(ctx: ExtensionContext, pendingMessage?: PiMessage) {
  const entries = ctx.sessionManager
    .getEntries()
    .map((entry) => coercePiSessionEntry(entry))
    .filter((entry): entry is PiSessionEntry => entry !== undefined);

  if (
    pendingMessage &&
    !entries.some(
      (entry) =>
        entry.message &&
        messageIdentity(entry.message) === messageIdentity(pendingMessage),
    )
  ) {
    entries.push({
      type: "message",
      timestamp:
        pendingMessage.timestamp === undefined
          ? new Date().toISOString()
          : new Date(pendingMessage.timestamp).toISOString(),
      message: pendingMessage,
    });
  }

  return entries;
}

export default function codexLogs(pi: ExtensionAPI) {
  let writes = Promise.resolve();
  let lastOutputPath: string | undefined;

  function rewrite(ctx: ExtensionContext, pendingMessage?: PiMessage) {
    const header = ctx.sessionManager.getHeader();
    if (!header) return;
    const entries = snapshotEntries(ctx, pendingMessage);

    writes = writes
      .then(async () => {
        const result = await writeCodexSession(header, entries);
        lastOutputPath = result.outputPath;
      })
      .catch((error: unknown) => {
        console.error("[codex-logs] Failed to write compatibility log:", error);
      });
  }

  pi.on("session_start", (_event, ctx) => rewrite(ctx));

  pi.on("message_end", (event, ctx) => {
    const message = coercePiMessage(event.message);
    if (message) rewrite(ctx, message);
  });

  pi.on("session_shutdown", async () => {
    await writes;
  });

  pi.registerCommand("codex-log", {
    description: "Rewrite and show the current Codex-compatible Pi session log",
    handler: async (_args, ctx) => {
      rewrite(ctx);
      await writes;
      if (lastOutputPath) {
        ctx.ui.notify(`Codex-compatible log: ${lastOutputPath}`, "info");
      } else {
        ctx.ui.notify(
          "This session has no persistent header to export.",
          "warning",
        );
      }
    },
  });
}
