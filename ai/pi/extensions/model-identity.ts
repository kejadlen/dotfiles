/**
 * Model Identity Extension
 *
 * Replaces the default Claude Code identity in the system prompt and
 * injects the current model name so the model knows what it's running
 * as (useful for Assisted-by footers, etc.)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    const model = ctx.model;
    let prompt = event.systemPrompt;

    // Replace the Claude Code identity preamble
    prompt = prompt.replace(
      /You are Claude Code, Anthropic.s official CLI for Claude\.\s*/,
      "",
    );

    prompt += `\n\nYou are running as: ${model.name} (${model.provider}/${model.id}) via pi`;

    return { systemPrompt: prompt };
  });
}
