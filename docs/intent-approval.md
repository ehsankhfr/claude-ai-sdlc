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
- **The check reads one line.** It looks for `Status: accepted` on the line starting `Author:`. If the template changes shape, update [.github/scripts/check-intent-status.sh](../.github/scripts/check-intent-status.sh).
- **Not tested on GitHub.** The script and the YAML syntax were checked locally. The workflow itself has not run on GitHub yet.
