---
name: writing-for-accessibility
description: Use when writing documentation, alt text, diagrams, or any content that should be accessible to people with disabilities. Covers alt text, color contrast, inclusive language, and accessible visuals. Also use when reviewing documents for accessibility.
---

# Writing for Accessibility

Actionable reference for making documentation accessible, distilled
from Google's Tech Writing for Accessibility course.

Accessible documentation is documentation anyone can read and
understand, including people who use screen readers, have low vision,
or have cognitive disabilities.

## Alt Text

**Write alt text for every informational image.** Screen readers read
alt text aloud; without it, they read the filename instead.

**Adjust descriptions to context.** The same image needs different alt
text depending on what the surrounding text emphasizes. A photo of a
chickadee in a birdwatching guide needs species detail; in an article
about winter adaptations, it needs plumage description.

**Keep it brief.** Use a short phrase or one to two sentences. Omit
"Image of" or "Photo of" — screen readers already announce that an
image is present. Capitalize the first word and end with a period to
provide auditory separation from the body text.

**Use empty alt text for decorative images.** When an image is purely
decorative or duplicates adjacent text, use `alt=""`. Omitting the alt
attribute entirely causes screen readers to read the filename.

**Handle complex images in two parts.** For graphs, flowcharts, or
detailed diagrams, write concise alt text summarizing the takeaway,
then provide a full description in the document body or on a linked
page. Data tables work well for chart data.

**Omit demographic details unless essential.** Describe people by
context ("musician," "teacher") unless demographics are relevant to the
image's purpose.

**Stay consistent.** Use the same alt text for the same image wherever
it appears. Avoid all caps — they affect readability and screen reader
interpretation.

## Color Contrast

**Meet WCAG contrast ratios.** Text must have sufficient contrast
against its background. Small text needs a higher ratio than large text.
Use a contrast checker tool before publishing.

**Never rely on color alone to convey meaning.** Pair color with text
labels, patterns, or icons. A chart that distinguishes series only by
color is inaccessible to colorblind readers.

## Inclusive Language

**Center the person, not the disability.** Avoid language that defines
people by a condition or implies they are lesser.

**Prefer person-first language in general.** "Person with a cognitive
impairment," not "cognitively impaired person."

**Respect community preferences.** Some communities prefer
identity-first language. Deaf and neurodivergent communities often
prefer "Deaf person" and "neurodivergent person." Research the
community's preference before writing about it.

**Avoid euphemisms and patronizing terms.** Do not describe nondisabled
people as "normal" or "healthy." Use "nondisabled," "sighted,"
"hearing," or "neurotypical" as appropriate.

**Avoid judgmental framing.** Replace "suffering from," "victim of,"
and "wheelchair-bound" with "experiencing," "living with," and "uses a
wheelchair."

**Do not use collective nouns for groups.** Write "people with
disabilities," not "the disabled."

## Accessible Visuals

**Introduce diagrams in body text.** Do not rely on alt text alone to
explain a diagram's purpose or structure.

**Use labels directly on diagrams** rather than requiring a separate
legend when possible. Legends add cognitive load and create problems
when the legend and diagram are not visible simultaneously.

**Ensure text in images is readable.** Use sufficient font size and
contrast. Text embedded in images cannot be resized by users and is
invisible to screen readers — minimize it.

## Editing for Accessibility

When reviewing a document for accessibility:

- Verify every informational image has descriptive alt text
- Check that decorative images use empty alt text
- Confirm color is never the sole indicator of meaning
- Test color contrast with a tool, not by eye
- Review language for person-first phrasing and community preferences
- Ensure diagrams are introduced and explained in body text
- Check that link text is descriptive ("Read the migration guide"),
  not generic ("Click here")
