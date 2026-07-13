/**
 * Session Blurb - keep the tmux pane title describing the current session.
 *
 * Once pi settles after the first real exchange, a cheap side model
 * condenses the conversation into a 3-6 word blurb and stores it as the
 * session name. Pi renders the session name into the terminal title as
 * `<APP> - <blurb> - <cwd>`, which tmux picks up as the pane title
 * (shown via pane-border-format).
 *
 * The blurb is set once per session and then left alone. A session that
 * already has a name (e.g. set via `/name`) is never touched.
 */

import { complete, getModel } from "@mariozechner/pi-ai/compat";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

// --- Configuration ---------------------------------------------------------

const MODEL_PROVIDER = "anthropic";
const MODEL_ID = "claude-haiku-4-5";
const MAX_WORDS = 6;
const MAX_CHARS = 40;
// Cap how much transcript we send to the summarizer. The tail carries the
// most relevant "what's happening now" signal, so we keep the last N chars.
const MAX_TRANSCRIPT_CHARS = 6000;

const PROMPT_PREAMBLE = [
	`Summarize what this coding session is about in ${MAX_WORDS} words or fewer.`,
	"Write a terse noun phrase, no punctuation, no quotes, lowercase unless a",
	"proper noun. Describe the task, not the assistant. Reply with only the phrase.",
	"",
	"<conversation>",
].join("\n");

// --- Transcript extraction (mirrors the summarize.ts example) --------------

type ContentBlock = {
	type?: string;
	text?: string;
	name?: string;
};

type SessionEntry = {
	type: string;
	message?: {
		role?: string;
		content?: unknown;
	};
};

function extractText(content: unknown): string[] {
	if (typeof content === "string") return [content];
	if (!Array.isArray(content)) return [];

	const parts: string[] = [];
	for (const part of content) {
		if (!part || typeof part !== "object") continue;
		const block = part as ContentBlock;
		if (block.type === "text" && typeof block.text === "string") {
			parts.push(block.text);
		}
	}
	return parts;
}

function extractToolNames(content: unknown): string[] {
	if (!Array.isArray(content)) return [];

	const names: string[] = [];
	for (const part of content) {
		if (!part || typeof part !== "object") continue;
		const block = part as ContentBlock;
		if (block.type === "toolCall" && typeof block.name === "string") {
			names.push(`(used ${block.name})`);
		}
	}
	return names;
}

function buildTranscript(entries: SessionEntry[]): string {
	const sections: string[] = [];

	for (const entry of entries) {
		const role = entry.type === "message" ? entry.message?.role : undefined;
		if (role !== "user" && role !== "assistant") continue;

		const lines: string[] = [];
		const text = extractText(entry.message?.content).join("\n").trim();
		if (text) lines.push(`${role === "user" ? "User" : "Assistant"}: ${text}`);
		if (role === "assistant") lines.push(...extractToolNames(entry.message?.content));

		if (lines.length > 0) sections.push(lines.join("\n"));
	}

	const full = sections.join("\n\n");
	return full.length > MAX_TRANSCRIPT_CHARS ? full.slice(-MAX_TRANSCRIPT_CHARS) : full;
}

function countExchange(entries: SessionEntry[]): { users: number; assistants: number } {
	let users = 0;
	let assistants = 0;
	for (const entry of entries) {
		if (entry.type !== "message") continue;
		if (entry.message?.role === "user") users++;
		else if (entry.message?.role === "assistant") assistants++;
	}
	return { users, assistants };
}

// --- Blurb sanitizing ------------------------------------------------------

function sanitizeBlurb(raw: string): string | undefined {
	// Take the first non-empty line, drop surrounding quotes/backticks and
	// trailing punctuation, collapse whitespace, and clamp length.
	const firstLine = raw
		.split("\n")
		.map((l) => l.trim())
		.find((l) => l.length > 0);
	if (!firstLine) return undefined;

	let blurb = firstLine
		.replace(/^[\s"'`*_]+/, "")
		.replace(/[\s"'`*_.,;:!?]+$/, "")
		.replace(/\s+/g, " ")
		.trim();

	if (!blurb) return undefined;

	const words = blurb.split(" ");
	if (words.length > MAX_WORDS) blurb = words.slice(0, MAX_WORDS).join(" ");
	if (blurb.length > MAX_CHARS) blurb = blurb.slice(0, MAX_CHARS).trimEnd();

	return blurb || undefined;
}

// --- Extension -------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	// Closure state, reset naturally when extensions reload on session switch.
	let blurbSet = false;
	let generating = false;

	async function generateBlurb(transcript: string, ctx: ExtensionContext): Promise<string | undefined> {
		const model = getModel(MODEL_PROVIDER, MODEL_ID);
		if (!model) return undefined;

		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (!auth?.ok || !auth.apiKey) return undefined;

		const response = await complete(
			model,
			{
				messages: [
					{
						role: "user" as const,
						content: [{ type: "text" as const, text: `${PROMPT_PREAMBLE}\n${transcript}\n</conversation>` }],
						timestamp: Date.now(),
					},
				],
			},
			{ apiKey: auth.apiKey, headers: auth.headers, env: auth.env },
		);

		const text = response.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join("\n");

		return sanitizeBlurb(text);
	}

	pi.on("agent_settled", async (_event, ctx) => {
		// Terminal title only matters in the interactive TUI.
		if (ctx.mode !== "tui") return;
		// Set the blurb once per session; keep retrying only until one lands.
		if (blurbSet || generating) return;

		const entries = ctx.sessionManager.getBranch() as SessionEntry[];

		// Need at least one real exchange before a blurb means anything.
		const { users, assistants } = countExchange(entries);
		if (users < 1 || assistants < 1) return;

		// Respect a manually chosen name: if the session is already named,
		// leave it and never set a blurb for this session.
		if (pi.getSessionName()) {
			blurbSet = true;
			return;
		}

		const transcript = buildTranscript(entries);
		if (!transcript.trim()) return;

		generating = true;
		try {
			const blurb = await generateBlurb(transcript, ctx);
			if (blurb) {
				pi.setSessionName(blurb);
				blurbSet = true;
			}
			// On an empty/failed result, leave blurbSet false so the next
			// settle retries; a successful set stops all future attempts.
		} catch {
			// Never surface summarizer failures into the session.
		} finally {
			generating = false;
		}
	});
}
