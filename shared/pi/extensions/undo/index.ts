import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PREVIEW_LENGTH = 100;

type UserPrompt = {
  id: string;
  content: unknown;
};

export function previewUserContent(content: unknown) {
  const text =
    typeof content === "string"
      ? content
      : Array.isArray(content)
        ? content
            .map((block) => {
              if (!block || typeof block !== "object" || !("type" in block)) {
                return "";
              }

              if (
                block.type === "text" &&
                "text" in block &&
                typeof block.text === "string"
              ) {
                return block.text;
              }

              return block.type === "image" ? "[image]" : "";
            })
            .filter(Boolean)
            .join(" ")
        : "";

  const normalized = text.replace(/\s+/g, " ").trim() || "[empty prompt]";
  return normalized.length > PREVIEW_LENGTH
    ? `${normalized.slice(0, PREVIEW_LENGTH - 1)}…`
    : normalized;
}

export function createUndoChoices(prompts: UserPrompt[]) {
  return prompts
    .map((prompt, index) => ({
      id: prompt.id,
      label: `${index + 1}. ${previewUserContent(prompt.content)}`,
    }))
    .reverse();
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("undo", {
    description: "Rewind the conversation to an earlier prompt",
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();

      const prompts = ctx.sessionManager.getBranch().flatMap((entry) => {
        if (entry.type !== "message" || entry.message.role !== "user") {
          return [];
        }

        return [{ id: entry.id, content: entry.message.content }];
      });

      const choices = createUndoChoices(prompts);
      if (choices.length === 0) {
        ctx.ui.notify("There are no prompts to rewind to", "info");
        return;
      }

      const selectedLabel = await ctx.ui.select(
        "Rewind conversation to which prompt?",
        choices.map(({ label }) => label),
      );
      const selected = choices.find(({ label }) => label === selectedLabel);
      if (!selected) return;

      await ctx.navigateTree(selected.id, { summarize: false });
    },
  });
}
