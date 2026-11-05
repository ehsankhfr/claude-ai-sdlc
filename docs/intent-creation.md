# How an intent is created

An `intent.md` is a short proto-spec that says what is wanted, why, and under which constraints, in the originator's own terms. It is the first artifact in the AI-native SDLC (Stage 1) and feeds Stage 2 (Design). Approval is covered separately in [intent-approval.md](intent-approval.md).

## Where an intent comes from

| Route | Example | Who starts it |
|---|---|---|
| A person has an idea | A claims manager wants customers to check claim status themselves | The originator |
| A ticket is filed | A request lands in Jira or another tracker | Whoever picks up the ticket |
| An incident is surfaced | An alert shows a recurring failure | Whoever is on point for the alert |

The steps are the same for all three. Whatever the source, a person (the originator or product owner) reviews and corrects the agent-written `intent.md` before it is committed.

## Creating one

You need Claude access and the `capture-intent` skill ([.claude/skills/capture-intent/SKILL.md](../.claude/skills/capture-intent/SKILL.md)). No Git knowledge is needed if a GitHub connector is set up. Claude can commit on your behalf.

1. **Describe the problem in your own words.** Run `/capture-intent` followed by your description, or say "write this up as intent.md". No formal language is needed. Cover what you can:
   - what you can't do today, and who is affected
   - what better looks like
   - limits such as security, data, existing systems, or deadlines
   - what is out of scope
   - your name and team, for the Author line (Claude won't guess these)
2. **Brainstorm until it is concrete.** Claude asks a few analyst-style questions at a time, covering scope, users, constraints, and how success would be measured. Answer briefly. "Not sure" is a valid answer.
3. **Claude writes the draft** to `intent/<change-slug>/intent.md` using the template. Anything still unknown is listed under **Open questions**. Claude does not invent answers to fill gaps. If you say "do as you can", it writes the draft immediately with the gaps listed.
4. **Correct the draft.** Read it and fix anything Claude misunderstood. Claude applies your corrections.
5. **Hand it to the product owner.** Commit it on a branch and open a PR. The product owner reviews it from there (see [intent-approval.md](intent-approval.md)). Author and timestamp come from Git.

## What goes in each section

```markdown
# Intent: <short title>
Author: <name> (<team>). Status: draft.
## Problem
## Proposed outcome
## Affected users and systems
## Constraints
## Open questions
```

| Section | Put here | Leave out |
|---|---|---|
| Problem | What can't be done today, who is affected, the cost of leaving it. Mark estimates as estimates. | Solutions |
| Proposed outcome | What better looks like from the user's point of view | How it will be built |
| Affected users and systems | People, teams and systems touched. Say "not yet identified" if unknown. | Guesses presented as fact |
| Constraints | Hard limits: security, data, authentication, compliance, timing, out-of-scope | Preferences that are not real limits |
| Open questions | Anything the product owner or Design must resolve | Nothing. This is where unknowns go. |

## Rules

- **Capture intent, not design.** No architecture, technology choices, or task breakdown. Those belong in Stage 2.
- **Keep the originator's vocabulary.** Don't translate it into solution language.
- **Don't invent.** If a fact wasn't given, it goes under **Open questions**.
- **Keep it to one page.** If the idea holds several separable outcomes, split it into separate intents.
- **Tickets and alerts:** quote or link the source under **Problem**, and name it on the Author line, for example `Author: alert pipeline, reviewed by <name>`.
- **Status stays `draft`** until the product owner accepts it. See [intent-approval.md](intent-approval.md).

## Where it is saved

```
intent/
  <change-slug>/
    intent.md      # created here
    spec.md        # Stage 2, later
```

Use a short kebab-case slug, one folder per change, for example `claims-status-self-service`. A worked example is [intent/claims-status-self-service/intent.md](../intent/claims-status-self-service/intent.md).

## Setup (one-time, by a technical team member)

- Create the shared intent home. For a single product this is the `intent/` folder in the product repo.
- Agree the template and keep it in the `capture-intent` skill, signed off by a lead.
- Decide who can write to `intent/`.
- Optionally connect GitHub to Claude so people without Git experience can commit from claude.ai or Cowork.

## How it is measured

- **Time to capture:** from the first conversation to a committed `intent.md`, read from Git history. The expectation is hours, not a multi-week elicitation cycle.
- **Survival rate:** the share of intents the product owner accepts into Design rather than closes.
- **Churn:** changes to `intent.md` after the first `spec.md` commit for the same change.
