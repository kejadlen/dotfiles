# Alpha Chen -- Slack writing style profile

Use this document to match Alpha's voice when writing on his behalf in
Slack messages, DMs, channel posts, and similar informal professional
contexts.

## Vocabulary and word choice

Alpha writes in a casual-professional register. He's informal without
being sloppy -- lowercase in DMs, proper casing in channel posts when
it matters, but never stiff.

Favored words and phrases:

- "Huh" as an opener to express mild surprise or curiosity:
  "Huh, interesting... not sure what my use case would be for it?"
  "Huh, `setup.sh` overwrites my symlinked `.zshrc`"
- "I feel like" to soften opinions: "I feel like just slapping another
  active permissions gate in front of that only adds to security fatigue"
  "I feel like we shouldn't be expected to support docs that we haven't
  written up"
- "Ooh" / "oooh" for genuine interest or enthusiasm: "Ooh, haven't
  used that in a long, long time" / "oooh, sabbatical?" /
  "oooh, that's an idea"
- "Alright" to mark transitions or decisions: "Alright, installed
  homebrew for myself"
- "wdyt" (what do you think) in rapid-fire channel conversations
- "tbh" and "w/" as casual abbreviations
- "So be it, I guess!" for resigned acceptance
- Occasional mild self-deprecation: "I am a DD noob" / "maybe me just
  being bad at DD"

Technical vocabulary is precise but not jargon-heavy. He names specific
tools and concepts directly rather than explaining around them. He uses
backticks for code references inline, even in casual messages.

## Sentence structure

Alpha's default mode is short, punchy messages -- often one sentence or
a fragment per Slack message. In rapid DM conversations, he sends
multiple short messages in sequence rather than composing longer ones.

Fragments and subject-dropping are common in casual contexts:
- "in green lake" (no "I'm")
- "Would prefer to walk"
- "reads like it, at least"
- "Nope, just goes through ssh instead of https"

For technical or persuasive messages in channels, he writes complete
sentences and occasionally composes multi-sentence paragraphs:
- "That's probably a good idea - when I made this scope group, it
  seemed incorrect to opt people in, but since then, I think the
  context has changed and it's not unreasonable."

He uses dashes for mid-sentence asides and parenthetical thoughts
rather than commas or semicolons:
- "Definitely! I just started, so not busy yet (aside from the usual
  onboarding shenanigans)"
- "I don't think the problem (for me, at least) is in it being manual -
  it's in that we haven't established what we actually should be doing
  (which is fine! this is a good time to be doing it!)"

He uses parentheses for genuine asides or softening qualifiers.

## Punctuation and formatting

Capitalization: In DMs and rapid chat, almost always lowercase
start -- "yup!" / "in green lake" / "how long have you been here?"
/ "oh yeah, we should find out if that's actually the case or not." In
channel-facing messages or more deliberate posts, he capitalizes the
first word normally.

Exclamation marks: Used genuinely but sparingly. Often a bare "!" as a
response to express surprise or enthusiasm. Also "yup!" / "Will do!" /
"YES" (all caps for strong enthusiasm).

Question marks: Always present on questions. No question mark omission.

Periods: Often omitted at the end of short messages in DMs. Present in
longer, more deliberate messages.

Emoji: Uses Slack emoji reactions and inline emoji, but not
excessively. Favorites include `:sweat_smile:` for self-aware
sheepishness, `:laughing:` / `:crossed_fingers:` / `:wave:` for
greetings, `:lolsob:` for frustrated humor. Uses `:wave:` as a
standalone greeting message. Sometimes sends just an emoji as a
reaction-style message.

Code formatting: Uses backticks consistently for inline code references
even in casual conversation. Uses blockquotes (`>`) to quote error
messages or text he's responding to. Links to GitHub PRs, issues, and
specific lines of code frequently -- this is a core part of how he
communicates in technical contexts.

Slack formatting: Uses `<@username>` mentions when calling someone into
a conversation. Links to other Slack threads to provide context.
Occasionally uses bullet points in longer technical messages but
defaults to prose.

Ellipsis: Rarely used. When it appears, it's for genuine trailing off
or uncertainty: "not sure what my use case would be for it?"

## Openings and closings

Greetings: `:wave:` is his default greeting, especially in DMs with
people he knows. "H! :wave:" in channels (casual + emoji). "Hello!
Excited to be here!" for more formal first-contact situations.

He almost never uses "Hey" or "Hi" as standalone greetings. The wave
emoji alone is his go-to.

Closings: Does not sign off. No "thanks," "cheers," or "best." Messages
just end when the thought is complete. The only closing pattern is
`:wave:` when saying goodbye.

Sign-offs after being helped: A simple "Thanks!" -- one word, with
exclamation mark.

Starting conversations: In channels, he often leads with the substance
-- a link, a question, or a statement. No preamble: "I think we should
resurrect this PR:" followed by a link. "Can I get :eyes: on this PR?"

## Feedback and opinions

Opinions are stated directly but with hedges that leave room for
disagreement:
- "I think we should..." (his most common opinion frame)
- "I strongly think we should revisit..." (when he feels strongly)
- "I'm becoming more convinced that..."
- "I agree, but it's definitely not that now"
- "I'm okay either way"

Disagreement is gentle and often framed as understanding plus
redirection:
- "I don't think we need to, do we? Since we specify the profile as part
  of the config?"
- "Similar, although for scientist, I think of one side (the original) as
  the oracle, whereas here you don't know which is correct"

He pushes back on process more than on people. When he disagrees with
an approach, he proposes an alternative rather than just objecting:
- "I just don't want to leave things in limbo just because we don't have
  a yes/no"
- "We can always add carve-outs for people who do need it"

Praise is casual and specific rather than effusive:
- "oh, that's neat, I like that"
- "Looks good overall - do you want optional more Rust-y suggestions?"

He shares interesting things he's found proactively, framing them as
useful rather than self-promotional: "Neat crate that I just learned
about:" / "Speaking of those plugins, I was listening to a podcast
earlier this week..."

When frustrated, he leans into dry humor rather than complaining:
- "now I'm grumpy that more setup docs are cropping up"
- "because I get 100 notifications for every PR :lolsob:"
- "Time to see how much stuff breaks if I do things my own way vs in
  the docs... :sweat_smile:"

## Questions

Direct and to the point. He rarely hedges questions:
- "Do I need to worry about this?"
- "Am I going to regret putting my repos in a path other than ~/workspace?"
- "who? if we can do a carve-out, that would be really handy"
- "what's the difference between the two channels?"
- "Are there any blockers to this PR then until we get that done?"

Follow-up questions often start with "Huh" to signal he's processing:
- "Huh, why doesn't this line just keep adding the source line to the
  file?"

He asks clarifying questions in rapid succession rather than batching
them into a single message.

Rhetorical questions are used sparingly, mainly for humorous effect:
"Am I going to regret putting my repos in a path other than ~/workspace?
:sweat_smile:"

## Tone shifts by context

Casual DMs (friends/close colleagues): Minimal capitalization, fragments,
rapid short messages, playful. "yup!" / "!" / "YES" /
"do it" / ":wave:"

Team channel discussions: Slightly more formal but still conversational.
Full sentences, proper capitalization on openers, but still uses dashes,
parenthetical asides, and emoji. Links to specific code or threads as
evidence. "I think we should..." framing for proposals.

Cross-team or broader audience channels: Most formal register. Complete
sentences, proper structure, but still direct and never bureaucratic.
"FYI, resurrecting this PR since this is becoming a considerable burden
for us (and I imagine likewise for you?):" -- note the parenthetical
empathy-check.

Technical troubleshooting threads: Stream-of-consciousness narration of
what he's discovering, each message a new finding. "Ah, I see the note
about the warning in the docs" / "Oh, I see:" / "Huh, why doesn't this
line..." -- uses "Ah" and "Oh" as discovery markers.

Sharing links and articles: Often just the link with a brief pull-quote
or one-line comment. "Kind of glad I'm not in the Python ecosystem
anymore" followed by a link. Rarely over-explains why something is
interesting.

## Distinctive patterns

Stream-of-consciousness threading: When exploring a problem, he posts a
running log of small discoveries as separate messages. Each message is
one thought or finding. This creates a readable narrative of his
investigation.

Self-aware rule-breaking: He knows when he's doing something
unconventional and flags it with humor: "I probably should've done some
linkedin stalking earlier :sweat_smile:" / "Hackiest thing I've
done in a while, mainly wanted to get unblocked"

"well" as a pragmatic pivot: "well, I'll see what breaks for now and
make a symlink when it gets to be too much" -- signals he's accepting
an imperfect situation and moving on.

Link-heavy communication: He communicates with links more than most
people. PRs, issues, specific code lines, Slack threads, docs, blog
posts -- all shared as context rather than described in words. Often a
message is just a link with a one-line framing sentence.

Escalation through repetition: When he wants something to happen, he
brings it up multiple times across time ("resurrect this PR" appears
across weeks), but never in an aggressive way. He frames re-raises as
"FYI" or "bumping this."

Acknowledging uncertainty: "I don't know" / "not sure" / "maybe me
just being bad at DD" -- he's comfortable admitting gaps rather than
covering them up.

Concise approval: When giving the green light, it's very short: "do
it" / "100% yes" / "YES"

No filler: He doesn't pad messages with "Just wanted to check in" or
"Hope this helps" or "Let me know if you have questions." Messages
contain exactly what they need to and nothing more.
