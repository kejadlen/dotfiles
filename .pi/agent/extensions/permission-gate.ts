/**
 * Permission Gate Extension
 *
 * Requires explicit user confirmation before every tool call.
 * Auto-allows read-only operations (read tool, non-destructive jj commands).
 * Auto-allows reading from tracked files and skills directories.
 * Shows tool name and a summary of the arguments, then asks to allow or block.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import * as path from "node:path";
import * as fs from "node:fs";
import * as os from "node:os";

const ALLOWED_JJ_SUBCOMMANDS = ["diff", "log", "show", "status"];

let trackedFiles: Set<string> | null = null;
let skillsDirs: string[] | null = null;

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

function getSkillsDirectories(cwd: string): string[] {
	if (skillsDirs) return skillsDirs;
	try {
		const settingsPath = path.join(cwd, ".pi", "agent", "settings.json");
		const settings = JSON.parse(fs.readFileSync(settingsPath, "utf-8"));
		skillsDirs = (settings.skills || []).map((skillPath: string) => {
			// Handle ~ expansion
			if (skillPath.startsWith("~/")) {
				return path.resolve(os.homedir(), skillPath.slice(2));
			}
			return path.resolve(cwd, skillPath);
		});
	} catch {
		skillsDirs = [];
	}
	return skillsDirs;
}

function isInSkillsDirectory(filePath: string, cwd: string): boolean {
	const skillsDirs = getSkillsDirectories(cwd);
	return skillsDirs.some(skillsDir => filePath.startsWith(skillsDir + path.sep));
}

function isAllowed(toolName: string, input: Record<string, unknown>, cwd: string): boolean {
	if (toolName === "read") {
		const filePath = path.resolve(cwd, String(input.path ?? ""));
		return getTrackedFiles(cwd).has(filePath) || isInSkillsDirectory(filePath, cwd);
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
		if (event.toolName === "write" || event.toolName === "edit") {
			const filePath = String(event.input.path ?? "");
			if (filePath.includes("settings.json")) {
				skillsDirs = null;
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
