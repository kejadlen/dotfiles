/**
 * Permission Gate Extension
 *
 * Requires explicit user confirmation before every tool call.
 * Shows tool name and a summary of the arguments, then asks to allow or block.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (!ctx.hasUI) return;

		const summary = formatArgs(event.toolName, event.input);
		const allowed = await ctx.ui.confirm(event.toolName, summary);

		if (!allowed) {
			return { block: true, reason: "Blocked by user" };
		}
	});
}

function formatArgs(toolName: string, input: Record<string, unknown>): string {
	switch (toolName) {
		case "bash":
			return `$ ${input.command}`;
		case "read":
			return `${input.path}` + (input.offset ? ` (offset ${input.offset})` : "");
		case "write":
			return `${input.path} (${String(input.content ?? "").length} chars)`;
		case "edit":
			return `${input.path}`;
		default: {
			const keys = Object.keys(input);
			if (keys.length === 0) return "(no arguments)";
			return keys.map((k) => `${k}: ${truncate(String(input[k]), 80)}`).join("\n");
		}
	}
}

function truncate(s: string, max: number): string {
	if (s.length <= max) return s;
	return s.slice(0, max) + "…";
}
