# How an intent becomes approved

An intent is **approved when it is merged into `main`** with `Status: accepted`. The merge is the decision. The `Status` line mirrors it so readers can see the state without opening Git.

This applies to every `intent/<change-slug>/intent.md`, whether it started as a person's idea, a ticket, or an alert.

## States

| State | Where it lives | `Status` line | Git record |
|---|---|---|---|
| Proposed | A branch with an open PR | `draft` | PR open, no decision |
| Approved | `main` | `accepted` | PR merged: reviewer and timestamp recorded |
| Rejected | Never reaches `main` | `draft` (unchanged) | PR closed without merging |

Stage 2 (Design) starts only from intents on `main` with `Status: accepted`.

## Steps

1. **Propose.** Put the intent on a branch with `Status: draft` and open a PR. People without Git experience can ask Claude to do this through a GitHub connector.
2. **Review.** The product owner reads it, corrects anything wrong (edit directly or comment on the PR), and checks that the **Open questions** are acceptable to carry into Design.
3. **Mark accepted.** Change `Status: draft` to `Status: accepted` inside the PR, either by editing it or by asking Claude to. The status change is then part of the reviewed diff.
4. **Merge.** Approve and merge the PR. Git records who merged it and when.
5. **Reject instead.** If the intent should not go ahead, close the PR without merging and say why in a comment. Rejected intents stay out of `main` and need no status value.

## Accepting with Claude

The product owner can run `/accept-intent <change-slug>` ([.claude/skills/accept-intent/SKILL.md](../.claude/skills/accept-intent/SKILL.md)) to do steps 2 to 3 above with Claude's help. Acceptance needs **both** of these:

1. **Claude's readiness check passes.** Claude checks the intent against the table below and reports what is missing, citing the line.
2. **The product owner explicitly says yes**, in the conversation, after seeing the result.

Claude never accepts on its own and never merges. After the yes it sets `Status: accepted` on a branch, commits, and opens the PR if there is a remote. The product owner still merges it, and the merge is the decision.

| # | Check | Kind |
|---|---|---|
| B1 | All five sections are present and non-empty. The Author line names a person and team. | Blocking |
| B2 | Every open question has a disposition chosen by the product owner, and none is a Blocker. | Blocking |
| B3 | Problem, Outcome and Constraints do not contradict each other. | Blocking |
| B4 | No design decision is hiding in the intent as if it were settled. | Blocking |
| B5 | It is one outcome, or the product owner has decided on a split. | Blocking |
| A1 | Estimates are marked as estimates. | Advisory |
| A2 | Constraints are specific enough to check a spec against. | Advisory |
| A3 | Unidentified systems or owners also appear as open questions. | Advisory |
| A4 | Success can be told, or how to measure it is an open question. | Advisory |
| A5 | It fits on one page. | Advisory |

Each open question gets one disposition from the product owner:

| Disposition | Meaning | Effect |
|---|---|---|
| Answered | The product owner supplies the answer | Folded into the intent body, question removed |
| Carry to Design | Design will resolve it, and the product owner accepts that | Stays under Open questions. Claude states what Design cannot settle until it is answered |
| Blocker | Must be answered before Design | The intent is not ready until it is answered or reclassified |

Not every question has to be answered. An intent can be accepted with questions carried to Design, as long as the product owner has chosen that for each one.

Limits:

- Claude cannot verify the person is the product owner. `CODEOWNERS` and branch protection do that, and they are not set up yet (see above).
- Claude will not mark an intent accepted over a failing blocking check. The product owner can still set the status in the PR themselves. Git shows who did.

## What the record shows

- **Author and timestamp:** from the first commit.
- **Corrections:** the revision history of `intent.md`, including the product owner's edits.
- **Decision:** the merge, or the closed PR, with the reviewer and time.

This is the governance evidence. The survival rate (merged intents against closed ones) is read from the same record.

## Setup required for this to hold

Git does not enforce approval by default. Three pieces make the rule hold:

| Piece | Where | State |
|---|---|---|
| The product owner is code owner of `intent/` | [.github/CODEOWNERS](../.github/CODEOWNERS) | Written, but the owner line is commented out until the product owner's GitHub username or team is filled in. **Until then, nothing requires their review.** |
| An `intent-status` check fails unless every changed intent is `Status: accepted` | [.github/workflows/intent-status.yml](../.github/workflows/intent-status.yml), [.github/scripts/check-intent-status.sh](../.github/scripts/check-intent-status.sh) | Written. The script is tested locally. The workflow runs once the repo is on GitHub. |
| Branch protection on `main` | GitHub repository settings | **Not set up.** It needs a remote and a repo admin. Without it, the first two pieces can be bypassed. |

### Branch protection settings

A repo admin sets these on `main` in GitHub:

- Require a pull request before merging. This also blocks direct pushes.
- Require approvals (at least 1) and require review from Code Owners.
- Require status checks to pass, with `intent-status` selected.
- Do not allow bypassing these settings, including for admins.

Notes:

- The code owner needs write access to the repo.
- GitHub does not let a PR author approve their own PR. If the product owner writes an intent, a second code owner has to approve it.
- The `intent-status` workflow has no path filter on purpose. A required check that is filtered out never reports, and it would leave unrelated PRs waiting.
- This repo currently has no remote, so there is nowhere to open a PR. Until one is added, merging locally records an author and timestamp but not a separate reviewer.

## How the pieces work together

- A PR that adds or changes an intent shows a failing `intent-status` check while it says `draft`. The check passes once the product owner sets `Status: accepted` in the PR. That failure is expected.
- A product owner's approval is required by CODEOWNERS and branch protection. The check alone does not prove they approved, because anyone could write `accepted` into the file.
- On `main`, the check runs on every push and requires all intents to be `accepted`. It cannot block a direct push, because it runs after it. Branch protection is what blocks direct pushes.

## Known gaps

- **`accepted` is a project convention.** Only `draft` is defined in the source lesson. Your team should confirm the values.
- **The check reads one line.** It looks for `Status: accepted` on the line starting `Author:`. If the template changes shape, update [.github/scripts/check-intent-status.sh](../.github/scripts/check-intent-status.sh) and [.github/scripts/list-intents.sh](../.github/scripts/list-intents.sh), which the two skills use to list intents.
- **Not tested on GitHub.** The script and the YAML syntax were checked locally. The workflow itself has not run on GitHub yet.
