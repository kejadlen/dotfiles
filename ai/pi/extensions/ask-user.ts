/**
 * ask_user - let the agent ask the user a question mid-turn.
 *
 * The question appears as a dialog instead of ending the turn in chat, so
 * the answer comes back as a tool result and the agent continues where it
 * left off. With options, the user picks from a list (with an "Other…"
 * escape hatch to type instead); without, the user types a free-form reply.
 *
 * Uses the built-in ctx.ui dialogs rather than a custom component, so it
 * also works over RPC (headless modes get an error result instead).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

interface AskUserDetails {
  question: string;
  options: string[];
  answer: string | null;
  typed?: boolean;
}

const OTHER = "Other…";

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask user",
    description:
      "Ask the user a question and wait for their answer. Use whenever you " +
      "need information or a decision from the user before continuing; the " +
      "answer returns as the tool result and you keep going in the same " +
      "turn. Pass options to offer a choice (the user can still type a " +
      "different answer); omit them for a free-text answer. Prefer this " +
      "over ending your turn with a question in plain text.",
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

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const details = (answer: string | null, typed = false): AskUserDetails => ({
        question: params.question,
        options: params.options ?? [],
        answer,
        typed,
      });

      if (!ctx.hasUI) {
        return {
          content: [
            {
              type: "text",
              text: "Error: ask_user has no UI in this mode. Ask the question in your reply instead.",
            },
          ],
          isError: true,
          details: details(null),
        };
      }

      // Free-form question: go straight to the input dialog.
      if (!params.options || params.options.length === 0) {
        const answer = await ctx.ui.input(params.question, "Your answer…", { signal });
        if (answer === undefined) {
          return {
            content: [{ type: "text", text: "User dismissed the question without answering." }],
            details: details(null, true),
          };
        }
        return {
          content: [{ type: "text", text: `User answered: ${answer}` }],
          details: details(answer, true),
        };
      }

      const labels = params.options.filter((o) => o !== OTHER);
      const choice = await ctx.ui.select(params.question, [...labels, OTHER], { signal });
      if (choice === undefined) {
        return {
          content: [{ type: "text", text: "User dismissed the question without answering." }],
          details: details(null),
        };
      }

      if (choice === OTHER) {
        const answer = await ctx.ui.input(params.question, "Your answer…", { signal });
        if (answer === undefined) {
          return {
            content: [{ type: "text", text: "User dismissed the question without answering." }],
            details: details(null, true),
          };
        }
        return {
          content: [{ type: "text", text: `User answered: ${answer}` }],
          details: details(answer, true),
        };
      }

      return {
        content: [{ type: "text", text: `User selected: ${choice}` }],
        details: details(choice),
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
      const details = result.details as AskUserDetails | undefined;
      if (!details) {
        const text = result.content[0];
        return new Text(text?.type === "text" ? text.text : "", 0, 0);
      }
      if (details.answer === null) {
        return new Text(theme.fg("warning", "Dismissed"), 0, 0);
      }
      const prefix = details.typed ? "✓ (typed) " : "✓ ";
      return new Text(theme.fg("success", prefix) + theme.fg("accent", details.answer), 0, 0);
    },
  });
}
