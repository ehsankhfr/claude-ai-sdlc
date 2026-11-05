---
name: accept-spec
description: Help the product owner work through a draft spec.md, check it is ready, and, only on their explicit confirmation, mark it Status accepted on a PR branch. Once the spec is accepted on main, turn it into a plan.md that cites the spec's numbered requirements and areas of concern. Use when someone says "accept this spec", "is this spec ready", "plan this change", "turn the spec into a plan", or runs /accept-spec. Never marks a spec accepted without the product owner's explicit yes, and never plans from a spec that is not accepted on main.
---

# Accept spec, then plan

Take `intent/<change-slug>/spec.md` from draft to accepted, then derive `intent/<change-slug>/plan.md` from the accepted text. This is the gate between Stage 2 (Design) and Stage 3 (Build, plan mode). It has two phases, run as separate pull requests, because the plan must come from what the product owner approved and that is the text on `main`, not a branch.

Acceptance needs **two things together**: Claude's readiness check passes, and the product owner says yes, in their own words, after seeing the result. Neither is enough alone. Claude does not accept specs. Claude prepares the decision, records it, and puts it in front of the people who make it. The merge of the PR is the decision itself (see `docs/spec-creation.md`).

## Steps

1. **Pick the change and find its state.** The argument is a slug or a path. With no argument, run `bash .github/scripts/list-intents.sh`, then for each row with `spec.md` = yes, read the spec's status with `grep -m1 -E '^From:' intent/<slug>/spec.md | grep -o 'Status: [a-z]*'` and check for a `plan.md`. Show one table and ask which change. Don't guess, even when there is only one. Then route:

   | State | Do this |
   |---|---|
   | No `spec.md` | Stop. Point to `/draft-spec <slug>`. |
   | `spec.md` says `Status: draft` | **Phase A**, steps 2 to 8. |
   | `Status: accepted` here, but not on main | Stop. Its PR must be merged first. |
   | `Status: accepted` on main, no `plan.md` | **Phase B**, steps 9 to 14. |
   | `Status: accepted` on main, `plan.md` exists | Ask whether this is a revision. A revision edits `plan.md` in place so Git keeps the history. Never replace a reviewed plan wholesale. |

   "Accepted on main" means `git show main:intent/<slug>/spec.md | grep -qE '^From:.*Status: accepted'` succeeds. The status lives on the line starting `From:`, the way an intent's lives on `Author:`.

## Phase A: accept the spec

2. **Gate: the spec must still come from an accepted intent.** Run `bash .github/scripts/check-spec-gate.sh intent/<slug>/spec.md`. It must pass. If it fails, say which check failed and point to `/accept-intent <slug>`. Do not touch the intent.

3. **Confirm who is deciding.** Ask the user to confirm they are acting as the product owner for this change. You cannot verify it. Real enforcement is `CODEOWNERS` and branch protection, and `docs/enforcement.md` says whether they are set up. If the user also drafted or authored the spec, tell them GitHub will not let a PR author approve their own PR, so a second code owner must.

4. **Check the working tree.** `git status --porcelain -- intent/<slug>` must be empty. If not, say so and ask what to do. Don't build on someone's unsaved edits.

5. **Run the readiness check.** Read `spec.md` and `intent.md` in full and judge the spec against the table. Cite the line or section for every finding. Open every file the spec cites.

   | # | Check | Kind |
   |---|---|---|
   | B1 | The `From:` line names the author, team, intent commit and Status. The `Skills applied` line is present. Requirements, Design, constraints table, open questions table, areas of concern and Provenance are all present and non-empty. | Blocking |
   | B2 | The commit in "accepted at `<hash>`" is the intent text on main today: `git diff --quiet <hash> main -- intent/<slug>/intent.md`. | Blocking |
   | B3 | Every requirement is numbered and tagged `Intent` or `Derived`, and every `Derived` one has been confirmed by the product owner. | Blocking |
   | B4 | Every Constraint and every Open question in `intent.md` appears in the spec's tables. | Blocking |
   | B5 | Every area of concern has an owner and says what closes it, and has a disposition from the product owner (step 6). None is a Blocker. | Blocking |
   | B6 | Every policy domain listed as "Not available" has been seen by the product owner and accepted as unchecked, or the policy skill now exists and the spec was re-checked against it. | Blocking |
   | B7 | Nothing is invented: every file, system and endpoint named exists in the repo or intent, or is marked "not yet identified" or "proposed". | Blocking |
   | A1 | Each constraint rated Partial or Cannot be confirmed is tied to an area of concern. | Advisory |
   | A2 | Each requirement can be proven: the Testing section names a check for it, or says why none is possible yet. | Advisory |
   | A3 | If the change is higher risk by the organization's own classification, a technical lead has looked at it. | Advisory |
   | A4 | It fits two to three pages. | Advisory |
   | A5 | It contains no task breakdown, estimates or sequencing. Those belong in the plan. | Advisory |

   Verdict: **Ready** if no blocking check fails, otherwise **Not ready** with the failing checks. Advisory findings never block. They are reported so the product owner can choose to fix them.

6. **Settle the areas of concern with the product owner.** Every area of concern gets exactly one disposition, chosen **by the product owner**:
   - **Resolved.** The product owner (or the named owner, relayed by them) gives the answer. You fold it into the right requirement or design text and mark the concern closed. Use their words.
   - **Carry to plan.** The product owner accepts that the plan will carry it as a risk. For each, tell them in a sentence which steps the plan cannot start until it is closed, so the choice is informed.
   - **Blocker.** It must be closed before any plan can be written. The spec is Not ready until it is.

   You may propose a disposition and say why. You may not choose one, and you may not answer a concern yourself. If the answer isn't in the spec or given by the product owner, it is not known. Ask a few at a time, not a questionnaire, and restate how you read each answer before editing so an answer cannot land on the wrong concern. "Do as you can" is not confirmation.

   Apply only the agreed edits to `spec.md`, in place. Keep `Status: draft`, show the diff, and re-run step 5. Repeat until the verdict is Ready or the product owner stops. Do not edit `intent.md`: if the intent is wrong, the fix is a new intent PR.

7. **Present the decision.** When the verdict is Ready, show the readiness table, each concern's disposition and what the plan cannot start until it is closed, the advisory notes, the exact `From:` line before and after, and what happens next (the PR, the merge as the decision, then `/accept-spec <slug>` again for the plan). Then ask one plain question: **"Do you accept this spec into Build, and do you want me to commit it on a branch and open a PR?"** Do not ask it while the verdict is Not ready. Say what is blocking and offer to keep working.

8. **Only on an explicit yes, record it, then stop.** A yes is the product owner clearly agreeing to the question in step 7 after seeing the result. None of these count: the original request to run this skill, "looks good" about one section, "do as you can", or silence.
   - Branch `accept-spec/<slug>` from main. If the step 6 edits are already on a branch, use that one.
   - Change `Status: draft` to `Status: accepted` on the `From:` line and **nothing else on that line**.
   - Run `bash .github/scripts/check-spec-gate.sh intent/<slug>/spec.md` again, then show `git diff`.
   - Commit with a message that states the decision, the dispositions and any advisory notes left open. If a remote exists, push and open a PR into main whose description lists the concerns carried to the plan. If there is no remote, say so and stop at the local commit.
   - **Do not merge.** The merge is the acceptance and belongs to the product owner (and a second code owner if they authored the spec). Rejecting means closing the PR with a reason. Offer to draft that comment. Do not close a PR yourself unless asked.

## Phase B: turn the accepted spec into a plan

9. **Gate: the spec must be accepted on main, and unchanged.** All of these must hold, otherwise stop and say which failed:
   - `git show main:intent/<slug>/spec.md | grep -qE '^From:.*Status: accepted'` succeeds.
   - `git diff --quiet main -- intent/<slug>/spec.md` and `git status --porcelain -- intent/<slug>` is empty, so the plan comes from the text the product owner accepted.
   - `bash .github/scripts/check-spec-gate.sh intent/<slug>/spec.md` passes.

   **Do not offer to "just proceed" from a draft spec.** A plan drafted from a spec that is not accepted is out of process. If a problem is found in the spec while planning, stop and say so. The fix is a revision to the spec through its own PR, not a workaround in the plan.

10. **Read the spec and the codebase.** Read `spec.md` completely: Requirements, Design, Testing, and above all the areas of concern, with the product owner's dispositions in the accepting PR. Open every file you intend to list. Don't describe code from memory. Where the spec says a location is "not yet identified", it is still not identified.

11. **Write `intent/<change-slug>/plan.md`** with the template below.

12. **Check your own work.** Fix the plan until all of these hold:
    - Every requirement R1 to Rn appears in at least one step and in Proof, or is listed as "not plannable yet" with the concern that blocks it.
    - Every area of concern carried from the spec appears under Risks with the steps it affects and what closes it.
    - Every step cites at least one requirement. A step that cites none is scope the spec did not ask for. Remove it, or raise it as a spec gap.
    - Every path under Files that change exists, or is marked `(new)`, or is marked "location not yet identified" with its concern.
    - Steps that cannot start are marked `Blocked: concern N`, and the unblocked steps are ordered so work can begin without them.
    - Each file line names the step that touches it. Steps that share no file and do not depend on each other get different stream letters (A, B), so the engineer can run them in separate worktrees (see `docs/parallel-sessions.md`). Steps that share a file stay in one stream. If everything shares a file, say there is one stream. Do not split work to make it look parallel.

13. **Hand it back.** Lead with what is blocked and by which concern, then what you assumed, then what the reader must decide. Ask them to correct anything misunderstood, and apply the corrections to the same file. The engineer who will build it reviews the plan against the spec, line by line.

14. **Commit only when asked.** If asked: branch `plan/<slug>` from main, commit `plan.md` alone, and open a PR into main. If local main holds commits that are not on `origin/main` and do not belong in this PR, base the branch on `origin/main`. Never commit to main directly, never touch `spec.md` or `intent.md`, and leave `Status: draft`. Write no source code in this skill. Building starts after the plan is reviewed.

## Rules

- **No yes, no change of status.** The only edit to a spec's `Status` is step 8, after the product owner's explicit yes in this conversation.
- **Don't answer for the product owner.** Don't resolve a concern from the repo, from examples, or from what seems likely. An unanswered concern is carried or blocks. It is never guessed.
- **Don't soften the check to get a yes.** Report what fails. If the product owner still wants to accept past a blocking finding, tell them you won't mark it accepted and that they can set the status in the PR themselves. That is their call, and it is visible in Git.
- **Don't invent.** Never import files, endpoints, systems, numbers or states from examples, other projects or memory. An unidentified location is "not yet identified" and the step that needs it is blocked.
- **The plan adds no scope.** It says how and in what order to meet the spec's requirements. It does not change them.
- **Edit the minimum.** Meaning changes only when the product owner says so. Show the diff.
- **Never push, open a PR or merge on your own.** Step 8 asks for the PR in the same question. The merge is never yours.

## Report template (step 7)

```markdown
## Readiness: <slug>
Verdict: <Ready | Not ready: n blocking>

| # | Check | Result | Where |
| :-- | :---- | :----- | :---- |
| B1 | Header and sections complete | Pass / Fail | <section or line> |
| ... | ... | ... | ... |

### Areas of concern
| # | Concern | Disposition | Note |
| :-- | :---- | :---- | :---- |
| 1 | <title> | Resolved / Carry to plan / Blocker | <folded into R<n>, or what the plan cannot start until it is closed> |

### Advisory
- <finding, section>

### Accepting changes
- Before: `From: <...>. Status: draft.`
- After:  `From: <...>. Status: accepted.`
- Other edits: <diff summary or "none">
```

## plan.md template (step 11)

Short enough to review against the spec line by line. R numbers and concern numbers are the spec's, so a reviewer can check each citation.

```markdown
# Plan: <short title, same as the spec>
From: [spec.md](spec.md), accepted at <short commit hash>. Status: draft.

## Files that change
<One line each: path, then (new) or what changes, then the step number. "Location not yet identified (concern N)" where the spec does not say.>

## Order of work
1. <step> (R1, R2). Stream A.
2. <step> (R4). Stream A. Blocked: concern N.
3. <step> (R5). Stream B.

## Risks
<Each carried concern: its number, the steps it affects, what closes it, owner.>

## Proof
<The test or check for each requirement, citing R numbers. Say which cannot be proven yet and why.>
```
