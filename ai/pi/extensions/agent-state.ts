/**
 * Agent State - report this pi session's state to ,agent-state.
 *
 * The pi counterpart to ai/claude/hooks/agent-state.sh: records blocked,
 * working, and idle into the SQLite database keyed by tmux pane, so the
 * ,agents picker (prefix+A) and the sketchybar agents item rank pi sessions
 * alongside Claude Code ones.
 *
 *   agent_start             -> working
 *   agent_settled (isIdle)  -> idle, "turn finished"
 *   session_start           -> republish current state (reload-safe)
 *   session_shutdown        -> clear the pane's row
 *
 * pi has no built-in permission prompt, so blocked arrives on the shared
 * event bus: permission-gate.ts emits "agent-state:blocked" around its
 * dialogs. Those are modal and every open is paired with a close, so a
 * boolean tracks it.
 *
 * Writes are fire-and-forget through a serial queue. Ordering matters
 * (the clear that /resume fires must land before the session_start record
 * that follows it), and a dropped write only means a stale row until the
 * next event.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { join } from "node:path";

const STATE_SCRIPT = join(process.env.HOME ?? "", ".dotfiles/ai/bin/,agent-state");

// Runs after each write, matching the Claude hook: pushes the new state at
// sketchybar's agents item instead of leaving it to poll. Resolved through
// sh with the Homebrew fallback because the spawn may not carry brew's PATH.
const TRIGGER_SKETCHYBAR = [
	"sketchybar_bin=$(command -v sketchybar) || sketchybar_bin=/opt/homebrew/opt/sketchybar/bin/sketchybar",
	"[ -x \"$sketchybar_bin\" ] && \"$sketchybar_bin\" --trigger agent_state_change >/dev/null 2>&1 || true",
].join("; ");

type AgentState = "blocked" | "working" | "idle";

interface BlockedEvent {
	active: boolean;
	label?: string;
}

export default function (pi: ExtensionAPI) {
	// The pane is the row's identity, so outside tmux there is nothing to
	// record. ,agent-state reads TMUX_PANE itself and no-ops without it.
	if (!process.env.TMUX_PANE) return;

	// TUI only: RPC/JSON/print modes are headless, and RPC still reports
	// hasUI=true, so mode is the reliable gate. Set once at session_start;
	// every other handler checks it.
	let interactive = false;
	let cwd = process.cwd();

	let agentActive = false;
	let blocked = false;
	let blockedMessage: string | undefined;
	let lastState: AgentState | undefined;
	let lastMessage: string | undefined;

	let queue: Promise<void> = Promise.resolve();

	function run(command: string, args: string[]): Promise<void> {
		const task = queue.then(async () => {
			try {
				const result = await pi.exec(command, args, { timeout: 5000 });
				if (result.code !== 0) return;
				if (command === STATE_SCRIPT) {
					await pi.exec("/bin/sh", ["-c", TRIGGER_SKETCHYBAR]);
				}
			} catch {
				// Never surface state-tracking failures into the session.
			}
		});
		queue = task;
		return task;
	}

	function desired(): { state: AgentState; message?: string } {
		if (blocked) return { state: "blocked", message: blockedMessage };
		if (agentActive) return { state: "working" };
		return { state: "idle", message: "turn finished" };
	}

	function publish(force = false): void {
		const next = desired();
		if (!force && next.state === lastState && next.message === lastMessage) return;
		lastState = next.state;
		lastMessage = next.message;
		void run(STATE_SCRIPT, ["record", next.state, cwd, next.message ?? ""]);
	}

	pi.events.on("agent-state:blocked", (data) => {
		if (!interactive) return;
		const event = data as BlockedEvent;

		blocked = event.active;
		blockedMessage = event.active ? event.label : undefined;
		publish();
	});

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		interactive = true;
		cwd = ctx.cwd;
		// A reload can replace this extension mid-run without another
		// agent_start, so re-derive activity from the session itself.
		agentActive = ctx.isIdle() === false;
		publish(true);
	});

	pi.on("agent_start", async () => {
		if (!interactive) return;
		agentActive = true;
		publish();
	});

	pi.on("agent_settled", async (_event, ctx) => {
		// Not settled if another extension started a new run, or if
		// auto-retry/compaction is still queued.
		if (!interactive || ctx.isIdle() !== true) return;
		agentActive = false;
		publish();
	});

	pi.on("session_shutdown", async () => {
		if (!interactive) return;
		void run(STATE_SCRIPT, ["clear"]);
	});
}
