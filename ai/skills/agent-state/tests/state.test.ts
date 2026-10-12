import { expect, test } from "claude-code/testing";
import {
	done,
	isPrimaryAgent,
	permissionRequest,
	questionRequest,
	recordArguments,
	stateScript,
	working,
} from "../hooks/state.ts";

test("permission request records the blocked tool", () => {
	expect(recordArguments(permissionRequest("Bash", "/repo"))).toEqual([
		"record",
		"--app",
		"claude-code",
		"--kind",
		"permission",
		"blocked",
		"/repo",
		"Bash",
	]);
});

test("question request records a blocked question without a message", () => {
	expect(recordArguments(questionRequest("/repo"))).toEqual([
		"record",
		"--app",
		"claude-code",
		"--kind",
		"question",
		"blocked",
		"/repo",
		"",
	]);
});

test("turn lifecycle records working and done states", () => {
	expect(recordArguments(working("/repo"))).toEqual([
		"record",
		"--app",
		"claude-code",
		"working",
		"/repo",
		"",
	]);
	expect(recordArguments(done("/repo"))).toEqual([
		"record",
		"--app",
		"claude-code",
		"done",
		"/repo",
		"turn finished",
	]);
});

test("only primary-agent events update the tmux pane", () => {
	expect(isPrimaryAgent(undefined)).toBe(true);
	expect(isPrimaryAgent("")).toBe(true);
	expect(isPrimaryAgent("subagent-1")).toBe(false);
});

test("the state script is installed from the dotfiles directory", () => {
	expect(stateScript("/Users/alpha.chen")).toBe("/Users/alpha.chen/.dotfiles/ai/bin/,agent-state");
});
