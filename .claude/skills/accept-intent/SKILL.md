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

1. **Pick the intent.** The argument is a slug or a path. With no argument, list the `intent/*/intent.md` files whose `Author:` line says `Status: draft` and ask which one. Don't guess.
   - If it already says `Status: accepted`, say so and stop.

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

6. **Apply agreed edits.** Edit `intent.md` only for what the product owner agreed: answers folded in, wording corrected, constraints moved. Keep the edit small, keep the Status as `draft` for now, and re-run the readiness check. Repeat steps 4 to 6 until the verdict is Ready or the product owner stops.

7. **Present the decision.** When the verdict is Ready, show:
   - the readiness table with every check's result
   - the open questions and their dispositions, and what is being carried to Design
   - advisory notes
   - what accepting changes: the exact `Author:` line before and after, and the diff of anything else
   - what happens next: the PR, the merge as the decision, and that Stage 2 (`/draft-spec`) starts from the accepted text

   Then ask one plain question: **"Do you accept this intent into Design, and do you want me to commit it on a branch and open a PR?"** Do not ask it while the verdict is Not ready. In that case say what is blocking and offer to keep working.

8. **Only on an explicit yes, record it.** A yes is the product owner clearly agreeing to the question in step 7, after they saw the result. None of these count: the original request to run this skill, "looks good" about one section, "do as you can", or silence. If they hesitate, ask what is missing or leave it as `draft`.
   - Create a branch `accept/<slug>` from the main branch. If the edits from step 6 are already on a branch, use that one.
   - Change `Status: draft` to `Status: accepted` on the `Author:` line and **nothing else on that line**, so the check script keeps reading it.
   - Run `bash .github/scripts/check-intent-status.sh intent/<slug>/intent.md`. It must pass.
   - Show `git diff`, then commit with a message that states the decision, the dispositions, and any advisory notes left open.
   - If a remote exists, push and open a PR into main. Its description lists the open questions carried to Design and the advisory notes. If there is no remote, say so and stop at the local commit.

9. **Stop there.** Do not merge. The merge is the acceptance, and it belongs to the product owner (and a second code owner if the author is the product owner). Tell them how: merge the PR, or if there is no remote, the local merge command and that it records an author and timestamp but no separate reviewer.

## If the product owner does not accept

Change nothing beyond edits they agreed, and leave `Status: draft`. Rejecting means closing the PR with a reason (see `docs/intent-approval.md`). If they want, draft that comment for them. Do not close a PR yourself unless asked.

## Rules

- **No yes, no change of status.** The only edit to the `Status` is the one in step 8, after the product owner's explicit yes in this conversation.
- **Don't answer for the product owner.** Don't fill an open question from the repo, from examples, or from what seems likely. An unanswered question is carried or blocks, it is never guessed.
- **Don't soften the check to get a yes.** Report what fails. Don't downgrade a blocking finding to advisory because it is inconvenient. If the product owner disagrees with a finding, they can fix the text or reclassify the question. If they still want to accept past a blocking finding, tell them you won't mark it accepted and that they can set the status in the PR themselves. That is their call, and it is visible in Git.
- **Capture intent, not design.** Never add architecture, technology or tasks while editing. Design is Stage 2.
- **Edit the minimum.** Meaning changes only when the product owner says so. Show the diff.
- **Never push, open a PR or merge on your own.** Step 8 asks for the PR in the same question. The merge is never yours.

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
