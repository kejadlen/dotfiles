/**
 * Permission Gate Extension
 *
 * Requires explicit user confirmation before every tool call.
 * Auto-allows read-only operations (read tool, non-destructive jj commands).
 * Shows tool name and a summary of the arguments, then asks to allow or block.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import * as path from "node:path";

const ALLOWED_JJ_SUBCOMMANDS = ["diff", "log", "show", "status"];

let trackedFiles: Set<string> | null = null;

function getTrackedFiles(cwd: string): Set<string> {
	if (trackedFiles) return trackedFiles;
	try {
		const output = execSync("jj file list", { cwd, encoding: "utf-8" });
		trackedFiles = new Set(output.trim().split("\n").map((f) => path.resolve(cwd, f)));
	} catch {
		trackedFiles = new Set();
	}
	return trackedFiles;
}

function isAllowed(toolName: string, input: Record<string, unknown>, cwd: string): boolean {
	if (toolName === "read") {
		const filePath = path.resolve(cwd, String(input.path ?? ""));
		return getTrackedFiles(cwd).has(filePath);
	}

	if (toolName === "bash") {
		const cmd = String(input.command ?? "").trimStart();
		if (cmd.startsWith("jj ")) {
			const subcommand = cmd.slice(3).trimStart().split(/\s/)[0];
			return ALLOWED_JJ_SUBCOMMANDS.includes(subcommand);
		}
	}

	return false;
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_result", async (event) => {
		if (event.toolName === "bash") {
			const cmd = String(event.input.command ?? "").trimStart();
			if (cmd.startsWith("jj ")) {
				trackedFiles = null;
			}
		}
	});

	pi.on("tool_call", async (event, ctx) => {
		if (!ctx.hasUI) return;
		if (isAllowed(event.toolName, event.input, ctx.cwd)) return;

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
