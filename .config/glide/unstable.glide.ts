// https://glide-browser.app/changelog#0.1.55a-split-views
glide.keymaps.set(
  "normal",
  "<C-w>v",
  async ({ tab_id }) => {
    await glide.excmds.execute("tab_new");
    const new_tab = await glide.tabs.active();
    glide.unstable.split_views.create([tab_id, new_tab.id]);
  },
  {
    description: "Create a split view with a new tab",
  },
);

glide.keymaps.set(
  "normal",
  "<C-w>j",
  async ({ tab_id }) => {
    const allTabs = await glide.tabs.query({});
    const currentIndex = allTabs.findIndex((t) => t.id === tab_id);
    const next = allTabs[currentIndex + 1];
    if (next?.id == null) return;
    glide.unstable.split_views.create([tab_id, next.id]);
  },
  {
    description: "Split view with the next tab",
  },
);

glide.keymaps.set(
  "normal",
  "<C-h>",
  async ({ tab_id }) => {
    const split = glide.unstable.split_views.get(tab_id);
    if (!split) return;
    const index = split.tabs.findIndex((t) => t.id === tab_id);
    const target = split.tabs.at((index - 1) % split.tabs.length);
    if (target?.id == null) return;
    await browser.tabs.update(target.id, { active: true });
  },
  {
    description: "Focus the split to the left",
  },
);

glide.keymaps.set(
  "normal",
  "<C-l>",
  async ({ tab_id }) => {
    const split = glide.unstable.split_views.get(tab_id);
    if (!split) return;
    const index = split.tabs.findIndex((t) => t.id === tab_id);
    const target = split.tabs.at((index + 1) % split.tabs.length);
    if (target?.id == null) return;
    await browser.tabs.update(target.id, { active: true });
  },
  {
    description: "Focus the split to the right",
  },
);

glide.keymaps.set(
  "normal",
  "<C-j>",
  async ({ tab_id }) => {
    const split = glide.unstable.split_views.get(tab_id);
    if (!split) {
      await glide.excmds.execute("tab_next");
      return;
    }
    const splitIds = new Set(split.tabs.map((t) => t.id));
    const all_tabs = await glide.tabs.query({});
    const currentIndex = all_tabs.findIndex((t) => t.id === tab_id);
    for (let i = 1; i < all_tabs.length; i++) {
      const target = all_tabs[(currentIndex + i) % all_tabs.length];
      if (target?.id && !splitIds.has(target.id)) {
        await browser.tabs.update(target.id, { active: true });
        return;
      }
    }
  },
  { description: "Next tab (skipping split siblings)" },
);

glide.keymaps.set(
  "normal",
  "<C-k>",
  async ({ tab_id }) => {
    const split = glide.unstable.split_views.get(tab_id);
    if (!split) {
      await glide.excmds.execute("tab_prev");
      return;
    }
    const splitIds = new Set(split.tabs.map((t) => t.id));
    const all_tabs = await glide.tabs.query({});
    const currentIndex = all_tabs.findIndex((t) => t.id === tab_id);
    for (let i = 1; i < all_tabs.length; i++) {
      const target = all_tabs.at((currentIndex - i) % all_tabs.length);
      if (target?.id && !splitIds.has(target.id)) {
        await browser.tabs.update(target.id, { active: true });
        return;
      }
    }
  },
  { description: "Previous tab (skipping split siblings)" },
);

glide.keymaps.set(
  "normal",
  "<C-w>f",
  async ({ tab_id }) => {
    glide.hints.show({
      action: async ({ content }) => {
        const href = await content.execute((target) => {
          const anchor = target.closest("a");
          return anchor?.href ?? null;
        });
        if (!href) return;

        const existing = glide.unstable.split_views.get(tab_id);
        if (existing) {
          // Navigate the other pane instead of creating a new split.
          const other = existing.tabs.find((t) => t.id !== tab_id);
          if (other?.id) {
            await browser.tabs.update(other.id, { url: href });
          }
        } else {
          const new_tab = await browser.tabs.create({ url: href, active: false });
          if (new_tab.id) {
            glide.unstable.split_views.create([tab_id, new_tab.id]);
          }
        }
      },
    });
  },
  {
    description: "Follow a hint in a split view",
  },
);

glide.keymaps.set(
  "normal",
  "<C-w>q",
  async ({ tab_id }) => {
    glide.unstable.split_views.separate(tab_id);
  },
  {
    description: "Close the split view for the current tab",
  },
);
