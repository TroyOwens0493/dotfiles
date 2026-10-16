import {
  type ExtensionAPI,
  SettingsManager,
} from "@earendil-works/pi-coding-agent";

export default function rememberModel(pi: ExtensionAPI) {
  pi.on("model_select", async (event, ctx) => {
    // Restored sessions and background agents must not replace the user's choice.
    if (ctx.mode !== "tui" || event.source === "restore") return;

    const settings = SettingsManager.create(ctx.cwd, undefined, {
      projectTrusted: false,
    });
    settings.setDefaultModelAndProvider(event.model.provider, event.model.id);
    await settings.flush();

    for (const { error } of settings.drainErrors()) {
      ctx.ui.notify(`Could not remember model: ${error.message}`, "warning");
    }
  });
}
