---
name: writing-error-messages
description: Use when writing, reviewing, or improving error messages in code, CLI tools, APIs, or UIs. Covers identifying the cause, explaining the fix, and setting the right tone. Also use when error messages are vague, unactionable, or confusing.
---

# Writing Error Messages

Actionable reference for writing helpful error messages, distilled from
Google's Technical Writing course on error messages.

Every error message should answer two questions: what went wrong, and
how the user fixes it.

## General Rules

**Never fail silently.** Failure is inevitable; failing to report
failures is inexcusable. Silent failures confuse users and complicate
support.

**Raise errors immediately.** Report errors as soon as detected. Early
detection reduces debugging cost and prevents cascading failures.

**Preserve root cause information.** Avoid generic messages like "Server
error." Provide specific context about what actually failed.

**Log numeric error codes alongside text.** Codes help support teams
monitor and diagnose issues. Document all codes for internal and
external use.

## Explain the Problem

**Name the specific cause.** Tell users exactly what went wrong. Vague
messages frustrate users.

| Vague | Specific |
|---|---|
| Bad directory. | Directory '/tmp/out' exists but is not writable. |
| Invalid field 'picture'. | Field 'picture' appears multiple times. Only one instance is allowed. |

**Identify invalid user inputs.** When the user provided bad input, say
which input and why it failed.

**State the requirements and constraints.** If the error involves a
limit or format requirement, name the requirement explicitly. Include
version context when relevant ("Prior to v3.0, duplicate fields were
allowed").

## Explain the Solution

**Show how to fix it.** An error message that names the problem without
a remedy is a dead end.

| Dead end | Actionable |
|---|---|
| Client app no longer supported. | Client app no longer supported. Click **Update app** to install the latest version. |
| Quota 'CPUS' exceeded. Limit: 1.0 | You requested 5 CPUs but the limit in us-central-1 is 1. Request a quota increase or deploy to a different region. |

**Provide multiple solution paths when they exist.** Users have
different constraints; offering alternatives gives them agency.

**Link to documentation** for complex recovery procedures rather than
cramming instructions into the message.

**Include concrete examples** when format requirements are involved.
Show the expected format alongside the rejected input.

## Write Clearly

**Be concise.** Omit words the user does not need. Error messages are
read under stress; brevity reduces cognitive load.

**Avoid double negatives.** "The value must not be non-empty" requires
two negation inversions. Write "The value must be empty" or "Provide a
non-empty value" depending on intent.

**Write for your audience.** An API error seen by developers can include
technical detail. An error in a consumer UI should use plain language.
Match vocabulary to the reader.

**Use terminology consistently.** If the system calls it a "project"
everywhere, do not call it a "workspace" in one error message.

**Format for readability.** In long messages, separate the problem
statement from the solution. Use line breaks, bullet points, or
structured fields when the environment supports them.

## Tone

**Be positive.** State what to do, not what the user did wrong.

| Negative | Positive |
|---|---|
| You didn't enter a name. | Enter a name. |
| You entered an invalid postal code. | Enter a valid postal code, such as 90210. |

**Do not over-apologize.** Skip "sorry" and "please." Focus on the
problem and solution. Cultural expectations around apologies vary; clear
information serves all readers.

**Skip humor.** Frustrated users do not appreciate jokes. Humor
translates poorly across cultures and distracts from the message's
purpose.

**Do not blame the user.** Focus on what happened, not who caused it.

| Blaming | Neutral |
|---|---|
| You specified a printer that's offline. | The specified printer is offline. |

## Quick Reference

Every error message should include:

1. What went wrong (specific cause, not a generic label)
2. Why it went wrong (the constraint or requirement that was violated)
3. How to fix it (concrete next steps or links to documentation)

When writing, check: Is it specific? Is it actionable? Is the tone
neutral and constructive?
