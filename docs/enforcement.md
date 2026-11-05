# What enforces the process

The skills in `.claude/skills/` tell Claude how to move a change through the stages. They are **advisory**: nothing forces a session to follow them. This page lists which rules are backed by something deterministic, where each check runs, what is not enforced yet, and what is needed to close the gaps.

The idea follows Lesson 6 (skills as institutional knowledge). A skill makes a violation unlikely. A rule that must always hold needs a check behind it: a **hook** at the edit, and **the same check on the pull request**. A required check in branch protection is what finally stops a merge.

State below was checked on 2026-11-05.

## The rules and what backs each

| Rule | Written in | Skill (advisory) | Hook (at the edit) | Pull request check | Stops a merge? |
|---|---|---|---|---|---|
| An intent is approved only when merged with `Status: accepted` | [intent-approval.md](intent-approval.md) | `accept-intent` | none | `intent-status`, step 1 | **No.** Branch protection is not set up |
| A spec comes only from an intent that is accepted on `main`, and the intent text is unchanged | [spec-creation.md](spec-creation.md) | `draft-spec`, step 2 | `spec-gate` | `intent-status`, step 2 | **No.** Same reason |
| Only the product owner accepts an intent, by saying yes | [intent-approval.md](intent-approval.md) | `accept-intent`, steps 7 and 8 | none | none | **Not enforced.** `CODEOWNERS` has no owner |
| A missing policy skill is "not available", never "checked and fine" | [spec-creation.md](spec-creation.md) | `draft-spec`, step 5 | none | none | **Not enforced.** Advisory only |

## The pieces

| Piece | File | What it does |
|---|---|---|
| Intent check | [check-intent-status.sh](../.github/scripts/check-intent-status.sh) | Fails for any intent file that does not have `Status: accepted` on the line starting `Author:`. This is the one place that decides what "accepted" means. |
| Spec gate check | [check-spec-gate.sh](../.github/scripts/check-spec-gate.sh) | Run as `check-spec-gate.sh [--base <ref>] intent/<slug>/spec.md`. Passes only if the sibling `intent.md` is on the base branch with `Status: accepted`, the working copy says accepted too, and the working copy is exactly the text on the base branch. The spec file does not have to exist yet. It calls the intent check, so the Author-line rule stays in one place. |
| Spec gate hook | [spec-gate.sh](../.claude/hooks/spec-gate.sh), registered in [settings.json](../.claude/settings.json) | A `PreToolUse` hook on `Edit` and `Write`. For a write to `intent/<slug>/spec.md` it runs the spec gate check and, if it fails, blocks the write and tells Claude why. Every other file passes straight through. |
| Workflow | [intent-status.yml](../.github/workflows/intent-status.yml) | Runs on every pull request and every push to `main`, with no path filter. Step 1 runs the intent check on changed intents. Step 2 runs the spec gate check on changed specs, against the pull request's base commit. On `main` it checks every intent and every spec. |
| Listing helper | [list-intents.sh](../.github/scripts/list-intents.sh) | Not enforcement. It shows each intent's status here and on `main`, whether a `spec.md` exists, and which skill to run next. `/accept-intent` and `/draft-spec` both run it when given no slug. |
| Owner file | [CODEOWNERS](../.github/CODEOWNERS) | Written, but the owner line is commented out, so it does nothing yet. |

The skill, the hook and the workflow all run the same spec gate script, so they cannot disagree about the rule.

## Limits worth knowing

- **The hook guards Claude's edits, not people.** Someone editing in an IDE is not blocked by it. Only the pull request check and branch protection bind everyone.
- **The hook does not see a spec written by a shell command.** That is why the same check runs on pull requests.
- **The hook needs `jq`.** Without it the hook warns and does not block, so the gate is not enforced in that session.
- **A spec pull request opened before its intent is merged will fail.** That is intended. A pull request that changes an intent and adds its spec fails for the same reason: changing the intent is a new intent pull request.
- **Only tested on macOS.** The scripts and the hook ran under macOS bash 3.2. The workflow runs on `ubuntu-latest` and uses `xargs -d`, which is GNU-only, so it cannot be run as written on a Mac. It was tested through a shim.

## Changing or extending it

1. **Change a rule in the script, once.** The skill, the hook and the workflow pick it up. Do not copy the rule into a second place.
2. **Changing the shape of the `Author:` line** means updating `check-intent-status.sh` and `list-intents.sh`. The spec gate script calls the first, so it needs no change.
3. **Adding a hook:** write the script in `.claude/hooks/`, make it executable, and register it in `.claude/settings.json` with a matcher. Keep it fast and scoped to the file that changed. Heavier checks belong at the pull request. Test it by piping simulated tool input into it, for example `printf '{"tool_input":{"file_path":"<path>"}}' | .claude/hooks/spec-gate.sh; echo $?`. Exit code 2 blocks the action.
4. **Back every new hook with the same check in the workflow**, for the cases where the hook does not fire.

## Not done yet

| Item | Why it is not done | What closes it |
|---|---|---|
| **Ask before `Status: accepted`.** A hook that asks the user to confirm whenever an edit sets the status. | A hook cannot verify the product owner's yes. It would add a prompt, not a check, on top of the question `accept-intent` already asks. | A decision that the extra prompt is wanted. It is small to add. |
| **`CODEOWNERS` owner line and branch protection on `main`** | Both need the product owner's GitHub username or team, with write access, and a repo admin's go-ahead. GitHub currently reports "Branch not protected". | The product owner's GitHub name, then the settings in [intent-approval.md](intent-approval.md#branch-protection-settings). With them on, a pull request's author cannot approve it, so a second code owner is needed when the author is the product owner. |
| **Policy skills** for brand, security, compliance and UX | A skill needs one real policy as a written source of truth and a named owner. Neither exists, and the owner is "yet to be defined". Rules copied from an example would be invented policy, and `draft-spec` would treat them as binding. | One policy document and an owner for it. A security skill is the natural first one: the claims status spec's R6 (no claim data in logs, page addresses or storage) is the first rule it would back. |
| **Enforcement that a `spec.md` is accepted before Stage 3** | Only the intent is checked today. The spec's own `Status` line has no stable format for a script to read. | Agree the `Status` line for specs, then extend the check. See [spec-creation.md](spec-creation.md#not-built-yet). |

## What has been verified

| Check | How | Result |
|---|---|---|
| `intent-status` on GitHub | Ran on PRs #1 and #2 | Passed both times. Only the passing path has run on GitHub. |
| Spec gate script | Scratch repo with six states (draft intent, accepted, no intent, accepted only on a branch, edited after acceptance, flipped back to draft). Also several specs at once, a spec file that does not exist yet, a SHA as base, no arguments, and the GitHub annotation format. Then the real repo. | Each gave the expected verdict. |
| Spec gate hook | Simulated tool input for spec files, non-spec files, empty input and a missing `jq`, in the scratch repo and the real repo | Blocks bad specs, ignores everything else. |
| Workflow step 2 | The step's actual text, run locally against the real content of PR #2 and against three fake pull requests, with a small shim for macOS `xargs` | Correct verdict in all four. |
| **Hook firing in a live Claude session** | **Not seen yet.** The session may need a restart for `settings.json` to load. | Unverified. |
| **Workflow step 2 on GitHub** | **Not run yet.** It first runs on the first pull request from `enforce/spec-gate`. | Unverified. |
| Branch protection | GitHub's API reports "Branch not protected" | Not set. |
| Review on merged PRs | PRs #1 and #2 were both merged by the account that opened them, with no review recorded. Nothing required one. | A gap, shown in Git. |

## How it is measured

- **Checks catching things:** failed `intent-status` runs on pull requests, read from the Actions history. A check that has never failed has not yet been shown to work on GitHub.
- **Drift between skill and policy:** when a policy skill exists, review findings that cite the policy should fall toward zero. If they do not, the skill is not triggering or its text has drifted from the policy.
