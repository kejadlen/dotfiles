import type { EngineInterface, Register } from "claude-code";
import {
	done,
	isPrimaryAgent,
	permissionRequest,
	questionRequest,
	recordArguments,
	stateScript,
	working,
	type StateRecord,
} from "./state.ts";

const sketchybarTrigger = [
	"sketchybar_bin=$(command -v sketchybar) || sketchybar_bin=/opt/homebrew/opt/sketchybar/bin/sketchybar",
	'[ -x "$sketchybar_bin" ] && "$sketchybar_bin" --trigger agent_state_change >/dev/null 2>&1 || true',
].join("; ");

async function cwd($: EngineInterface): Promise<string> {
	return $.session.cwd();
}

async function triggerSketchybar($: EngineInterface): Promise<void> {
	await $.process.run(["/bin/sh", "-c", sketchybarTrigger], { timeoutMs: 5000 });
}

async function publish($: EngineInterface, record: StateRecord): Promise<void> {
	const [pane, home] = await Promise.all([$.env.get("TMUX_PANE"), $.env.get("HOME")]);
	if (pane === undefined || pane === "" || home === undefined || home === "") return;

	try {
		await $.process.run([stateScript(home), ...recordArguments(record)], { timeoutMs: 5000 });
		await triggerSketchybar($);
	} catch {
		// State tracking must not disrupt the Claude session.
	}
}

async function clear($: EngineInterface): Promise<void> {
	const [pane, home] = await Promise.all([$.env.get("TMUX_PANE"), $.env.get("HOME")]);
	if (pane === undefined || pane === "" || home === undefined || home === "") return;

	try {
		await $.process.run([stateScript(home), "clear"], { timeoutMs: 5000 });
		await triggerSketchybar($);
	} catch {
		// State tracking must not disrupt the Claude session.
	}
}

export const register: Register = on => {
	let writes: Promise<void> = Promise.resolve();
	const enqueue = (operation: () => Promise<void>) => {
		writes = writes.then(operation, operation).catch(() => undefined);
		return writes;
	};
	on("turn.start", async ($, event, next) => {
		if (isPrimaryAgent(event.agentId)) await enqueue(async () => publish($, working(await cwd($))));
		return next(event);
	});

	on("turn.complete", async ($, event, next) => {
		if (isPrimaryAgent(event.agentId)) await enqueue(async () => publish($, done(await cwd($))));
		return next(event);
	});

	on("tool.call", { tool: "AskUserQuestion" }, async ($, event, next) => {
		if (isPrimaryAgent(event.agentId)) await enqueue(async () => publish($, questionRequest(await cwd($))));
		return next(event);
	}).catch(($, event, next) => next(event));

	on("classic.PermissionRequest", async ($, event, next) => {
		if (isPrimaryAgent(event.agent_id)) {
			await enqueue(async () => publish($, permissionRequest(event.tool_name, await cwd($))));
		}
		return next(event);
	}).catch(($, event, next) => next(event));

	on("classic.PermissionDenied", async ($, event, next) => {
		if (isPrimaryAgent(event.agent_id)) await enqueue(async () => publish($, working(await cwd($))));
		return next(event);
	}).catch(($, event, next) => next(event));

	on("session.end", async ($, event, next) => {
		await enqueue(() => clear($));
		return next(event);
	});
};
