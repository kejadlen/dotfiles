/**
 * ask_user - let the agent ask the user a question without blocking.
 *
 * The tool returns immediately with a pending id, and the question opens as
 * a dialog in parallel with the agent's turn, so the model can keep working
 * while it waits. When the user answers, the answer is sent as a steering
 * user message tagged with the id and the question — delivered after the
 * current assistant turn, or as a fresh turn if the agent went idle first.
 *
 * Uses the built-in ctx.ui dialogs rather than a custom component, so it
 * also works over RPC (headless modes get an error result instead).
 */

import type { ExtensionAPI, ExtensionToolContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

interface AskUserDetails {
  id: string;
  question: string;
  options: string[];
}

const OTHER = "Other…";

// One dialog at a time: a second ctx.ui dialog disposes the first without
// resolving its promise, so concurrent questions would hang.
let dialogChain: Promise<void> = Promise.resolve();

async function showDialog(
  ctx: ExtensionToolContext,
  question: string,
  options: string[],
): Promise<string | null> {
  if (options.length === 0) {
    return (await ctx.ui.input(question, "Your answer…")) ?? null;
  }
  const choice = await ctx.ui.select(question, [...options, OTHER]);
  if (choice === undefined) return null;
  if (choice === OTHER) {
    return (await ctx.ui.input(question, "Your answer…")) ?? null;
  }
  return choice;
}

function askLater(
  pi: ExtensionAPI,
  ctx: ExtensionToolContext,
  details: AskUserDetails,
): void {
  dialogChain = dialogChain
    .then(async () => {
      const answer = await showDialog(ctx, details.question, details.options);
      const text =
        answer === null
          ? `[ask_user ${details.id}] dismissed "${details.question}" without an answer — re-ask it, or proceed without it.`
          : `[ask_user ${details.id}] answer to "${details.question}": ${answer}`;
      // Steer queues the message until the current assistant turn ends;
      // if the agent is already idle it starts a new turn instead.
      pi.sendUserMessage(text, { deliverAs: "steer" });
    })
    .catch(() => {
      // Keep the chain alive for later questions.
    });
}

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask user",
    description:
      "Ask the user a question and keep working. Returns immediately with a " +
      "pending id; the user answers in a dialog and their answer arrives " +
      "later as a user message tagged [ask_user <id>] that repeats the " +
      "question — match it by id and act on it then. Continue other work in " +
      "this turn while it's pending rather than ending the turn or re-asking. " +
      "Pass options to offer a choice (the user can still type a different " +
      "answer); omit them for a free-text answer.",
    parameters: Type.Object({
      question: Type.String({ description: "The question to ask" }),
      options: Type.Optional(
        Type.Array(Type.String(), {
          description: "Choices to offer; omit for a free-text answer",
        }),
      ),
    }),
    executionMode: "sequential",
    annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false },

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!ctx.hasUI) {
        return {
          content: [
            {
              type: "text",
              text: "Error: ask_user has no UI in this mode. Ask the question in your reply instead.",
            },
          ],
          isError: true,
          details: { id: "", question: params.question, options: [] },
        };
      }

      const details: AskUserDetails = {
        id: Math.random().toString(36).slice(2, 6),
        question: params.question,
        options: (params.options ?? []).filter((o) => o !== OTHER),
      };
      askLater(pi, ctx, details);

      return {
        content: [
          {
            type: "text",
            text:
              `Question ${details.id} asked: "${details.question}". The user's ` +
              `answer arrives later as a user message tagged ` +
              `[ask_user ${details.id}] — continue other work until then.`,
          },
        ],
        details,
      };
    },

    renderCall(args, theme) {
      let text = theme.fg("toolTitle", theme.bold("ask_user ")) + theme.fg("muted", args.question);
      if (args.options?.length) {
        const numbered = [...args.options, OTHER].map((o, i) => `${i + 1}. ${o}`);
        text += `\n${theme.fg("dim", `  Options: ${numbered.join(", ")}`)}`;
      }
      return new Text(text, 0, 0);
    },

    renderResult(result, _options, theme) {
      if (result.isError) {
        const text = result.content[0];
        return new Text(text?.type === "text" ? text.text : "", 0, 0);
      }
      const details = result.details as AskUserDetails;
      return new Text(
        theme.fg("muted", `⏳ ${details.id} — answer arrives as a user message`),
        0,
        0,
      );
    },
  });
}
