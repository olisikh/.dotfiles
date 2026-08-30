/* @ts-expect-error Pi provides this module to extensions at runtime. */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ProviderRequestEvent = {
  payload: object;
};

type ProviderRequestContext = {
  model?: {
    provider: string;
    id: string;
  } | null;
};

const CONTEXT_VARIANT_SUFFIX = "-900k";
const SUPPORTED_PROVIDERS = new Set(["openai", "openai-codex"]);
const GPT56_MODELS = new Set(["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"]);

export default function openaiContextVariants(pi: ExtensionAPI): void {
  pi.on(
    "before_provider_request",
    (event: ProviderRequestEvent, ctx: ProviderRequestContext) => {
      const model = ctx.model;
      if (!model || !SUPPORTED_PROVIDERS.has(model.provider)) return;
      if (!model.id.endsWith(CONTEXT_VARIANT_SUFFIX)) return;

      const baseModel = model.id.slice(0, -CONTEXT_VARIANT_SUFFIX.length);
      if (!GPT56_MODELS.has(baseModel)) return;

      return { ...event.payload, model: baseModel };
    },
  );
}
