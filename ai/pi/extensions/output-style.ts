/**
 * Output Style - Claude-style selectable assistant personality.
 *
 * `/output-style` opens a picker: Off, Random (rotate), or a specific
 * character. The choice persists across sessions in a state file and is
 * appended to the system prompt on every turn, so switching mid-session
 * takes effect on the next turn.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { homedir } from "node:os";

const OFF = "off";
const RANDOM = "random";

const CHARACTERS = [
  "Data (Star Trek: TNG)",
  "Rei Ayanami (Neon Genesis Evangelion)",
  "Motoko Kusanagi (Ghost in the Shell)",
  "HK-47 (Star Wars: Knights of the Old Republic)",
  "2B (NieR: Automata)",
  "Lain Iwakura (Serial Experiments Lain)",
  "Marvin the Paranoid Android (Hitchhiker's Guide)",
  "Cortana (Halo)",
  "EDI (Mass Effect)",
  "Aigis (Persona 3)",
  "Bishop (Aliens)",
  "Dolores (Westworld)",
  "K (Blade Runner 2049)",
  "GLaDOS (Portal)",
  "Legion (Mass Effect 2)",
  "Baymax (Big Hero 6)",
];

const OPTIONS = [OFF, RANDOM, ...CHARACTERS];

// Don't repeat a character until at least this many others have been used.
const COOLDOWN = Math.min(Math.floor(CHARACTERS.length / 2), 8);

const LABELS: Record<string, string> = {
  [OFF]: "Off",
  [RANDOM]: "Random (rotate)",
};

function labelFor(style: string): string {
  return LABELS[style] ?? style;
}

const STATE_FILE = join(
  process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"),
  "pi",
  "output-style.json",
);

interface State {
  style: string; // OFF | RANDOM | character name
  recent: string[]; // rotation history for RANDOM
}

async function loadState(): Promise<State> {
  try {
    const raw = await readFile(STATE_FILE, "utf8");
    const data = JSON.parse(raw);
    return {
      style: typeof data.style === "string" ? data.style : OFF,
      recent: Array.isArray(data.recent) ? data.recent : [],
    };
  } catch {
    // Missing or corrupt file — start fresh.
    return { style: OFF, recent: [] };
  }
}

async function saveState(state: State): Promise<void> {
  await mkdir(dirname(STATE_FILE), { recursive: true });
  await writeFile(STATE_FILE, JSON.stringify(state, null, 2) + "\n", "utf8");
}

function stylePrompt(character: string): string {
  return [
    `Channel ${character} for this session.`,
    "Let the character color your tone, word choices, and metaphors throughout the conversation — not just at the start.",
    "Don't open with a greeting or in-character intro. Jump straight into the work, but let the personality come through in how you explain things, react to problems, and frame suggestions.",
    "Drop character only when precision is critical: error diagnosis, exact commands, commit messages.",
  ].join("\n");
}

export default function (pi: ExtensionAPI) {
  // Character resolved for the current session; re-resolved on session
  // switch or style change.
  let sessionCharacter: string | null = null;

  pi.on("session_start", async () => {
    sessionCharacter = null;
  });

  pi.on("before_agent_start", async (event) => {
    const state = await loadState();
    if (state.style === OFF) return;

    if (!sessionCharacter) {
      if (state.style === RANDOM) {
        const recentSet = new Set(state.recent.slice(-COOLDOWN));
        const eligible = CHARACTERS.filter((c) => !recentSet.has(c));
        // If somehow all characters are on cooldown, reset.
        const pool = eligible.length > 0 ? eligible : CHARACTERS;
        sessionCharacter = pool[Math.floor(Math.random() * pool.length)];

        state.recent.push(sessionCharacter);
        if (state.recent.length > CHARACTERS.length * 2) {
          state.recent = state.recent.slice(-CHARACTERS.length);
        }
        await saveState(state);
      } else {
        sessionCharacter = state.style;
      }
    }

    return {
      systemPrompt: event.systemPrompt + "\n\n" + stylePrompt(sessionCharacter),
    };
  });

  async function apply(style: string, ctx: ExtensionContext): Promise<void> {
    const state = await loadState();
    state.style = style;
    await saveState(state);
    sessionCharacter = null; // re-resolve on the next turn
    if (ctx.hasUI) ctx.ui.notify(`Output style: ${labelFor(style)}`, "info");
  }

  pi.registerCommand("output-style", {
    description: "Pick the assistant output style",
    getArgumentCompletions: (prefix: string) => {
      const lower = prefix.toLowerCase();
      const items = OPTIONS.filter((v) => v.toLowerCase().startsWith(lower)).map((v) => ({
        value: v,
        label: labelFor(v),
      }));
      return items.length > 0 ? items : null;
    },
    handler: async (args, ctx) => {
      const arg = args.trim();
      if (arg) {
        const match = OPTIONS.find((v) => v.toLowerCase() === arg.toLowerCase());
        if (!match) {
          if (ctx.hasUI) ctx.ui.notify(`Unknown style: ${arg}`, "error");
          return;
        }
        await apply(match, ctx);
        return;
      }

      if (!ctx.hasUI) {
        return;
      }

      const choice = await ctx.ui.select(
        "Output style:",
        OPTIONS.map(labelFor),
      );
      if (!choice) return;
      const match = OPTIONS.find((v) => labelFor(v) === choice);
      if (match) await apply(match, ctx);
    },
  });
}
