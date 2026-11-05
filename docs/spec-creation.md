# How an accepted intent becomes a spec

A `spec.md` turns an accepted intent into requirements and design that engineering can plan against, with the areas of concern flagged. It is the second artifact in the AI-native SDLC (Stage 2). Claude writes it. The product owner reviews it and doesn't write it. Acceptance of the spec starts Stage 3 (Build, plan mode).

## When it starts

Only from an intent that is accepted. See [intent-approval.md](intent-approval.md): the intent is merged into `main` with `Status: accepted`. The `draft-spec` skill checks this itself and refuses to run otherwise. It will not change the status for you, because acceptance is the product owner's decision.

## Who runs it

Anyone with Claude access and this repo: typically the engineer picking the change up, or the product owner. Neither needs to write the spec by hand.

## Running it

The skill is [.claude/skills/draft-spec/SKILL.md](../.claude/skills/draft-spec/SKILL.md).

1. Make sure you are on a current checkout of `main` with the accepted intent.
2. Run `/draft-spec <change-slug>`, for example `/draft-spec claims-status-self-service`. Or say "draft the spec for claims-status-self-service". With no slug, Claude lists accepted intents that have no spec yet.
3. Claude checks the gate, reads the intent and the codebase, finds and applies the organization's policy skills, and writes `intent/<change-slug>/spec.md`.
4. Claude reports back, with the areas of concern first, what it assumed, and what the product owner must decide.
5. Correct anything misunderstood. Claude applies the corrections to the same file.
6. Ask Claude to commit it on a branch `spec/<change-slug>` and open a PR. Git records the author and timestamp.

## What Claude does and doesn't do

| Does | Doesn't |
|---|---|
| Stops if the intent is not accepted, or differs from what is on `main` | Edit the intent, or mark it accepted |
| Describes the codebase from files it has read | Describe systems from memory or examples |
| Applies each policy skill it finds and names it in the spec | Treat a missing policy as "checked and fine" |
| Raises policy clashes with both sides, a proposal and an owner | Pick a winner silently |
| Marks unknowns "not yet identified" and carries open questions forward | Invent systems, numbers or states to fill gaps |
| Proposes the smallest scope that meets the intent | Break the work into tasks. That is the plan in Stage 3 |
| Refuses to overwrite an existing `spec.md` | Replace a reviewed spec wholesale |

## What goes in the spec

| Section | Contains |
|---|---|
| Header | Source intent and its commit, status, the skills applied, and which policy domains had no skill |
| Requirements | Numbered, each tagged `Intent` (stated in the intent) or `Derived` (added, to be confirmed) |
| Design | What exists in the repo today, components and boundaries, contracts, data handling, error states, measurement, tests |
| How each constraint is met | One row per intent constraint, with a confidence rating |
| Open questions | Every question from the intent, answered or carried forward |
| Areas of concern | What blocks planning, ordered, each with a proposed owner |
| Provenance | The prompt, the skill versions in force, the intent commit |

## Review

The product owner reviews the spec against the idea, in this order:

1. **Work through the areas of concern first.** They are the points an analyst would have escalated. Resolve each with its owner before engineering sees the spec.
2. **Check the spec solves the stated problem.** Compare it with the intent's Problem and Proposed outcome.
3. **Check every open question** is answered or deliberately carried forward.
4. **Read the header.** Any policy domain listed under "Not available" has not been checked. Decide whether that is acceptable.
5. **Consult a technical lead** for anything the organization classes as higher risk.

Then:

- **Accept:** set `Status: accepted` in the PR and merge. A human teammate always makes this call. This starts Stage 3.
- **Reject or rework:** comment on the PR and have Claude revise the same file. If the problem is in the intent, open a new intent PR. Don't patch around it in the spec.

## Setup (one-time, by a technical team member)

- Provide the organization's brand, security, compliance and UX policies as skills, and make them available wherever `/draft-spec` is run. **Until they exist, every spec will say they were not applied.**
- Extend [.github/CODEOWNERS](../.github/CODEOWNERS) so the product owner reviews `spec.md` files too.
- Decide who owns each policy skill, so concerns have a named owner to route to.

## Not built yet

- **No enforcement that `spec.md` is accepted before Stage 3.** The `intent-status` check covers `intent.md` only. The same check could be extended to `spec.md`, which needs a stable `Status` line the script can read.
- **Not automated.** The lesson's next step is a non-interactive job that fires when an intent is merged and opens the spec PR. That needs a remote, a CI secret for Claude access, and the policy skills available to the job. Run it by hand first.
- **The skill has not been exercised end to end on an accepted intent.** The gate was tested only against the current draft, which it correctly rejects.

## How it is measured

- **Time to spec:** the gap between the `intent.md` accepting commit and the `spec.md` commit for the same change, read from Git timestamps.
- **Spec rework:** `spec.md` commits dated after the first `plan.md` commit for the same change. Each one is a requirement or design problem found during build.
- **Concern yield:** how many areas of concern were resolved before build against how many surfaced during it. Read from the PR review.
