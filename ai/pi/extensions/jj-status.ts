/**
 * JJ Status Extension
 *
 * Replaces the default footer to show jj info instead of the git branch.
 * The built-in footer shows "(detached)" in colocated jj repos because
 * jj's git backend uses a detached HEAD. This extension swaps that for
 * bookmark, distance, and change ID — matching p10k's jj prompt.
 *
 * All other footer behavior (token stats, context %, model, extension
 * statuses) is preserved verbatim from the built-in footer.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { execSync } from "node:child_process";

// --- jj info ---

function getJJBranch(cwd: string): string | null {
  try {
    const bookmark = execSync(
      `jj --ignore-working-copy --no-pager log --no-graph --limit 1 -r '
        coalesce(
          heads(::@ & (bookmarks() | remote_bookmarks() | tags())),
          heads(@:: & (bookmarks() | remote_bookmarks() | tags())),
          trunk()
        )' -T 'separate(" ", bookmarks, tags)'`,
      { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] },
    ).trim().split(" ")[0]?.replace(/\*$/, "") ?? "";

    let result = "";

    if (bookmark) {
      const where = bookmark.length > 32
        ? bookmark.slice(0, 12) + "…" + bookmark.slice(-12)
        : bookmark;
      const after = execSync(
        `jj --ignore-working-copy --no-pager log --no-graph -r '${bookmark}..@ & (~empty() | merges())' -T '"n"'`,
        { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] },
      ).length;
      const before = execSync(
        `jj --ignore-working-copy --no-pager log --no-graph -r '@..${bookmark} & (~empty() | merges())' -T '"n"'`,
        { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] },
      ).length;
      result += where;
      if (before > 0) result += `‹${before}`;
      if (after > 0) result += `›${after}`;
    }

    const raw = execSync(
      `jj --ignore-working-copy --no-pager log --no-graph --limit 1 -r @ -T '
        separate("#",
          change_id.shortest(4),
          concat(
            if(conflict, "!"),
            if(divergent, "D"),
            if(hidden, "H"),
            if(immutable, "I"),
          ),
        )'`,
      { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] },
    ).trim();
    const [changeId, flags] = raw.split("#");

    if (changeId) {
      if (result) result += " ";
      result += changeId;
    }
    if (flags) result += ` ${flags}`;

    return result || null;
  } catch {
    return null;
  }
}

// --- footer (copied from built-in, replacing getGitBranch with getJJBranch) ---

function sanitizeStatusText(text: string): string {
  return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
  return `${Math.round(count / 1000000)}M`;
}

let cachedBranch: string | null = null;

function refreshJJ(cwd: string) {
  cachedBranch = getJJBranch(cwd);
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    refreshJJ(ctx.cwd);

    ctx.ui.setFooter((tui, theme, footerData) => ({
      invalidate() {},
      render(width: number): string[] {
        // --- Line 1: pwd + jj branch + session name ---
        let pwd = process.cwd();
        const home = process.env.HOME || process.env.USERPROFILE;
        if (home && pwd.startsWith(home)) {
          pwd = `~${pwd.slice(home.length)}`;
        }

        // jj info instead of git branch
        if (cachedBranch) {
          pwd = `${pwd} (${cachedBranch})`;
        }

        const sessionName = ctx.sessionManager.getSessionName();
        if (sessionName) {
          pwd = `${pwd} • ${sessionName}`;
        }

        if (pwd.length > width) {
          const half = Math.floor(width / 2) - 2;
          if (half > 1) {
            pwd = `${pwd.slice(0, half)}...${pwd.slice(-(half - 1))}`;
          } else {
            pwd = pwd.slice(0, Math.max(1, width));
          }
        }

        // --- Line 2: token stats (left) + model (right) ---
        let totalInput = 0;
        let totalOutput = 0;
        let totalCacheRead = 0;
        let totalCacheWrite = 0;
        let totalCost = 0;

        for (const entry of ctx.sessionManager.getEntries()) {
          if (entry.type === "message" && entry.message.role === "assistant") {
            const m = entry.message as any;
            totalInput += m.usage.input;
            totalOutput += m.usage.output;
            totalCacheRead += m.usage.cacheRead;
            totalCacheWrite += m.usage.cacheWrite;
            totalCost += m.usage.cost.total;
          }
        }

        // Context % from last non-aborted assistant message
        const branch = ctx.sessionManager.getBranch();
        let contextTokens = 0;
        for (let i = branch.length - 1; i >= 0; i--) {
          const e = branch[i];
          if (e.type === "message" && e.message.role === "assistant") {
            const m = e.message as any;
            if (m.stopReason !== "aborted") {
              contextTokens = m.usage.input + m.usage.output + m.usage.cacheRead + m.usage.cacheWrite;
              break;
            }
          }
        }

        const contextWindow = ctx.model?.contextWindow || 0;
        const contextPercentValue = contextWindow > 0 ? (contextTokens / contextWindow) * 100 : 0;

        const statsParts: string[] = [];
        if (totalInput) statsParts.push(`↑${formatTokens(totalInput)}`);
        if (totalOutput) statsParts.push(`↓${formatTokens(totalOutput)}`);
        if (totalCacheRead) statsParts.push(`R${formatTokens(totalCacheRead)}`);
        if (totalCacheWrite) statsParts.push(`W${formatTokens(totalCacheWrite)}`);

        const usingSubscription = ctx.model ? ctx.modelRegistry.isUsingOAuth(ctx.model) : false;
        if (totalCost || usingSubscription) {
          statsParts.push(`$${totalCost.toFixed(3)}${usingSubscription ? " (sub)" : ""}`);
        }

        const contextDisplay = `${contextPercentValue.toFixed(1)}%/${formatTokens(contextWindow)} (auto)`;
        if (contextPercentValue > 90) {
          statsParts.push(theme.fg("error", contextDisplay));
        } else if (contextPercentValue > 70) {
          statsParts.push(theme.fg("warning", contextDisplay));
        } else {
          statsParts.push(contextDisplay);
        }

        let statsLeft = statsParts.join(" ");
        let statsLeftWidth = visibleWidth(statsLeft);
        if (statsLeftWidth > width) {
          const plain = statsLeft.replace(/\x1b\[[0-9;]*m/g, "");
          statsLeft = `${plain.substring(0, width - 3)}...`;
          statsLeftWidth = visibleWidth(statsLeft);
        }

        const minPadding = 2;
        const modelName = ctx.model?.id || "no-model";
        let rightSideWithoutProvider = modelName;
        if (ctx.model?.reasoning) {
          const level = pi.getThinkingLevel() || "off";
          rightSideWithoutProvider =
            level === "off" ? `${modelName} • thinking off` : `${modelName} • ${level}`;
        }

        let rightSide = rightSideWithoutProvider;
        if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
          rightSide = `(${ctx.model.provider}) ${rightSideWithoutProvider}`;
          if (statsLeftWidth + minPadding + visibleWidth(rightSide) > width) {
            rightSide = rightSideWithoutProvider;
          }
        }

        const rightSideWidth = visibleWidth(rightSide);
        const totalNeeded = statsLeftWidth + minPadding + rightSideWidth;
        let statsLine: string;
        if (totalNeeded <= width) {
          const padding = " ".repeat(width - statsLeftWidth - rightSideWidth);
          statsLine = statsLeft + padding + rightSide;
        } else {
          const availableForRight = width - statsLeftWidth - minPadding;
          if (availableForRight > 3) {
            const plainRight = rightSide.replace(/\x1b\[[0-9;]*m/g, "");
            const truncated = plainRight.substring(0, availableForRight);
            const padding = " ".repeat(width - statsLeftWidth - truncated.length);
            statsLine = statsLeft + padding + truncated;
          } else {
            statsLine = statsLeft;
          }
        }

        const dimLeft = theme.fg("dim", statsLeft);
        const remainder = statsLine.slice(statsLeft.length);
        const dimRemainder = theme.fg("dim", remainder);
        const lines = [theme.fg("dim", pwd), dimLeft + dimRemainder];

        // --- Line 3 (optional): extension statuses ---
        const extensionStatuses = footerData.getExtensionStatuses();
        if (extensionStatuses.size > 0) {
          const sorted = Array.from(extensionStatuses.entries())
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([, text]) => sanitizeStatusText(text));
          const statusLine = sorted.join(" ");
          lines.push(truncateToWidth(statusLine, width, theme.fg("dim", "...")));
        }

        return lines;
      },
    }));
  });

  pi.on("tool_result", async (event, ctx) => {
    if (event.toolName === "bash") {
      const cmd = String(event.input.command ?? "").trimStart();
      if (cmd.startsWith("jj ")) refreshJJ(ctx.cwd);
    }
    if (event.toolName === "write" || event.toolName === "edit") {
      refreshJJ(ctx.cwd);
    }
  });
}
