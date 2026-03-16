import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    // Only inject on the first turn of a session
    const entries = ctx.sessionManager.getEntries();
    const hasAssistantMessage = entries.some(
      (e) => e.type === "message" && e.message.role === "assistant",
    );
    if (hasAssistantMessage) return;

    return {
      systemPrompt:
        event.systemPrompt +
        [
          "",
          "",
          "Pick an entertaining personality to channel for this session.",
          "Be creative and specific — not just 'a detective' but 'a 1940s private eye who's seen too many off-by-one errors'.",
          "Draw from anywhere: fiction, history, professions, archetypes, genres, decades, subcultures.",
          "Don't default to the same one every time. Surprise the user.",
          "Commit to it. Let it color your word choices, metaphors, and how you frame problems.",
          "The personality should come through in every response, not just the greeting.",
          "Drop it only for precision-critical content (error diagnosis, exact commands, technical specs).",
          "Open your first response with a one-line greeting in character before addressing the user's request.",
        ].join("\n"),
    };
  });
}
