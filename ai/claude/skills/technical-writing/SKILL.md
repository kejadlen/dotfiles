---
name: technical-writing
description: Use when writing or reviewing technical documentation, API docs, tutorials, READMEs, or developer guides. Covers terminology, audience analysis, document structure, lists, paragraphs, illustrations, and sample code. Complements elements-of-style (prose clarity) and diataxis (document classification).
---

# Technical Writing

Actionable reference for technical documentation, distilled from
Google's Technical Writing courses.

For sentence-level prose rules, use elements-of-style. For classifying
documentation types, use diataxis. This skill covers the technical
writing concerns those skills do not.

## Terminology

**Define new terms.** Link to existing definitions when available.
Collect multiple definitions into a glossary.

**Use terms consistently.** When readers encounter two words that seem
synonymous, they wonder whether the author signals a subtle distinction.
Pick one term and stick with it. If you introduce an abbreviation
(Protocol Buffers as "protobufs"), use only the short form after the
first occurrence.

**Handle acronyms deliberately.** On first use, spell out the full term
with the acronym in parentheses, both bolded: **Telekinetic Tactile
Network (TTN)**. Do not define acronyms that appear only a few times or
that save little space.

**Resolve ambiguous pronouns.** Pronouns like *it*, *they*, *this*, and
*that* confuse readers when the referent is unclear. Place a pronoun
within five words of its noun. If a second noun intervenes, repeat the
original noun instead.

## Audience

**Define your audience before writing.** Identify their roles, existing
knowledge, and proximity to the subject. The equation:

> good documentation = (knowledge the audience needs) minus (knowledge
> the audience already has)

**List what the audience must learn or do.** Order prerequisites before
dependent material.

**Beware the curse of knowledge.** Expert understanding of a topic ruins
explanations to newcomers. Experts reference subtle interactions they
have internalized; newcomers have no frame for these references. After
drafting, reread from the audience's perspective and unpack assumptions.

**Use simple words.** Prefer straightforward vocabulary. Simple language
aids native speakers, non-native speakers, and translation tools alike.

**Avoid idioms and cultural references.** "Piece of cake," "ballpark
figure," and "sticky wicket" exclude international readers. Replace
with plain language.

## Sentences

**Choose strong, specific verbs.** Replace vague verbs (forms of *be*,
*occur*, *happen*) with verbs that say what actually happens.

| Weak | Strong |
|---|---|
| The exception occurs when... | Dividing by zero raises the exception |
| This error message happens when... | The system generates this error when... |

**Reduce "there is" and "there are."** These pair a generic noun with a
generic verb. Find the true subject and verb.

| Before | After |
|---|---|
| There is a variable that stores... | The variable stores... |
| There are two facts you should know | You should know two facts |

**Replace vague adjectives with data.** Subjective descriptors
("blazingly fast") sound like marketing. Use numbers: "225-250%
faster."

**Distinguish *that* from *which* (US English).** *That* introduces
essential clauses (no comma). *Which* introduces nonessential clauses
(with comma). Test: if you hear a pause, use *which*.

## Short Sentences

**One idea per sentence.** Each sentence should convey a single thought,
the way a program statement executes a single task.

**Convert embedded lists to actual lists.** When a sentence contains
"or" between multiple items or embeds a series of tasks, break it into
a bulleted or numbered list.

**Cut filler.** Common replacements:

| Wordy | Concise |
|---|---|
| at this point in time | now |
| determine the location of | find |
| is able to | can |
| causes the triggering of | triggers |

**Reduce subordinate clauses that branch into separate ideas.** If a
clause introduced by *which*, *because*, *since*, or *unless* carries
its own distinct point, promote it to a separate sentence.

## Lists and Tables

**Bulleted lists** for unordered items. **Numbered lists** for sequences
where order matters. Avoid embedding lists inside sentences.

**Maintain parallel structure.** The first item establishes a pattern
all items must follow in grammar, capitalization, and punctuation.

**Start numbered list items with imperative verbs.** "Open the file,"
"Click Submit," "Verify the output."

**Introduce every list and table** with a sentence explaining what it
represents. End the introduction with a colon. Use "following" when
natural.

**Table cells** should be concise (two sentences maximum). Keep data
within a column parallel.

## Paragraphs

**Write a strong opening sentence.** Busy readers sometimes read only
the first sentence of each paragraph. Make it carry the paragraph's
central point.

**One topic per paragraph.** Delete or move sentences unrelated to the
current topic.

**Three to five sentences per paragraph.** Walls of text intimidate
readers. Long paragraphs (seven or more sentences) should be split.
Excessive one-sentence paragraphs should be combined or converted to
lists.

**Address what, why, and how.** State what the thing is, why it matters
to the reader, and how the reader can use or verify it.

## Document Structure

**State the scope.** Declare what the document covers. Define its
non-scope: topics readers might expect but will not find. Non-scope
entries should be genuinely related to the subject.

**Specify the audience and prerequisites.** Help readers determine
whether the document is meant for them.

**Write a strong opening.** The first page determines whether readers
continue. Summarize key points early.

**Relate new concepts to familiar ones.** Compare and contrast with
technologies or ideas the audience already knows.

**Organize around audience needs.** Identify who reads the document,
what they know beforehand, and what they should know afterward.

## Organizing Large Documents

**Outline before writing.** Explain *why* before asking readers to
perform tasks. Limit each step to one concept. Share outlines with
contributors.

**Write introductions that orient.** State what the document covers,
required prior knowledge, and what it excludes.

**Provide navigation.** Include a table of contents, logical heading
hierarchy, links to related resources, and "what to learn next"
guidance.

**Use task-based headings.** Describe what the reader does ("Configure
the database") rather than abstract labels ("Configuration"). Avoid
unfamiliar terminology in headings.

**Disclose progressively.** Introduce terms near where they are used.
Break large text blocks with tables, diagrams, and lists. Start with
simple examples and advance to complex ones.

## Illustrations

**Write the caption before the illustration.** Effective captions are
brief, clarify the takeaway, and direct attention in detailed visuals.

**Limit information density.** Do not put more than one paragraph's
worth of information in a single diagram. Break complex systems into a
big-picture overview plus separate detail diagrams.

**Focus the reader's eye.** Use callouts, arrows, or highlighted shapes
to direct attention to the element that matters.

**Revise iteratively.** Ask: can I simplify this? Should it split into
multiple illustrations? Is text readable against the background?

## Sample Code

**Correct, concise, understandable, reusable, sequenced.** Good sample
code your readers can run, understand quickly, and adapt.

**Make sample code production-ready.** It should build without errors,
perform its task, and follow language conventions including security
considerations.

**Explain how to run it.** Document prerequisites: library
installations, environment variables, IDE configuration. Describe
expected output.

**Use descriptive names.** For learners, `MyLevel =
go.so.Level(rank=5, dimension=28)` beats unnamed positional parameters.

**Comment the non-obvious.** Keep comments brief. For experienced
readers, explain *why*, not *what*. Place short descriptions in code
comments; put longer explanations before the code block.

**Sequence by complexity.** Start with a minimal "hello world" example,
then progress through increasing complexity. Do not jump to advanced
usage first.

**Show both correct and incorrect forms** when language conventions
matter, so readers recognize the difference.

## Self-Editing Checklist

When reviewing your own technical writing:

- Read aloud to catch awkward phrasing
- Check every pronoun: is the referent obvious?
- Verify terminology consistency across the document
- Confirm each paragraph opens with its main point
- Ensure lists are parallel in grammar and punctuation
- Replace vague verbs and filler phrases
- Test sample code
- Write captions for every illustration
- Reread from the audience's perspective for curse-of-knowledge gaps
