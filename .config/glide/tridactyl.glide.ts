/* navigation */

// `gi` doesn't focus if no element has previously been focused
glide.keymaps.set("normal", "gi", "keys gI");

type ZoomFn = (zoom: number) => number;
type KeymapHandler = (ctx: { tab_id: number }) => Promise<void>;

const setZoom = (fn: ZoomFn): KeymapHandler => async ({ tab_id }) => {
  const zoom = await browser.tabs.getZoom(tab_id);
  await browser.tabs.setZoom(tab_id, fn(zoom));
};

glide.keymaps.set("normal", "zi", setZoom((z) => z + 0.1));
glide.keymaps.set("normal", "zo", setZoom((z) => z - 0.1));
glide.keymaps.set("normal", "zz", setZoom(() => 1));

/* new pages */

function isUrl(text: string): boolean {
  try {
    const url = new URL(text);
    return ["http:", "https:", "file:"].includes(url.protocol);
  } catch {
    return false;
  }
}

glide.keymaps.set("normal", "p", async ({ tab_id }) => {
  const text = (await navigator.clipboard.readText()).trim();
  if (isUrl(text)) {
    await browser.tabs.update(tab_id, { url: text });
  } else {
    await browser.search.search({ query: text, tabId: tab_id });
  }
});

glide.keymaps.set("normal", "P", async () => {
  const text = (await navigator.clipboard.readText()).trim();
  if (isUrl(text)) {
    await browser.tabs.create({ url: text });
  } else {
    await browser.search.search({ query: text, disposition: "NEW_TAB" });
  }
});

glide.keymaps.set("normal", "H", "back");
glide.keymaps.set("normal", "L", "forward");

/* tab handling */

glide.keymaps.set("normal", "d", "tab_close");

glide.keymaps.set("normal", "u", async () => {
  const sessions = await browser.sessions.getRecentlyClosed({ maxResults: 1 });
  const [session, ..._] = sessions;
  if (session) {
    await browser.sessions.restore(session.tab?.sessionId ?? session.window?.sessionId);
  }
});


