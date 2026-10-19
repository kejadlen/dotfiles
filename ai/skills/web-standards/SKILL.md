---
name: web-standards
description: Use when writing or reviewing HTML, CSS, or browser JavaScript — covers semantic markup, native platform features over libraries, Baseline browser support, accessibility and APCA contrast, and optional validation with vnu, axe, and Lighthouse
---

# Web standards

Build on what the platform already does, and check claims about it
against a primary source rather than memory. Browser support moves
faster than training data, so a feature remembered as unsupported may
have shipped everywhere since.

For visual design, fluid type, and Alpine.js, use `web-design`. For alt
text and inclusive language, use `writing-for-accessibility`.

## Semantic HTML

Lead with semantic HTML. Reach for meaningful elements — `main`,
`article`, `nav`, `kbd`, `details`, `dl`/`dt` — before wrapping content
in generic `div`s. Semantic markup gives the CSS something to target and
carries accessibility along with it.

## Native before JavaScript

Before adding a library or hand-rolling behavior, check whether the
platform has a built-in. The following replace common dependencies:

| Need | Platform feature |
|------|------------------|
| Modals | `<dialog>` with `showModal()` |
| Menus, tooltips, toasts | `popover` attribute |
| Disclosure, accordions | `<details>` and `<summary>`, grouped with `name` |
| Form validation | Constraint validation: `required`, `pattern`, `:user-invalid` |
| Parent and state selectors | `:has()` |
| Component-level responsiveness | Container queries |
| Preprocessor nesting | Native CSS nesting |
| Page and state transitions | View transitions |
| Positioning relative to another element | Anchor positioning |
| Date, number, and list formatting | `Intl.*` |
| URL parsing and query strings | `URL`, `URLSearchParams` |
| Cancellable requests | `fetch` with `AbortController` |
| Deep copies | `structuredClone()` |

Some of these are newer than others. Check support before relying on
one, as described in the next section.

## Browser support

Default to [Baseline] "widely available": features that have worked in
every major browser for at least 30 months. Use "newly available"
features only as progressive enhancement, behind `@supports` or feature
detection, so the page still works without them.

Look up the current status on [Baseline] or [caniuse] instead of
recalling it. MDN pages also show a Baseline badge near the top.

## Progressive enhancement

Forms submit and links navigate without JavaScript. JavaScript layers
behavior on top of working HTML, not in place of it. Keep state worth
sharing — filters, tabs, search terms — in the URL so it survives a
reload and a copied link.

## Accessibility

Target [WCAG 2.2] level AA. It's the current W3C Recommendation, and
the regulations that cite WCAG 2.1 AA are satisfied by 2.2 AA too.
WCAG 3 is still a Working Draft; don't target it.

Follow the first rule of ARIA: when a native element has the semantics
and behavior you need, use it instead of adding `role` and `aria-*` to
a `div`. A `<button>` is focusable, activates on Enter and Space, and
announces itself as a button for free.

Keep focus visible and in a logical order. When a `<dialog>` or popover
closes, focus returns to whatever opened it. Respect
`prefers-reduced-motion` for animation and `prefers-color-scheme` for
theming.

## Color contrast

Pass WCAG 2.2 AA (4.5:1 for body text, 3:1 for large text and UI
components), then check [APCA] as a perceptual floor. APCA handles dark
mode and thin fonts better than the WCAG 2 ratio, which overstates
contrast for light text on dark backgrounds. APCA is a candidate for
WCAG 3, not a standard, so it supplements WCAG 2.2 and doesn't replace
it.

APCA reports a lightness contrast (Lc) value that's negative for light
text on dark backgrounds; compare its absolute value against the
following thresholds:

| Lc | Use |
|----|-----|
| 90 | Preferred for body text |
| 75 | Minimum for body text (18px/400, 16px/500, 14px/700) |
| 60 | Minimum for other content text (24px/400, 16px/700) |
| 45 | Headlines (36px/400, 24px/700) |
| 30 | Minimum for any other text, and non-text elements |
| 15 | Minimum for non-semantic elements that must stay visible |

With fluid type, check the smallest size in each `clamp()` range.

## Primary sources

Cite specs and references, not blog summaries or recollection:

- [WHATWG] for HTML, DOM, Fetch, and URL behavior
- [MDN] for usage and examples
- [Baseline] and [caniuse] for browser support
- [WCAG 2.2] and [ARIA in HTML] for accessibility

## Validating

These checks are optional. Run one when it's cheap and the change
touches markup, styles, or color. If a tool isn't available, say which
check you skipped instead of installing something to get around it.

| Check | Command | Needs |
|-------|---------|-------|
| HTML conformance | `vnu --errors-only page.html` | `vnu` (Homebrew) or `npx vnu-jar`, plus a JDK |
| CSS conformance | `vnu --css --errors-only style.css` | Same as above |
| Accessibility rules | `npx @axe-core/cli <url>` | Chrome |
| Accessibility audit | `npx lighthouse <url> --only-categories=accessibility` | Chrome |
| APCA contrast | The [APCA calculator], or `apca-w3` in a script | Nothing, or Node |

Automated checks catch only a fraction of accessibility problems; a
clean axe run doesn't mean the page is accessible. For interactive
changes, also tab through the page and confirm focus stays visible and
moves in order.

[Baseline]: https://web.dev/baseline
[caniuse]: https://caniuse.com
[WCAG 2.2]: https://www.w3.org/TR/WCAG22/
[APCA]: https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell
[APCA calculator]: https://apcacontrast.com
[WHATWG]: https://spec.whatwg.org
[MDN]: https://developer.mozilla.org
[ARIA in HTML]: https://www.w3.org/TR/html-aria/

---

*This is a self-improving skill. If you used it and it came up short — a missing command, flag, gotcha, or workflow — invoke the `self-improving-skills` skill and follow it before you finish.*
