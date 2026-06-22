---
name: web-design
description: Use when designing or building web UI, frontends, or styling — covers personal web design preferences, fluid layout, and Alpine.js
---

# Web design

These are personal defaults for building web interfaces. When a project
has its own design system, component library, or established conventions,
follow those instead.

This skill grows over time. It currently covers semantic HTML, fluid
layout (Utopia), and interactivity (Alpine.js); add sections as new
preferences surface.

## Semantic HTML

Lead with semantic HTML. Reach for meaningful elements — `main`,
`article`, `nav`, `kbd`, `details`, `dl`/`dt` — before wrapping content
in generic `div`s. Semantic markup gives the CSS something to target and
carries accessibility along with it.

matklad's [CSS: the unavoidable bad
parts](https://matklad.github.io/2026/06/04/css-unavoidable-bad-parts.html)
covers more ground — classless CSS, resets, flexbox, and gotchas like
margin collapsing. Worth reading and weighing case by case, not adopting
wholesale.

## Fluid layout with Utopia

Prefer fluid type and space scales over fixed breakpoint jumps. Sizes
interpolate continuously between a minimum and maximum viewport with CSS
`clamp()`, so layouts scale smoothly instead of snapping at media-query
boundaries.

Why fluid over breakpoints:

- Type and spacing stay proportional at every viewport width, not just
  the handful you picked.
- Fewer media queries to write and maintain.
- One coherent scale ties heading sizes, body text, and spacing
  together.

Generate the scales with the [Utopia](https://utopia.fyi) calculators
rather than hand-writing `clamp()` values:

- Type scale: <https://utopia.fyi/type/calculator>
- Space scale: <https://utopia.fyi/space/calculator>

Expose each step as a CSS custom property (`--step-0`, `--step-1`,
`--space-s`, `--space-m`, and so on) and reference the properties
throughout, so the scale lives in one place.

## Interactivity with Alpine.js

Prefer [Alpine.js](https://alpinejs.dev) for interactivity on
server-rendered pages. Alpine adds behavior through HTML attributes
(`x-data`, `x-show`, `x-on`) with no build step, which suits sites where
the markup already comes from the server and only needs light, local
interactivity.

Reach for Alpine when:

- The page is server-rendered and needs sprinkles of behavior
  (dropdowns, toggles, tabs, small stateful widgets).
- A full SPA framework would be more machinery than the problem
  warrants.
- You want behavior to live next to the markup it controls.

Prefer a heavier framework when the UI is genuinely
application-shaped — substantial client-side state, routing, or complex
component trees that Alpine's directive model would strain.

References:

- Docs and directives: <https://alpinejs.dev/start-here>
- Plugins (persist, focus, mask, etc.): <https://alpinejs.dev/plugins>

---

*This is a self-improving skill — see the `self-improving-skills` skill.*
