// Config docs:
//
//   https://glide-browser.app/config
//
// API reference:
//
//   https://glide-browser.app/api
//
// Default config files can be found here:
//
//   https://github.com/glide-browser/glide/tree/main/src/glide/browser/base/content/plugins
//
// Most default keymappings are defined here:
//
//   https://github.com/glide-browser/glide/blob/main/src/glide/browser/base/content/plugins/keymaps.mts
//
// Try typing `glide.` and see what you can do!

glide.unstable.include("hints.glide.ts");

glide.styles.add(`
  .yank-notification {
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    z-index: 2147483646;
    background: var(--glide-cmdl-bg);
    color: var(--glide-cmdl-fg);
    border: 1px solid hsla(0, 0%, 100%, 0.1);
    border-radius: 4px;
    box-shadow: 0 -8px 32px hsla(0, 0%, 0%, 0.4);
    font-family: var(--glide-cmdl-font-family);
    font-size: var(--glide-cmdl-font-size);
    line-height: var(--glide-cmdl-line-height);
    padding: 0.75rem 1rem;
    max-width: 600px;
    word-break: break-all;
  }
`);

glide.keymaps.set("normal", "zi", async ({ tab_id }) => {
  const zoom = await browser.tabs.getZoom(tab_id);
  await browser.tabs.setZoom(tab_id, zoom + 0.1);
});

glide.keymaps.set("normal", "zo", async ({ tab_id }) => {
  const zoom = await browser.tabs.getZoom(tab_id);
  await browser.tabs.setZoom(tab_id, zoom - 0.1);
});

glide.keymaps.set("normal", "zz", async ({ tab_id }) => {
  await browser.tabs.setZoom(tab_id, 1);
});

glide.keymaps.set("normal", "u", async () => {
  const sessions = await browser.sessions.getRecentlyClosed({ maxResults: 1 });
  const [session, ..._] = sessions;
  if (session) {
    await browser.sessions.restore(session.tab?.sessionId ?? session.window?.sessionId);
  }
});

glide.keymaps.set("normal", "H", "back");
glide.keymaps.set("normal", "L", "forward");
glide.keymaps.set("normal", "d", "tab_close");

glide.keymaps.set("normal", "p", async ({ tab_id }) => {
  const url = await navigator.clipboard.readText();
  await browser.tabs.update(tab_id, { url });
});

glide.keymaps.set("normal", "P", async () => {
  const url = await navigator.clipboard.readText();
  await browser.tabs.create({ url });
});

glide.keymaps.set("normal", "yy", async () => {
  const url = glide.ctx.url;
  await navigator.clipboard.writeText(url.toString());

  const notification = DOM.create_element("div", {
    className: "yank-notification",
    textContent: `Yanked: ${url}`,
  });

  document.documentElement.appendChild(notification);
  setTimeout(() => notification.remove(), 2000);
});

