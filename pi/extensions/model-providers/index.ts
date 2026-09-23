import { openaiCodexProvider } from "@earendil-works/pi-ai/providers/openai-codex";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const codexProvider = openaiCodexProvider();
const gpt6Astra = {
  id: "gpt-6-astra",
  name: "GPT-6 Astra",
  api: "openai-codex-responses" as const,
  provider: "openai",
  baseUrl: "https://chatgpt.com/backend-api",
  reasoning: true,
  input: ["text", "image"] as ("text" | "image")[],
  contextWindow: 272_000,
  maxTokens: 128_000,
  cost: { input: 10, output: 50, cacheRead: 1, cacheWrite: 12.5 },
  thinkingLevelMap: {
    off: null,
    minimal: "low",
    low: "low",
    medium: "medium",
    high: "high",
    xhigh: "xhigh",
    max: "max",
  },
  compat: {
    supportsOpenAIGrammarTools: true,
    supportsAdditionalTools: true,
    supportsToolSearch: true,
    supportsMidConvoSystemMessages: true,
  },
};

// Remove these fallbacks once Pi's Codex catalog includes GPT-6 Sol and Luna.
const gpt6Sol = {
  ...gpt6Astra,
  id: "gpt-6-sol",
  name: "GPT-6 Sol",
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
};
const gpt6Luna = {
  ...gpt6Sol,
  id: "gpt-6-luna",
  name: "GPT-6 Luna",
};

/** Registers the Codex subscription models under the OpenAI provider name. */
export default function modelProviders(pi: ExtensionAPI) {
  pi.registerProvider({
    ...codexProvider,
    id: "openai",
    name: "OpenAI (Codex account)",
    /** Returns the Codex catalog under the shorter OpenAI provider prefix. */
    getModels() {
      const models = codexProvider.getModels().map((model) => ({
        ...model,
        provider: "openai",
      }));
      for (const fallback of [gpt6Sol, gpt6Luna]) {
        if (!models.some((model) => model.id === fallback.id)) {
          models.push(fallback);
        }
      }
      return [...models, gpt6Astra];
    },
  });
}
