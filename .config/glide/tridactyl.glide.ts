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

glide.keymaps.set("normal", "p", async ({ tab_id }) => {
  const url = await navigator.clipboard.readText();
  await browser.tabs.update(tab_id, { url });
});

glide.keymaps.set("normal", "P", async () => {
  const url = await navigator.clipboard.readText();
  await browser.tabs.create({ url });
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


