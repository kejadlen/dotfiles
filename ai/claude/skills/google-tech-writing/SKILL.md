---
name: google-tech-writing
description: Use when writing or reviewing technical documentation, error messages, API docs, code comments, READMEs, or tutorials for a technical audience
---

# Google Tech Writing

Reference guide distilled from Google's four Technical Writing courses. Covers
rules specific to technical communication that general prose style guides omit.
Complements elements-of-style (general prose quality) with technical-specific
guidelines.

## Terminology

- Define new terms on first use; link to existing definitions when available
- Use each term consistently throughout — don't alternate names ("Protocol
  Buffers" then "protobufs" without introduction)
- On first use, spell out the full term with the acronym in parentheses, both
  bold: **Telekinetic Tactile Network** (**TTN**)
- Only define acronyms that appear multiple times and save significant space
- Replace ambiguous "this", "that", "it" with the noun they reference
- If five or more words separate a pronoun from its antecedent, repeat the noun

## Sentences

- Choose strong, specific verbs over forms of "be", "occur", "happen"
  - Weak: "The exception occurs when dividing by zero"
  - Strong: "Dividing by zero raises the exception"
- Eliminate "There is/There are" — restructure around the real subject
- Replace vague adjectives with numbers: "225-250% faster" not "screamingly fast"
- One idea per sentence
- "That" for essential clauses (no comma); "which" for nonessential (with comma)

## Lists, Tables, and Paragraphs

- Bulleted lists for unordered items; numbered lists for sequences or steps
- Start numbered list items with imperative verbs: Open, Set, Click
- Keep all items parallel in grammar, capitalization, and punctuation
- Introduce every list and table with a sentence containing "following" and a colon
- Open each paragraph with its central point — busy readers skip everything else
- One topic per paragraph; 3-5 sentences; answer what, why, and how

## Audience and Document Structure

- Documentation = knowledge the audience needs minus what they already know
- State scope and non-scope explicitly: what the document covers and what it does not
- Specify the target audience and prerequisite knowledge
- Answer the reader's essential questions in the opening
- Relate new concepts to familiar ones ("like X, except Y")
- Beware the curse of knowledge: experts forget what beginners don't know
- Prefer simple words; avoid idioms, sports metaphors, and culturally specific references

## Code Samples

- Samples must build without errors, perform what they claim, and be production-ready
- Correctness over conciseness — never use bad practices to shorten code
- Comments explain why, not what, for experienced readers
- Sequence samples from basic to intermediate to advanced
- Test samples regularly; they break as systems change
- Unit tests and sample code serve different purposes — don't substitute one for the other

## Error Messages

Every error message answers two questions: what went wrong, and how to fix it.

**Explain the problem:**
- Name the specific component, field, or value that failed
- State the exact constraint violated, not a generic "invalid input"
- Include relevant context (limits, version changes, region)

**Explain the fix:**
- Provide concrete steps or link to documentation
- Offer multiple fix paths when they exist

**Write clearly:**
- Concise but not cryptic: "Can't connect to the SQL database" not "Unsupported"
- Active voice: "The Frambus app no longer supports..." not "is no longer supported by..."
- Don't blame the user: "Enter a valid postal code" not "You entered an invalid postal code"
- Don't apologize ("sorry") or attempt humor
- Use progressive disclosure for lengthy explanations — brief message with option to expand

**Format for readability:**
- Place the message as close as possible to the error's location
- Pair color cues with a second visual indicator (bold, underline, spacing)
- Log numeric error codes for support teams
- Raise errors immediately — delayed reporting obscures the cause

## Illustrations

- Write the caption before creating the illustration
- Limit each diagram to one paragraph of information (~5 bullet points)
- Decompose complex systems into subsystem diagrams shown progressively
- Use callouts and arrows to direct attention to key areas
- Export as SVG for scalable quality

## Accessibility

- Write contextual alt text in 1-2 sentences; omit "Image of..." prefixes
- End alt text with a period so screen readers pause before the next element
- Use empty `alt=""` for decorative images or when surrounding text already conveys the meaning
- For complex diagrams, provide a detailed description in the document body
- Ensure sufficient color contrast; pair color with another visual cue
- Use person-first language ("person with low vision") unless the community prefers identity-first
- Avoid "normal" or "healthy" for nondisabled people

## Self-Editing

- Read the draft aloud — awkward phrasing becomes obvious
- Set it aside and return with fresh eyes
- Change the visual context: different font, format, or medium
- Ask a peer to review; they need style awareness, not domain expertise

## Source

[Google Technical Writing Courses](https://developers.google.com/tech-writing/overview),
licensed CC BY 4.0.
