export type AgentState = "blocked" | "working" | "done";
export type BlockedKind = "permission" | "question";

export type StateRecord = {
	state: AgentState;
	cwd: string;
	kind?: BlockedKind;
	message?: string;
};

export const stateScript = (home: string) => `${home}/.dotfiles/ai/bin/,agent-state`;

export function recordArguments(record: StateRecord): string[] {
	const args = ["record", "--app", "claude-code"];
	if (record.kind !== undefined) args.push("--kind", record.kind);
	args.push(record.state, record.cwd, record.message ?? "");
	return args;
}

export function permissionRequest(tool: string | undefined, cwd: string): StateRecord {
	return { state: "blocked", kind: "permission", cwd, message: tool ?? "" };
}

export function questionRequest(cwd: string): StateRecord {
	return { state: "blocked", kind: "question", cwd };
}

export function working(cwd: string): StateRecord {
	return { state: "working", cwd };
}

export function done(cwd: string): StateRecord {
	return { state: "done", cwd, message: "turn finished" };
}

export function isPrimaryAgent(agentId: string | undefined): boolean {
	return agentId === undefined || agentId === "";
}
