import { openaiCodexProvider } from "@earendil-works/pi-ai/providers/openai-codex";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CLI_PROXY_API_KEY_COMMAND =
  '!/usr/bin/ruby -ryaml -e \'puts YAML.load_file(File.join(Dir.home, ".cli-proxy-api/merged-config.yaml")).fetch("api-keys").first\'';

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

/** Registers distinct names for the Codex subscription and CLIProxyAPI routes. */
export default function modelProviders(pi: ExtensionAPI) {
  pi.registerProvider({
    ...codexProvider,
    id: "openai",
    name: "OpenAI (Codex account)",
    /** Returns the Codex catalog under the shorter OpenAI provider prefix. */
    getModels() {
      return [
        ...codexProvider.getModels().map((model) => ({
          ...model,
          provider: "openai",
        })),
        gpt6Astra,
      ];
    },
  });

  pi.registerProvider("cli-proxy-api", {
    name: "CLIProxyAPI",
    baseUrl: "http://127.0.0.1:8317/v1",
    apiKey: CLI_PROXY_API_KEY_COMMAND,
    api: "openai-responses",
    models: [
      "gpt-5.5",
      "gpt-5.6-luna",
      "gpt-5.6-sol",
      "gpt-5.6-terra",
      "gpt-6-astra",
    ].map((id) => ({
      id,
      name: id,
      reasoning: true,
      input: ["text", "image"] as ("text" | "image")[],
      contextWindow: 272_000,
      maxTokens: 128_000,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      thinkingLevelMap: {
        off: "none",
        low: "low",
        medium: "medium",
        high: "high",
        xhigh: "xhigh",
        max: "max",
      },
      compat: {
        supportsStrictMode: true,
        supportsOpenAIGrammarTools: true,
        supportsAdditionalTools: true,
        supportsToolSearch: true,
        supportsMidConvoSystemMessages: true,
      },
    })),
  });
}
