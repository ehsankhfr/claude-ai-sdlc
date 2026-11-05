# Intent

The shared, version-controlled home for `intent.md` files. This is where the AI-native SDLC starts. The product owner watches this folder.

## Layout

```
intent/
  <change-slug>/
    intent.md      # Stage 1: what is wanted, why, under which constraints
    spec.md        # Stage 2: requirements and design, derived from an accepted intent.md
```

One folder per change, so the artifact chain stays together next to the code derived from it.

## What happens after acceptance

Once an intent is accepted, anyone with Claude access runs `/draft-spec <change-slug>` to produce `spec.md`. The skill refuses to run on an intent that is not accepted. Full detail: [docs/spec-creation.md](../docs/spec-creation.md).

## How an intent gets here

Full detail: [docs/intent-creation.md](../docs/intent-creation.md).

1. Someone has an idea, a ticket is filed, or an alert surfaces an incident.
2. They brainstorm with Claude using the `capture-intent` skill (`.claude/skills/capture-intent/`).
3. The originator corrects the draft. The product owner reviews it.
4. It is committed here. Author and timestamp come from Git.
5. The product owner accepts it into Design (merge) or rejects it (close the review).

## Approval

The product owner approves an intent in Git. No separate form is needed. Full detail: [docs/intent-approval.md](../docs/intent-approval.md).

1. **Propose:** the intent goes on a branch and a pull request is opened into the main branch. Claude can do this for people without Git experience through a GitHub connector.
2. **Review:** the product owner reads it, corrects anything wrong (edit directly or comment on the PR), and checks that **Open questions** are acceptable to carry into Design.
3. **Decide:**
   - **Accept:** merge the PR. This sends the intent into Stage 2 (Design). Set `Status: accepted` as part of the merge.
   - **Reject:** close the PR without merging.
4. **Record:** the author, timestamp, revision history and the merge or close decision live in Git history. That is the governance evidence.

### Setup (one-time, by a technical team member)

- Decide who can write to this folder.
- Require product owner review before merge, for example with branch protection or a `CODEOWNERS` entry for `intent/`.
- Agree the `Status` values. This repo uses `draft` and `accepted`. Rejected intents are closed rather than merged, so they need no status.

## Measuring

- **Time to capture:** first conversation to committed `intent.md`, read from Git history.
- **Survival rate:** share of intents accepted into Design rather than closed.
- **Churn:** changes to `intent.md` after the first `spec.md` commit for the same change.
