/**
 * Shared utilities — Glide config
 *
 * Glide configs can't import runtime code between files (only type
 * imports, which are stripped), and each included file gets its own
 * global scope. Shared state goes through `glide.g`, which crosses
 * include boundaries; types are added with `declare global`. Keys
 * under `glide.g["dev.kejadlen"]` are this dotfiles repo's own
 * namespace (reverse-DNS, so glide's own GlideGlobals state can never
 * collide — it already uses `mapleader` there).
 */

glide.styles.add(`
  .glide-notification {
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

interface Utils {
  /** Show a transient notification overlay in the browser UI. */
  notify(text: string): void;
}

declare global {
  interface GlideGlobals {
    "dev.kejadlen"?: Utils;
  }
}

// Keymap and excmd callbacks run in the main process, where `document`
// is the browser UI itself; `DOM` is main-process-only by design.
glide.g["dev.kejadlen"] = {
  notify(text: string): void {
    const el = DOM.create_element("div", { className: "glide-notification", textContent: text });
    document.documentElement.appendChild(el);
    setTimeout(() => el.remove(), 2000);
  },
};
