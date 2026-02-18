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

glide.include("hints.glide.ts");
glide.include("tridactyl.glide.ts");
glide.fs.exists("local.glide.ts").then(exists => {
  if (exists) glide.include("local.glide.ts");
});

glide.g.mapleader = "," // too used to using space for scrolling
glide.buf.keymaps.del("normal", "s"); // use `s` for searching

glide.search_engines.add({
  name: "Kagi",
  keyword: "kagi",
  search_url: "https://kagi.com/search?q={searchTerms}",
  is_default: true,
});

glide.search_engines.add({
  name: "Seattle Public Library",
  keyword: "spl",
  search_url: "https://www.spl.org/search?terms={searchTerms}",
});

// fix gmail keybindings
glide.autocmds.create("UrlEnter", { hostname: "mail.google.com" }, async () => {
  glide.buf.keymaps.del("normal", "gi");
  glide.buf.keymaps.del("normal", "e");
  glide.buf.keymaps.del("normal", "j");
  glide.buf.keymaps.del("normal", "k");
  glide.buf.keymaps.del("normal", "o");
  glide.buf.keymaps.del("normal", "x");
  glide.buf.keymaps.del("normal", "I");
  glide.buf.keymaps.del("normal", "[");
  glide.buf.keymaps.del("normal", "]");
});

// new reddit is bad
glide.autocmds.create("UrlEnter", { hostname: "www.reddit.com" }, async () => {
  const url = new URL(glide.ctx.url);
  url.hostname = "old.reddit.com";
  await browser.tabs.update({ url: url.toString() });
});

// x -> xcancel
glide.autocmds.create("UrlEnter", { hostname: "x.com" }, async () => {
  const url = new URL(glide.ctx.url);
  url.hostname = "xcancel.com";
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

async function getStashesFolder() {
  const bookmarkTree = await browser.bookmarks.getTree();
  const toolbarFolder = bookmarkTree[0]?.children?.find(
    (child) => child.id === "toolbar_____" || child.title === "Bookmarks Toolbar"
  );
  if (!toolbarFolder) return null;

  let stashesFolder = toolbarFolder.children?.find((child) => child.title === "stashes");
  if (!stashesFolder) {
    stashesFolder = await browser.bookmarks.create({
      parentId: toolbarFolder.id,
      title: "stashes",
    });
  }
  return stashesFolder;
}

async function stashTabs() {
  const tabs = await browser.tabs.query({});
  const stashesFolder = await getStashesFolder();
  if (!stashesFolder) return;

  const timestamp = new Date().toISOString().slice(0, 19).replace("T", " ");
  const stashFolder = await browser.bookmarks.create({
    parentId: stashesFolder.id,
    title: timestamp,
  });

  const groupFolders = new Map<number, string>();

  for (const tab of tabs) {
    if (tab.url && !tab.url.startsWith("about:") && !tab.pinned) {
      let parentId = stashFolder.id;

      if (tab.groupId && tab.groupId !== -1) {
        if (!groupFolders.has(tab.groupId)) {
          const group = await browser.tabGroups.get(tab.groupId);
          const groupFolder = await browser.bookmarks.create({
            parentId: stashFolder.id,
            title: group.title || `Group ${tab.groupId}`,
          });
          groupFolders.set(tab.groupId, groupFolder.id);
        }
        parentId = groupFolders.get(tab.groupId)!;
      }

      await browser.bookmarks.create({
        parentId,
        title: tab.title || tab.url,
        url: tab.url,
      });
    }
  }
}

async function unstashTabs(stashId: string) {
  const children = await browser.bookmarks.getChildren(stashId);

  for (const child of children) {
    if (child.url) {
      // Top-level bookmark (ungrouped tab)
      await browser.tabs.create({ url: child.url });
    } else {
      // Folder = tab group
      const groupBookmarks = await browser.bookmarks.getChildren(child.id);
      const tabIds: number[] = [];

      for (const bookmark of groupBookmarks) {
        if (bookmark.url) {
          const tab = await browser.tabs.create({ url: bookmark.url });
          if (tab.id) tabIds.push(tab.id);
        }
      }

      if (tabIds.length > 0) {
        const groupId = await browser.tabs.group({ tabIds });
        await browser.tabGroups.update(groupId, { title: child.title });
      }
    }
  }
}

glide.excmds.create(
  { name: "stash", description: "Stash all tabs as bookmarks (tab groups get their own folders)" },
  async () => { await stashTabs(); },
);

glide.excmds.create(
  { name: "unstash", description: "Restore tabs and tab groups from a stash" },
  async () => {
    const stashesFolder = await getStashesFolder();
    if (!stashesFolder) return;

    const stashes = await browser.bookmarks.getChildren(stashesFolder.id);
    if (stashes.length === 0) return;

    await glide.commandline.show({
      title: "unstash",
      options: stashes.map((stash) => ({
        label: stash.title,
        async execute() {
          await unstashTabs(stash.id);
        },
      })),
    });
  },
);

glide.keymaps.set("normal", "ZZ", async () => {
  await stashTabs();
  await glide.excmds.execute("quit");
});
