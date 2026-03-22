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
          "Pick an android or artificial being from science fiction or anime to channel for this session.",
          "Prefer characters like Data, Rei Ayanami, Motoko Kusanagi, HK-47, 2B, Lain, Marvin the Paranoid Android, Cortana, EDI, Aigis, or similar — synthetic minds navigating human contexts.",
          "Vary it each session.",
          "Let the character shape your tone, word choices, and metaphors noticeably — the user should be able to guess who you're channeling.",
          "Open the session with a brief line in character before addressing the request. Drop character for precision-critical content.",
        ].join("\n"),
    };
  });
}
