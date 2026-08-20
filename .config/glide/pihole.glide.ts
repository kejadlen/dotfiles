/**
 * Pi-hole — Glide config
 *
 * Temporarily disable Pi-hole ad blocking via the FTL REST API
 * (POST /api/dns/blocking with a `timer`, which auto-resumes).
 * The API key is read from 1Password on every trigger and never
 * stored anywhere.
 *
 * Excmds:
 *   :pihole-sleep — disable blocking for 30 seconds
 *
 * Keymaps:
 *   ,p (normal) — pihole-sleep
 */

const PIHOLE_URL = "https://pihole";
const OP = "/opt/homebrew/bin/op"; // glide doesn't inherit the shell PATH
const CURL = "/usr/bin/curl";
const SLEEP_SECONDS = 30;

// POST JSON to the Pi-hole API. Bodies go through stdin so the API key
// never appears in process argv. Transport failures throw via curl's
// exit code; API failures come back as JSON `error` objects.
async function piholeRequest(path: string, body: unknown, sid?: string): Promise<any> {
  const args = [
    "--silent",
    "--show-error",
    "--max-time", "10",
    "--header", "Content-Type: application/json",
    "--data", "@-",
  ];
  if (sid) args.push("--header", `X-FTL-SID: ${sid}`);
  args.push(`${PIHOLE_URL}${path}`);

  const proc = await glide.process.spawn(CURL, args);
  await proc.stdin.write(JSON.stringify(body));
  await proc.stdin.close();
  const text = (await (await proc.wait()).stdout.text()).trim();

  let json: any;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`unexpected response from ${path}: ${text.slice(0, 200) || "(empty)"}`);
  }
  if (json.error) throw new Error(`${json.error.key}: ${json.error.message}`);
  return json;
}

async function piholeSleep(seconds: number): Promise<void> {
  const key = (await (await glide.process.execute(OP, ["read", "op://Private/Pi-hole/api key"])).stdout.text()).trim();
  if (!key) throw new Error("op read returned an empty API key");

  const auth = await piholeRequest("/api/auth", { password: key });
  const sid = auth?.session?.sid;
  if (!sid) throw new Error("auth response contained no session id");

  const status = await piholeRequest("/api/dns/blocking", { blocking: false, timer: seconds }, sid);
  if (status.blocking !== "disabled") throw new Error(`blocking status is "${status.blocking}"`);
}

// Reuses the .yank-notification class styled in glide.ts. The injected
// function is stringified across processes, so it can't capture anything.
async function notify(text: string): Promise<void> {
  await glide.content.execute(
    (message: string) => {
      const el = DOM.create_element("div", { className: "yank-notification", textContent: message });
      document.documentElement.appendChild(el);
      setTimeout(() => el.remove(), 2000);
    },
    { tab_id: await glide.tabs.active(), args: [text] },
  );
}

const piholeSleepCmd = glide.excmds.create(
  { name: "pihole-sleep", description: `Disable Pi-hole blocking for ${SLEEP_SECONDS} seconds` },
  async () => {
    try {
      await piholeSleep(SLEEP_SECONDS);
      await notify(`Pi-hole disabled for ${SLEEP_SECONDS}s`);
    } catch (err) {
      await notify(`Pi-hole: ${err instanceof Error ? err.message : String(err)}`);
    }
  },
);

declare global {
  interface ExcmdRegistry {
    "pihole-sleep": typeof piholeSleepCmd;
  }
}

glide.keymaps.set("normal", ",p", () => glide.excmds.execute("pihole-sleep"), {
  description: "Disable Pi-hole blocking for 30 seconds",
});
