---
name: draft-spec
description: Turn an accepted intent.md into a requirements and design spec.md, applying the organization's policy skills and flagging areas of concern. Use when an engineer or product owner says "draft the spec for <slug>", "turn this intent into a spec", or runs /draft-spec. Refuses to run on an intent that is not accepted.
---

# Draft spec

Produce `intent/<change-slug>/spec.md` from an accepted `intent.md`: requirements and design in one pass, constrained by the organization's policy skills, with areas of concern flagged. This is Stage 2 of the AI-native SDLC. Its output is reviewed by the product owner and, once accepted, feeds Stage 3 (Build, plan mode).

The product owner reviews the spec. They do not write it. Your job is a spec engineering can plan against, with every unknown and every policy clash visible instead of quietly resolved.

## Steps

1. **Pick the intent.** The argument is a slug (`claims-status-self-service`) or a path. With no argument, run `bash .github/scripts/list-intents.sh` and show the table. It is the same table `/accept-intent` shows, so both skills describe the same state. Offer the intents whose **Next** column says `/draft-spec <slug>` (accepted on main, no `spec.md`) and ask which one. Don't guess, even when there is only one. For an intent the table sends elsewhere, say where: a draft goes to `/accept-intent <slug>`, and one accepted only on a branch needs its PR merged first. Intents that already have a `spec.md` are not offered, except to revise (step 3).

2. **Gate: the intent must be accepted.** Both checks must pass, otherwise stop:
   - `bash .github/scripts/check-intent-status.sh intent/<slug>/intent.md` passes. This is the same rule CI uses (`Status: accepted` on the `Author:` line).
   - The accepted text is the text on the main branch: `git show main:intent/<slug>/intent.md` exists and also has `Status: accepted`, and the working copy has no uncommitted change to `intent.md` (`git status --porcelain -- intent/<slug>/intent.md` is empty). If they differ, say so and stop. The spec must be derived from what the product owner approved.

   If the gate fails, tell the user which check failed and that the product owner accepts an intent by merging it with `Status: accepted` (see `docs/intent-approval.md`). Point them to `/accept-intent <slug>`, which closes the intent's gaps with the product owner. **Do not edit the intent's status, and do not offer to "just proceed".** Acceptance is a human decision. A spec drafted from a draft intent is out of process.

3. **Don't overwrite.** If `spec.md` already exists, stop and ask whether this is a revision. A revision edits the file in place so Git keeps the history. Never replace a reviewed spec wholesale.

4. **Read the intent and the codebase.**
   - Read `intent.md` completely. Constraints and Open questions drive the spec.
   - Read enough of the repo to say what exists today: structure, stack and versions, auth, API layer, tests, conventions (`CLAUDE.md`, `README.md`, `docs/`). Open the files you cite. Don't describe code from memory.
   - Note what the intent refers to that is **not** in the repo (systems, services, login). That is a finding, not something to fill in.

5. **Find and apply the policy skills.**
   - Look through the available skills for the organization's brand, security, compliance and UX policies. Read each one that applies and use it as a constraint on the spec.
   - Record each skill you applied by exact name (and version if it has one).
   - For each of the four domains with no skill, write "not available" in the spec header **and** raise an areas-of-concern item. Where you fall back on general good practice, label it as general practice, not as the organization's policy. Silence about a policy must never read as "checked and fine".

6. **Write `intent/<change-slug>/spec.md`** using the template below, following the rules.

7. **Check your own work before handing over.** Fix the spec until all of these hold:
   - Every item under the intent's **Constraints** appears in the constraints table.
   - Every item under the intent's **Open questions** appears in the open questions table as answered (with reasoning) or carried forward (with an area of concern).
   - Every requirement is numbered and tagged `Intent` or `Derived`.
   - Every area of concern has an owner and says what is needed to close it.
   - Every file, system and endpoint named exists in the intent or the repo, or is marked "not yet identified" or "proposed".
   - No task breakdown, estimates or sequencing. That is the plan in Stage 3.

8. **Hand it back.** Lead with the areas of concern, then what you assumed, then what the product owner must decide. Say plainly which policy domains were not checked. Then ask the reader to correct anything misunderstood and apply the corrections.

9. **Commit only when asked.** If asked: branch `spec/<slug>`, commit `spec.md` alone, open a PR into main. Never commit to main directly and never touch `intent.md`. The product owner reviews and merges. Leave `Status: draft` until they accept it.

## Rules

- **Don't invent.** If the intent or repo doesn't say, it is "not yet identified" or an open question. Never import system names, endpoints, numbers or states from examples, other projects or memory. A confident but fabricated detail is the worst failure of this stage.
- **Don't resolve policy clashes silently.** When two policies pull against each other, or a policy clashes with a constraint, do not pick a winner. Name both sides, cite the skill or constraint, propose a way through, and name the owner.
- **Don't change the intent.** If the intent looks wrong or incomplete, raise it as an area of concern. Fixing it is a new intent PR.
- **Smallest scope that meets the intent.** Where the intent leaves scope open, propose the smaller option, mark it as a proposal, and put the decision to the product owner.
- **Requirements say what, not how.** Design says how, at the level of components, boundaries, contracts and data handling. Not tasks.
- **Write for the product owner.** They are not necessarily an engineer. Plain language, define terms, keep each concern short and concrete.
- **Keep it reviewable.** Aim for two to three pages. Move detail into the design only when engineering needs it to plan.

## Template

```markdown
# Spec: <short title, same as the intent>
From: [intent.md](intent.md) (<author>, <team>), accepted at <short commit hash>. Status: draft.
Skills applied: <exact skill names, or "none">. Not available: <policy domains with no skill, or "none">.

## Requirements
Numbered so the plan and review can cite them. `Intent` = stated in intent.md. `Derived` = added by this spec, to be confirmed.
- R1. <what the system must do or ensure.> *(Intent: <which section>.)*
- R2. ...

## Design
<What exists today in the repo, in a few lines. Then components and boundaries, the contracts between them, data handling, error and empty states, how success is measured, how it is tested. Mark anything unidentified.>

## How each constraint in the intent is met
| Constraint | Met by | Confidence |
| :---- | :---- | :---- |
| <from intent.md> | <requirement or design element> | <Full / Partial / Cannot be confirmed, and why> |

## Open questions from the intent
| Question | State |
| :---- | :---- |
| <from intent.md> | <Answered: how and why. Or: Carried forward as concern N. Or: Needs product owner decision.> |

## Areas of concern
Ordered by how much they block planning. Owners are proposed.
1. **<Short title.>** <What the problem is, in plain words. Both sides, if two policies clash. What is proposed. What is needed to close it.> Owner: <role or team>.

## Provenance
- Prompt: <name of this skill and any extra instructions given>.
- Skills in force: <names and versions>.
- Source: intent.md at <short commit hash>.
```
