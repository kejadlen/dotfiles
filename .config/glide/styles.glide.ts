/**
 * Per-site page CSS.
 *
 * `glide.styles.add` only reaches the browser UI, so page styling goes through
 * the extension API. `browser.contentScripts.register` is the one that takes
 * CSS as an inline string, and registering at `document_start` styles every
 * matching load before first paint.
 *
 * Injected at author origin, which the cascade orders before the page's own
 * sheets — a page rule wins at equal specificity. If a site fights back, use
 * `browser.scripting.insertCSS({ origin: "USER" })` for it instead.
 */

const siteStyles: Record<string, string> = {
  // Unstyled HTML: no measure, no line-height, default Times.
  "*://danluu.com/*": css`
    body {
      max-width: 68ch;
      margin-inline: auto;
      padding: 2rem 1.25rem 4rem;
      font-family: Charter, "Iowan Old Style", Georgia, serif;
      font-size: 1.125rem;
      line-height: 1.6;
    }

    /* The measure would crush his 13-column benchmark tables, so let them out
       and centre them on the column — auto margins collapse to 0 once an
       element is wider than its container, hence left/translate. */
    main table {
      display: block;
      width: fit-content;
      max-width: 92vw;
      overflow-x: auto;
      position: relative;
      left: 50%;
      transform: translateX(-50%);
    }
  `,
};

for (const [matches, code] of Object.entries(siteStyles)) {
  browser.contentScripts.register({
    matches: [matches],
    css: [{ code }],
    runAt: "document_start",
  });
}
