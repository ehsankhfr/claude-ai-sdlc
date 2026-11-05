---
name: capture-intent
description: Turn an idea, ticket, or incident into an intent.md proto-spec through a short brainstorm. Use when someone describes a problem, a wanted outcome, or says "capture this as intent" / "write this up as intent.md".
---

# Capture intent

Produce a reviewed `intent.md` in the originator's own terms: what is wanted, why, and under which constraints. This is Stage 1 of the AI-native SDLC. Its output feeds Stage 2 (Design).

## Steps

1. **Listen.** Let the originator describe the problem in their own words: what they cannot do today, who is affected, what better looks like, what is out of scope. Don't require formal language.
2. **Brainstorm until concrete.** Ask the questions an analyst would ask, a few at a time, not a questionnaire:
   - Scope: what is in, what is explicitly out?
   - Users: who is affected, and who else might be?
   - Constraints: security, data, regulatory, existing systems, deadlines.
   - Success: how would we know it worked? Prefer something measurable.
   Stop when the template sections below can be filled from what was said. Anything still unknown goes under **Open questions**. Don't invent answers to fill gaps.
3. **Write `intent/<change-slug>/intent.md`** using the template below. Use a short kebab-case slug (e.g. `claims-status-self-service`). Keep the originator's vocabulary; don't translate it into solution design.
4. **Hand it back for correction.** Show the draft and ask the originator to fix anything misunderstood. Apply their corrections. The product owner reviews it again before it is accepted.
5. **Commit only when asked.** Author and timestamp come from Git history. Leave `Status: draft` until the product owner accepts it.

## Rules

- Capture intent, not design: no architecture, tech choices, or task breakdown. Those belong in Stage 2.
- Ask for the author's name and team if not known. Don't guess.
- If the source is a ticket or alert, link or quote it under **Problem**, and note the source in **Author** (e.g. `Author: alert pipeline, reviewed by <name>`).
- Keep it to one page. If the idea contains several separable outcomes, propose splitting into separate intents.

## Template

```markdown
# Intent: <short title>
Author: <name> (<team>). Status: draft.
## Problem
<What can't be done today, who is affected, and the cost of leaving it.>
## Proposed outcome
<What better looks like, from the user's point of view.>
## Affected users and systems
<People, teams, and systems touched.>
## Constraints
<Hard limits: security, data, auth, compliance, timing, out-of-scope.>
## Open questions
<Things still unknown that the product owner or Design must resolve.>
```
