/**
 * Model Identity Extension
 *
 * Injects the current model name into the system prompt so the model
 * knows what it's running as (useful for Assisted-by footers, etc.)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    const model = ctx.model;
    return {
      systemPrompt: event.systemPrompt + `\n\nYou are running as: ${model.provider}/${model.id}`,
    };
  });
}
