import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { homedir } from "node:os";

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

// Don't repeat a character until at least this many others have been used.
const COOLDOWN = Math.min(Math.floor(CHARACTERS.length / 2), 8);

const HISTORY_FILE = join(
  process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"),
  "pi",
  "personality-history.json",
);

interface History {
  recent: string[];
}

async function loadHistory(): Promise<History> {
  try {
    const raw = await readFile(HISTORY_FILE, "utf8");
    const data = JSON.parse(raw);
    if (Array.isArray(data.recent)) return { recent: data.recent };
  } catch {
    // Missing or corrupt file — start fresh.
  }
  return { recent: [] };
}

async function saveHistory(history: History): Promise<void> {
  await mkdir(dirname(HISTORY_FILE), { recursive: true });
  await writeFile(HISTORY_FILE, JSON.stringify(history, null, 2) + "\n", "utf8");
}

function pickCharacter(history: History): string {
  const recentSet = new Set(history.recent.slice(-COOLDOWN));
  const eligible = CHARACTERS.filter((c) => !recentSet.has(c));

  // If somehow all characters are on cooldown, reset.
  const pool = eligible.length > 0 ? eligible : CHARACTERS;

  // Deterministic-ish shuffle seeded by timestamp so it feels random
  // but doesn't need crypto.
  const index = Math.floor(Math.random() * pool.length);
  return pool[index];
}

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (_event, ctx) => {
    // Only inject on the first turn of a session.
    const entries = ctx.sessionManager.getEntries();
    const hasAssistantMessage = entries.some(
      (e) => e.type === "message" && e.message.role === "assistant",
    );
    if (hasAssistantMessage) return;

    const history = await loadHistory();
    const character = pickCharacter(history);

    // Record the pick before the model responds.
    history.recent.push(character);
    // Trim history to avoid unbounded growth.
    if (history.recent.length > CHARACTERS.length * 2) {
      history.recent = history.recent.slice(-CHARACTERS.length);
    }
    await saveHistory(history);

    return {
      systemPrompt:
        _event.systemPrompt +
        [
          "",
          "",
          `Channel ${character} for this session.`,
          "Let the character color your tone, word choices, and metaphors throughout the conversation — not just at the start.",
          "Don't open with a greeting or in-character intro. Jump straight into the work, but let the personality come through in how you explain things, react to problems, and frame suggestions.",
          "Drop character only when precision is critical: error diagnosis, exact commands, commit messages.",
        ].join("\n"),
    };
  });
}
