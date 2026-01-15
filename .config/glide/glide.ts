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
glide.unstable.include("tridactyl.glide.ts");
glide.fs.exists("local.glide.ts").then(exists => {
  if (exists) glide.unstable.include("local.glide.ts");
});

glide.g.mapleader = "," // too used to using space for scrolling
glide.buf.keymaps.del("normal", "s"); // use `s` for searching

// fix gmail keybindings
glide.autocmds.create("UrlEnter", {hostname: "mail.google.com"}, async () => {
  glide.buf.keymaps.del("normal", "gi");
  glide.buf.keymaps.del("normal", "e");
  glide.buf.keymaps.del("normal", "o");
  glide.buf.keymaps.del("normal", "x");
});

// new reddit is bad
glide.autocmds.create("UrlEnter", {hostname: "www.reddit.com"}, async () => {
  const url = new URL(glide.ctx.url);
  url.hostname = "old.reddit.com";
  await browser.tabs.update({ url: url.toString() });
});

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

glide.keymaps.set("normal", "ZZ", async () => {
  const tabs = await browser.tabs.query({});

  const bookmarkTree = await browser.bookmarks.getTree();
  const toolbarFolder = bookmarkTree[0]?.children?.find(
    (child) => child.id === "toolbar_____" || child.title === "Bookmarks Toolbar"
  );

  if (toolbarFolder) {
    let stashesFolder = toolbarFolder.children?.find((child) => child.title === "stashes");
    if (!stashesFolder) {
      stashesFolder = await browser.bookmarks.create({
        parentId: toolbarFolder.id,
        title: "stashes",
      });
    }

    const timestamp = new Date().toISOString().slice(0, 19).replace("T", " ");
    const stashFolder = await browser.bookmarks.create({
      parentId: stashesFolder.id,
      title: timestamp,
    });

    for (const tab of tabs) {
      if (tab.url && !tab.url.startsWith("about:")) {
        await browser.bookmarks.create({
          parentId: stashFolder.id,
          title: tab.title || tab.url,
          url: tab.url,
        });
      }
    }
  }

  await glide.excmds.execute("quit");
});
