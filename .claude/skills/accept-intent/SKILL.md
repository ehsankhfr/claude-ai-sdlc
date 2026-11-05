---
name: accept-intent
description: Help the product owner close the gaps in a draft intent.md, check it is ready, and, only on their explicit confirmation, mark it Status accepted on a PR branch. Use when the product owner says "review this intent", "accept this intent", "is this intent ready", or runs /accept-intent. Never marks an intent accepted without the product owner's explicit yes.
---

# Accept intent

Take a draft `intent/<change-slug>/intent.md` to accepted, with the product owner. This is the gate between Stage 1 (Intent) and Stage 2 (Design). Acceptance needs **two things together**:

1. **Claude's readiness check passes.** The gaps are filled or deliberately carried forward, and nothing blocking is left.
2. **The product owner says yes.** In their own words, in this conversation, after seeing the result of the check.

Neither is enough alone. A passing check is not a decision, and a product owner's yes does not clear a blocking gap. Claude does not accept intents. Claude prepares the decision, records it, and puts it in front of the people who make it. The merge of the PR is the decision itself (see `docs/intent-approval.md`).

## Steps

1. **Pick the intent.** The argument is a slug or a path. With no argument, run `bash .github/scripts/list-intents.sh` and show the table. It is the same table `/draft-spec` shows, so both skills describe the same state. Offer the intents whose **Next** column says `/accept-intent <slug>` and ask which one. Don't guess, even when there is only one. For an intent the table sends elsewhere, say where.
   - If it already says `Status: accepted`, say so and stop. Point to what comes next: `/draft-spec <slug>` if it is accepted on main, or merging its PR first if it is not on main yet.
   - An intent still in its first PR (from `capture-intent`) is not in a checkout of `main`. Check out that PR's branch first (`gh pr checkout <number>`), then run this skill.

2. **Confirm who is deciding.** Ask the user to confirm they are acting as the product owner for this intent. You cannot verify it. Real enforcement is `CODEOWNERS` and branch protection, and docs/intent-approval.md says whether those are set up. If the user is also the intent's author, tell them GitHub will not let an author approve their own PR, so a second code owner must.

3. **Check the working tree.** `git status --porcelain` must show no uncommitted change to this intent. If it does, say so and ask what to do. Don't build on top of someone's unsaved edits.

4. **Run the readiness check.** Read the whole intent and judge it against the table below. Cite the line or section for every finding.

   | # | Check | Kind |
   |---|---|---|
   | B1 | All five sections (Problem, Proposed outcome, Affected users and systems, Constraints, Open questions) are present and non-empty. The `Author:` line has a name and team. | Blocking |
   | B2 | Every open question has a disposition, and none is a Blocker (see step 5). | Blocking |
   | B3 | Problem, Outcome and Constraints do not contradict each other. | Blocking |
   | B4 | No design decision is hiding in the intent as if it were settled: architecture, technology, or a named solution. If it is a real limit, it belongs under Constraints. Otherwise it goes. | Blocking |
   | B5 | The intent is one outcome. If it holds several separable outcomes, the product owner has decided to split it or keep it together. | Blocking |
   | A1 | Estimates and unmeasured figures are marked as such. | Advisory |
   | A2 | Every constraint is specific enough that a spec could be checked against it. | Advisory |
   | A3 | Something unidentified under Affected users and systems (a system, an owner) also appears as an open question, so it is not lost. | Advisory |
   | A4 | There is a way to tell success, or how to measure it is an open question. | Advisory |
   | A5 | It fits on one page. | Advisory |

   Verdict: **Ready** if no blocking check fails, otherwise **Not ready** with the failing checks listed. Advisory findings never block. They are reported so the product owner can choose to fix them.

5. **Settle the open questions with the product owner.** Every question under **Open questions** gets exactly one disposition, chosen **by the product owner**:
   - **Answered.** The product owner gives the answer. You fold it into the right section (Problem, Proposed outcome, Affected users and systems, or Constraints) and remove the question. Use their words and the originator's vocabulary.
   - **Carry to Design.** The product owner accepts that Design will resolve it. The question stays under Open questions. For each one, tell them in a sentence what Design cannot settle until it is answered, so the choice is informed.
   - **Blocker.** It must be answered before Design can start. The intent is Not ready until it is answered or reclassified.

   You may propose a disposition and say why. You may not choose one, and you may not answer a question yourself. If the answer isn't in the intent or given by the product owner, it is not known. Ask a few questions at a time, not a questionnaire. If the product owner says "do as you can", propose dispositions and edits for their review. That is not confirmation.

6. **Apply agreed edits.** Edit `intent.md` only for what the product owner agreed: answers folded in, wording corrected, constraints moved. Keep the edit small, keep the Status as `draft` for now, and re-run the readiness check. Repeat steps 4 to 6 until the verdict is Ready or the product owner stops. Land each round of edits as a PR before the turn ends (step 8, part A), so they are never only in the working copy.

7. **Present the decision.** When the verdict is Ready, show:
   - the readiness table with every check's result
   - the open questions and their dispositions, and what is being carried to Design
   - advisory notes
   - what accepting changes: the exact `Author:` line before and after, and the diff of anything else
   - what happens next: the PR, the merge as the decision, and that Stage 2 (`/draft-spec`) starts from the accepted text

   Say that the agreed edits are already in a draft PR, and that only a yes sets `Status: accepted`. Then ask one plain question: **"Do you accept this intent into Design?"** Do not ask it while the verdict is Not ready. In that case say what is blocking and offer to keep working.

8. **Land every change as a PR. Set accepted only on an explicit yes.** These are two separate things.
   - **A. The PR, always.** Whenever this skill has changed `intent.md`, land it before the turn ends, following "How skill changes land" in `CLAUDE.md`. Branch `accept/<slug>`, or `intent/<slug>` if `origin/intent/<slug>` exists because the intent is still in its first PR. Commit `intent.md` alone. Open a **draft** PR, or add a commit to the one that exists. The description lists the open questions and their dispositions so far. This happens whatever the product owner decided, so agreed edits are never left in the working copy.
   - **B. The status, only on a yes.** A yes is the product owner clearly agreeing to the question in step 7, after they saw the result. None of these count: the original request to run this skill, "looks good" about one section, "do as you can", or silence. If they hesitate, ask what is missing or leave it as `draft`. On a yes:
     - Change `Status: draft` to `Status: accepted` on the `Author:` line and **nothing else on that line**, so the check script keeps reading it.
     - Run `bash .github/scripts/check-intent-status.sh intent/<slug>/intent.md`. It must pass.
     - Show `git diff`, then commit on the same branch with a message that states the decision, the dispositions, and any advisory notes left open.
     - Push, mark the PR ready (`gh pr ready`), and update its description to list the open questions carried to Design and the advisory notes.

9. **Stop there.** Do not merge. The merge is the acceptance, and it belongs to the product owner (and a second code owner if the author is the product owner). Tell them how: review and merge the PR. If there is no remote, say the change has not landed (see `CLAUDE.md`). A local merge would record an author and timestamp but no separate reviewer.

## If the product owner does not accept

Change nothing beyond edits they agreed, and leave `Status: draft`. Those edits are already in the draft PR (step 8, part A), so nothing is lost. Rejecting means closing that PR with a reason (see `docs/intent-approval.md`). If they want, draft that comment for them. Do not close a PR yourself unless asked.

## Rules

- **No yes, no change of status.** The only edit to the `Status` is the one in step 8, after the product owner's explicit yes in this conversation.
- **Don't answer for the product owner.** Don't fill an open question from the repo, from examples, or from what seems likely. An unanswered question is carried or blocks, it is never guessed.
- **Don't soften the check to get a yes.** Report what fails. Don't downgrade a blocking finding to advisory because it is inconvenient. If the product owner disagrees with a finding, they can fix the text or reclassify the question. If they still want to accept past a blocking finding, tell them you won't mark it accepted and that they can set the status in the PR themselves. That is their call, and it is visible in Git.
- **Capture intent, not design.** Never add architecture, technology or tasks while editing. Design is Stage 2.
- **Edit the minimum.** Meaning changes only when the product owner says so. Show the diff.
- **Every change to the intent ends in a PR, and the merge is never yours.** Landing the PR is part of this skill (step 8, part A) and needs no separate ask. Merging, and closing a PR, are not part of it.

## Report template

```markdown
## Readiness: <slug>
Verdict: <Ready | Not ready: n blocking>

| # | Check | Result | Where |
| :-- | :---- | :----- | :---- |
| B1 | Sections complete, author and team named | Pass / Fail | <section or line> |
| ... | ... | ... | ... |

### Open questions
| Question | Disposition | Note |
| :---- | :---- | :---- |
| <text> | Answered / Carry to Design / Blocker | <answer folded into <section>, or what Design cannot settle until answered> |

### Advisory
- <finding, section>

### Accepting changes
- Before: `Author: <...>. Status: draft.`
- After:  `Author: <...>. Status: accepted.`
- Other edits: <diff summary or "none">
```
