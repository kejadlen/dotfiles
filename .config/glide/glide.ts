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
glide.include("pihole.glide.ts");
glide.include("splits.glide.ts");
glide.include("styles.glide.ts");
glide.include("tridactyl.glide.ts");
glide.include("utils.glide.ts");
glide.fs.exists("local.glide.ts").then(exists => {
  if (exists) glide.include("local.glide.ts");
});

// Open new tabs immediately after the current one, rather than at the
// end of the tab strip. Native Gecko pref; must be set at top level.
glide.prefs.set("browser.tabs.insertAfterCurrent", true);

// Make smoothscroll take a bit longer - with the default values, when
// I hit <space>, it goes too fast for me to keep track of where I was
glide.prefs.set("general.smoothScroll.pages.durationMinMS", 200);
glide.prefs.set("general.smoothScroll.pages.durationMaxMS", 400);

glide.g.mapleader = "," // too used to using space for scrolling
glide.buf.keymaps.del("normal", "s"); // use `s` for searching

glide.keymaps.set("command", "<C-n>", "commandline_focus_next");
glide.keymaps.set("command", "<C-p>", "commandline_focus_back");

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
  glide.buf.keymaps.set("normal", "*a", async () => {
    await glide.keys.send("*a", { skip_mappings: true });
  });
});

// new reddit is bad (but old.reddit.com doesn't serve media paths)
glide.autocmds.create("UrlEnter", { hostname: "www.reddit.com" }, async () => {
  const url = new URL(glide.ctx.url);

  // old reddit doesn't serve these
  if (url.pathname.startsWith("/media")) return;

  url.hostname = "old.reddit.com";
  await browser.tabs.update({ url: url.toString() });
});

// strip tracking params (rewrites the request before it fires, no reload)
// forEach avoids Symbol.iterator, which Xray vision denies on cross-compartment values.
const trackingParams = ["utm_*", "uta_*", "fbclid", "gclid"];
browser.webRequest.onBeforeRequest.addListener(
  (details) => {
    const url = new URL(details.url);
    const toDelete: string[] = [];
    url.searchParams.forEach((_value, key) => {
      if (trackingParams.some((pattern) =>
        pattern.endsWith("*") ? key.startsWith(pattern.slice(0, -1)) : key === pattern
      )) {
        toDelete.push(key);
      }
    });
    if (toDelete.length === 0) return;
    for (const key of toDelete) url.searchParams.delete(key);
    return { redirectUrl: url.toString() };
  },
  { urls: ["<all_urls>"], types: ["main_frame"] },
  ["blocking"]
);

// doi -> sci-hub — intercept at network level before the redirect fires
browser.webRequest.onBeforeRequest.addListener(
  (details) => {
    return { redirectUrl: `https://sci-hub.st/${details.url}` };
  },
  { urls: ["*://doi.org/*"], types: ["main_frame"] },
  ["blocking"]
);

glide.keymaps.set("normal", "yy", async () => {
  const url = glide.ctx.url;
  await navigator.clipboard.writeText(url.toString());
  glide.g["dev.kejadlen"]!.notify(`Yanked: ${url}`);
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
      // Top-level bookmark (ungrouped tab). With browser.tabs.insertAfterCurrent
      // enabled, a tab created while a grouped tab is active is added to that
      // group, so ungroup it to keep loose tabs loose.
      const tab = await browser.tabs.create({ url: child.url });
      if (tab.id) await browser.tabs.ungroup(tab.id);
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
      options: stashes.toReversed().map((stash) => ({
        label: stash.title,
        async execute() {
          await unstashTabs(stash.id);
        },
      })),
    });
  },
);

// cmd+opt+t: open a new tab at the end of the tab strip (overrides insertAfterCurrent for this call)
glide.keymaps.set("normal", "<D-A-t>", async () => {
  const tabs = await browser.tabs.query({});
  const lastIndex = tabs.reduce((max, t) => (t.index > max ? t.index : max), -1);
  await browser.tabs.create({ active: true, index: lastIndex + 1 });
},
  { description: "Open a new tab at the end of the tab strip" });

// mash+o (cmd+ctrl+alt+o): send the current tab to the "main" window — the
// normal window with the most tabs — and drop it at the end of that strip.
glide.keymaps.set(["normal", "insert"], "<C-A-D-o>", async ({ tab_id }) => {
  const windows = await browser.windows.getAll({
    populate: true,
    windowTypes: ["normal"],
  });
  const mainWindow = windows.reduce((best, win) =>
    (win.tabs?.length ?? 0) > (best.tabs?.length ?? 0) ? win : best
  );
  if (mainWindow.id == null) return;

  // Glide's cross-window mutation promises never settle, so we can't await
  // tabs.move. Fire it and wait for the tab to attach to the main window —
  // Glide brings that window to the front as it lands, making it the current
  // window, so activating the tab there (a same-window update) works.
  const onAttached = (attachedId: number, info: { newWindowId: number }) => {
    if (attachedId !== tab_id || info.newWindowId !== mainWindow.id) return;
    browser.tabs.onAttached.removeListener(onAttached);
    browser.tabs.update(tab_id, { active: true });
  };
  browser.tabs.onAttached.addListener(onAttached);
  browser.tabs.move(tab_id, { windowId: mainWindow.id, index: -1 });
});

glide.keymaps.set("normal", "ZZ", async () => {
  await stashTabs();
  await glide.excmds.execute("quit");
});
