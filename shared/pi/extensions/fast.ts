import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const STATE_TYPE = "codex-fast-mode";

export default function fastMode(pi: ExtensionAPI) {
  let enabled = false;

  function supportsFastMode(ctx: ExtensionContext) {
    return (
      ctx.model?.provider === "openai-codex" &&
      ctx.model.api === "openai-codex-responses"
    );
  }

  function updateStatus(ctx: ExtensionContext) {
    ctx.ui.setStatus(
      STATE_TYPE,
      enabled
        ? supportsFastMode(ctx)
          ? "fast: priority requested"
          : "fast: paused (not Codex)"
        : undefined,
    );
  }

  function restoreState(ctx: ExtensionContext) {
    enabled = false;
    for (const entry of ctx.sessionManager.getBranch()) {
      if (
        entry.type === "custom" &&
        entry.customType === STATE_TYPE &&
        typeof entry.data === "object" &&
        entry.data !== null &&
        "enabled" in entry.data &&
        typeof entry.data.enabled === "boolean"
      ) {
        enabled = entry.data.enabled;
      }
    }
    updateStatus(ctx);
  }

  pi.on("session_start", (_event, ctx) => restoreState(ctx));
  pi.on("session_tree", (_event, ctx) => restoreState(ctx));
  pi.on("model_select", (_event, ctx) => updateStatus(ctx));

  pi.on("before_provider_request", (event, ctx) => {
    if (
      !enabled ||
      !supportsFastMode(ctx) ||
      typeof event.payload !== "object" ||
      event.payload === null ||
      !("model" in event.payload) ||
      event.payload.model !== ctx.model?.id
    ) {
      return;
    }

    return { ...event.payload, service_tier: "priority" };
  });

  pi.registerCommand("fast", {
    description: "Toggle Codex priority processing: /fast [on|off|status]",
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase();
      if (!["", "on", "off", "status"].includes(action)) {
        ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
        return;
      }
      if (action === "status") {
        ctx.ui.notify(
          `Fast mode is ${enabled ? "on" : "off"}${enabled && !supportsFastMode(ctx) ? " (paused: select a Codex model)" : ""}.`,
          "info",
        );
        return;
      }

      const nextEnabled = action === "" ? !enabled : action === "on";
      if (nextEnabled && !supportsFastMode(ctx)) {
        ctx.ui.notify("Fast mode requires an openai-codex model.", "warning");
        return;
      }

      enabled = nextEnabled;
      pi.appendEntry(STATE_TYPE, { enabled });
      updateStatus(ctx);
      ctx.ui.notify(
        enabled
          ? "Fast mode on: requesting priority processing. May use your allowance faster; thinking level is unchanged."
          : "Fast mode off: using normal processing.",
        "info",
      );
    },
  });
}
