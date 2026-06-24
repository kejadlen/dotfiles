---
name: markdown
description: Use when writing, reviewing, or formatting Markdown — captures personal preferences for links, citations, and plaintext readability
---

# Markdown preferences

Personal conventions for hand-written Markdown. Optimize for how the
source reads in *plaintext*, not just how it renders.

## Links and citations

Use reference-style links (`[text][label]` with a separate `[label]: url`
definition) rather than inline `[text](url)` when the URL is long. A long
inline URL fragments the prose across line wraps, which reads badly in
plaintext.

Keep the visible tag tiny and place the `[label]: url` definition close
to where the link is used — not collected at the bottom of the file.
Markdown allows reference definitions anywhere, so keep the URL near its
context. Use one reference per link; don't stack a footnote (`[^x]`) and
a separate link reference for the same source.

---

*This is a self-improving skill — see the `self-improving-skills` skill.*
