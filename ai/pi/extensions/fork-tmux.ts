/**
 * Fork Tmux - Fork the current session into a new tmux pane, window, or popup.
 *
 * Creates a branched copy of the current session and opens it
 * in a new tmux target, leaving the current session untouched.
 *
 * Usage:
 *   /fork-tmux              Popup (tmux 3.3+)
 *   /fork-tmux 80%x80%     Popup with size
 *   /fork-tmux -h           Horizontal split (right)
 *   /fork-tmux -v           Vertical split (below)
 *   /fork-tmux -w           New window
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type Mode = "split-h" | "split-v" | "window" | "popup";

function parseArgs(raw: string): { mode: Mode; extra: string[] } {
	const parts = raw.trim().split(/\s+/).filter(Boolean);
	let mode: Mode = "popup";
	const extra: string[] = [];

	for (const p of parts) {
		if (p === "-h") mode = "split-h";
		else if (p === "-v") mode = "split-v";
		else if (p === "-w") mode = "window";
		else extra.push(p);
	}

	return { mode, extra };
}

function shellEscape(s: string): string {
	return "'" + s.replace(/'/g, "'\\''") + "'";
}

function findPi(): string {
	// Resolve full path to pi so it works in minimal shell environments (e.g. tmux popups)
	try {
		const { execSync } = require("node:child_process");
		return execSync("which pi", { encoding: "utf-8" }).trim();
	} catch {
		return "pi";
	}
}

function buildShellCommand(mode: Mode, extra: string[], sessionFile: string): string {
	const piCmd = `${findPi()} --session ${shellEscape(sessionFile)}`;

	switch (mode) {
		case "split-h":
			return `tmux split-window -h -- ${piCmd}`;
		case "split-v":
			return `tmux split-window -v -- ${piCmd}`;
		case "window":
			return `tmux new-window -- ${piCmd}`;
		case "popup": {
			const sizeArgs: string[] = [];
			if (extra[0]) {
				const [w, h] = extra[0].split("x");
				if (w) sizeArgs.push(`-w ${w}`);
				if (h) sizeArgs.push(`-h ${h}`);
			}
			return `tmux display-popup -E ${sizeArgs.join(" ")} -- ${piCmd}`;
		}
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("fork-tmux", {
		description: "Fork session into a tmux popup (default), pane (-h, -v), or window (-w)",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("fork-tmux requires interactive mode", "error");
				return;
			}

			if (!process.env.TMUX) {
				ctx.ui.notify("Not inside a tmux session", "error");
				return;
			}

			const sessionFile = ctx.sessionManager.getSessionFile();
			if (!sessionFile) {
				ctx.ui.notify("No session file (ephemeral session)", "error");
				return;
			}

			const leafId = ctx.sessionManager.getLeafId();
			if (!leafId) {
				ctx.ui.notify("No entries to fork from", "error");
				return;
			}

			const newSessionFile = ctx.sessionManager.createBranchedSession(leafId);
			if (!newSessionFile) {
				ctx.ui.notify("Failed to create branched session", "error");
				return;
			}

			const { mode, extra } = parseArgs(args);
			const cmd = buildShellCommand(mode, extra, newSessionFile);

			const result = await pi.exec("bash", ["-c", cmd]);
			if (result.code !== 0) {
				ctx.ui.notify(`tmux failed (exit ${result.code}): ${result.stderr || result.stdout || "(no output)"}`, "error");
				return;
			}

			const labels: Record<Mode, string> = {
				"split-h": "pane (right)",
				"split-v": "pane (below)",
				"window": "window",
				"popup": "popup",
			};
			ctx.ui.notify(`Forked into new ${labels[mode]}`, "success");
		},
	});
}
