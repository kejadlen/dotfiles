---
name: threat-modeling
description: Use when writing or reviewing a threat model, designing a system with security implications, or evaluating security claims and trade-offs — covers the seven questions, layered decomposition, risk status categories, and spotting weak security reasoning
---

# Threat modeling

An informal, practical approach to threat models, from Soatok's guide.
Threat modeling belongs at the design stage — architectural mistakes
(wrong abstractions, unsolvable ordering requirements) are detectable
there and expensive to discover post-implementation.

## The seven questions

A threat model answers these, in roughly this order:

1. What are we protecting? (assets)
2. Who or what wants to harm it? (threat actors — hackers, activists,
   cyber-stalkers, disgruntled employees, hostile legislators,
   nation-states)
3. How might 2 attack 1? (attack vectors)
4. What will we do to prevent 3? (controls)
5. How are the assets related and connected? Think in graphs, not
   lists — attacks travel along relationships.
6. What assumptions are we making, especially in 4 and 5?
7. What threats are we deliberately not addressing? (accepted risks)

Questions 6 and 7 separate good threat models from bad ones. An
incorrect assumption undermines the whole model — the Invisible
Salamanders attack works because AEAD schemes like AES-GCM and
ChaCha20-Poly1305 are assumed to bind a ciphertext to a single key,
and they don't. Writing assumptions down is how unknown unknowns get
found.

## Method

- Map the system's components graphically and draw the relationships
  between components that interact or depend on each other.
- Work in nested abstraction layers: start broad, then drill into
  specifics. Different components have different security dependencies —
  a database's needs aren't a load balancer's.
- For each layer, document inputs, outputs, and answers to the seven
  questions. For layers you're not examining deeply, document the
  assumptions you're making about them instead.
- Look for relationships that shouldn't exist and sever them.
- Treat the result as a living document. A model unchanged for years
  while vulnerabilities accumulate is a red flag, not a sign of
  stability.

## Structure of a good one

Soatok's [Public Key Directory threat model][pkd] (key transparency for
the Fediverse) is the worked example. Sections: assumptions stated
upfront, then assets, then actors (attackers and protected parties,
each given a role name), then risks. Each risk gets a status:

| Status | Meaning |
|---|---|
| Prevented by design | The attack cannot happen |
| Mitigated | The attack fails unless an assumption breaks |
| Addressable | Mitigation is possible but takes effort |
| Open | Accepted risk; the attack will succeed |

The anti-pattern is a flat list of attack types with no assumptions, no
asset inventory, no relationships, and stale coverage (Matrix's threat
model earns a C- on these grounds). That said: a shitty threat model
beats not having a threat model.

## Using it to evaluate claims

The same discipline detects weak security reasoning in debates and
reviews: check the factual premises, check whether a proposed control
actually mitigates the stated risk, and check for hedges that don't
hold in the scenario they claim to address. Example from the
post-quantum debate: hybrid PQ+ECDH hedges against a pre-Q-Day break of
the PQ algorithm but adds zero security post-Q-Day, so "hybrid always"
is not the safety argument it sounds like — pure ECDH is what Q-Day
retroactively breaks.

Controls trade against usability, and the trade cuts back: "security at
the expense of usability comes at the expense of security" (Avi
Douglen). Threat modeling sometimes surfaces controls that improve
both — passkeys kill credential stuffing (asymmetric, domain-bound,
nothing reusable to stuff) and are easier to use than passwords.

[pkd]: https://github.com/fedi-e2ee/public-key-directory-specification/blob/main/Specification.md#threat-model

## Sources

- [Soatok's Informal Guide to Threat Models](https://soatok.blog/2026/06/30/soatoks-informal-guide-to-threat-models/) (Soatok, 2026)
