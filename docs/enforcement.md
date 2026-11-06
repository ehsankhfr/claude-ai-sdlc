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
| The product owner's answer is recorded on the PR, whether yes or no | [intent-approval.md](intent-approval.md) | `accept-intent` and `accept-spec`, step 8 part C | none | none | **Not enforced.** Advisory only, and the comment quotes a chat, so it is not verified |
| A missing policy skill is "not available", never "checked and fine" | [spec-creation.md](spec-creation.md) | `draft-spec`, step 5 | none | none | **Not enforced.** Advisory only |
| Every change a skill makes to an intent, spec or plan ends in a PR, never only in the working copy and never on `main` | [CLAUDE.md](../CLAUDE.md), "How skill changes land" | all four skills, in their last steps | none | none | **Not enforced.** Advisory only. Branch protection would stop direct pushes to `main`. |
| Lint, tests and build pass before a change is reported done, with the output shown | [feedback-loop.md](feedback-loop.md) | [CLAUDE.md](../CLAUDE.md) "Verifying your work", `verifier` agent | none | `ci` | **No.** `ci` is not a required check, because branch protection is not set up |
| In a fix task the agent cannot edit a test file | [feedback-loop.md](feedback-loop.md) | CLAUDE.md "Bug fix" | `test-guard`, only while `CLAUDE_FIX_TASK` is set | none | **Not enforced.** CI cannot see the variable. Review the diff |

## The pieces

| Piece | File | What it does |
|---|---|---|
| Intent check | [check-intent-status.sh](../.github/scripts/check-intent-status.sh) | Fails for any intent file that does not have `Status: accepted` on the line starting `Author:`. This is the one place that decides what "accepted" means. |
| Spec gate check | [check-spec-gate.sh](../.github/scripts/check-spec-gate.sh) | Run as `check-spec-gate.sh [--base <ref>] intent/<slug>/spec.md`. Passes only if the sibling `intent.md` is on the base branch with `Status: accepted`, the working copy says accepted too, and the working copy is exactly the text on the base branch. The spec file does not have to exist yet. It calls the intent check, so the Author-line rule stays in one place. |
| Spec gate hook | [spec-gate.sh](../.claude/hooks/spec-gate.sh), registered in [settings.json](../.claude/settings.json) | A `PreToolUse` hook on `Edit` and `Write`. For a write to `intent/<slug>/spec.md` it runs the spec gate check and, if it fails, blocks the write and tells Claude why. Every other file passes straight through. |
| Workflow | [intent-status.yml](../.github/workflows/intent-status.yml) | Runs on every pull request and every push to `main`, with no path filter. Step 1 runs the intent check on changed intents. Step 2 runs the spec gate check on changed specs, against the pull request's base commit. On `main` it checks every intent and every spec. |
| Test guard hook | [test-guard.sh](../.claude/hooks/test-guard.sh), registered in [settings.json](../.claude/settings.json) | A `PreToolUse` hook on `Edit` and `Write`. Does nothing unless `CLAUDE_FIX_TASK` is set in the session's environment. When it is, it blocks any edit or new file that matches a test pattern (`*.test.*`, `*.spec.js/ts` and their `x` variants, `__tests__/`, `setupTests.*`) and tells Claude to fix the code, not the test. |
| Verification workflow | [ci.yml](../.github/workflows/ci.yml) | Runs `npm ci`, `npm run lint`, `npm test -- --watchAll=false` and `npm run build` on every pull request and every push to `main`, with no path filter. It is the evidence a reviewer reads in the check run, and the source of the first-pass success rate. |
| Listing helper | [list-intents.sh](../.github/scripts/list-intents.sh) | Not enforcement. It shows each intent's status here and on `main`, whether a `spec.md` exists, and which skill to run next. `/accept-intent` and `/draft-spec` both run it when given no slug. |
| Owner file | [CODEOWNERS](../.github/CODEOWNERS) | Written, but the owner line is commented out, so it does nothing yet. |

The skill, the hook and the workflow all run the same spec gate script, so they cannot disagree about the rule.

## Limits worth knowing

- **The hook guards Claude's edits, not people.** Someone editing in an IDE is not blocked by it. Only the pull request check and branch protection bind everyone.
- **The hook does not see a spec written by a shell command.** That is why the same check runs on pull requests.
- **The hook needs `jq`.** Without it the hook warns and does not block, so the gate is not enforced in that session.
- **The test guard works only if the engineer sets `CLAUDE_FIX_TASK=1` when starting the session.** Nothing sets it for them. It is read from the session's environment, so the agent cannot unset it from a shell command, but it also does not see a test file rewritten by one (`sed`, `tee`, `git checkout`). That is why the diff is reviewed.
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
| **A check that a skill's change reached a PR.** For example a `Stop` hook that refuses to end a turn while `intent/` has changes that are not committed and pushed. | It cannot tell a skill's change from a person's hand edit in the IDE, so it would nag about edits the skills did not make. Not built. | A decision that the nagging is acceptable, or a way to mark skill-made changes. Branch protection ("require a pull request") is the real backstop, because it also blocks direct pushes to `main`. |
| **A pull request check that a fix did not touch existing tests** | The hook is switched on by an environment variable that CI cannot see. A check would need another signal, such as a `fix/` branch prefix or a label. That is a new convention nobody has agreed. | Agree the signal, then fail the pull request if it modifies or deletes a test file that exists on the base. Until then, the reviewer reads the diff. |
| **The product owner decides with their own PR comment** (`/accept`, `/reject <reason>`), handled by a workflow script | Needs the product owner's GitHub login, which `CODEOWNERS` does not have yet, so a script cannot tell who may decide. Also needs a rule that the comment counts only if the PR's head commit is still the one the readiness report named. | The login, then a workflow that checks the commenter and the commit, sets the status or closes the PR, and never merges. Claude would handle only free-text change requests, later, through the Claude GitHub Action, whose setup was not checked. |
| **Policy skills** for brand, security, compliance and UX | A skill needs one real policy as a written source of truth and a named owner. Neither exists, and the owner is "yet to be defined". Rules copied from an example would be invented policy, and `draft-spec` would treat them as binding. | One policy document and an owner for it. A security skill is the natural first one: the claims status spec's R6 (no claim data in logs, page addresses or storage) is the first rule it would back. |
| **Enforcement that a `spec.md` is accepted before Stage 3** | Only the intent is checked today. The spec's own `Status` line has no stable format for a script to read. | Agree the `Status` line for specs, then extend the check. See [spec-creation.md](spec-creation.md#not-built-yet). |

## What has been verified

| Check | How | Result |
|---|---|---|
| `intent-status` on GitHub | Ran on PRs #1 and #2 | Passed both times. Only the passing path has run on GitHub. |
| Spec gate script | Scratch repo with six states (draft intent, accepted, no intent, accepted only on a branch, edited after acceptance, flipped back to draft). Also several specs at once, a spec file that does not exist yet, a SHA as base, no arguments, and the GitHub annotation format. Then the real repo. | Each gave the expected verdict. |
| Spec gate hook | Simulated tool input for spec files, non-spec files, empty input and a missing `jq`, in the scratch repo and the real repo | Blocks bad specs, ignores everything else. |
| Workflow step 2 | The step's actual text, run locally against the real content of PR #2 and against three fake pull requests, with a small shim for macOS `xargs` | Correct verdict in all four. |
| Test guard hook | Simulated tool input: a test file, a new test file, `setupTests.js` and `__tests__/` with the variable set (blocked, exit 2); source, a spec and `package.json` with it set, and a test file with it unset (allowed); empty input | Blocks only test files, and only in a fix session. |
| Lint, test and build commands | Run locally, including with `CI=true` as GitHub sets it. ESLint's own exit code was checked with a deliberate warning in place. | All three exit 0 when healthy. Lint exits 1 on a warning. |
| **Hooks firing in a live Claude session** | **Not seen yet** for either hook. The session may need a restart for `settings.json` to load, and `CLAUDE_FIX_TASK` must reach the hook's environment. | Unverified. |
| `ci` on GitHub | Ran on PR #3 (`enforce/spec-gate`) on Node 24.22.2: `npm ci`, lint, test and build | Passed. Healthy path only, no failing run seen. GitHub warned that `actions/checkout@v4` and `actions/setup-node@v4` target the deprecated Node 20. |
| Workflow step 2 on GitHub | Ran on PR #3 | Ran and passed, but reported "No spec files to check", because the PR changes no spec. **The step has not yet judged a real spec on GitHub, and no failing run has been seen.** |
| Branch protection | GitHub's API reports "Branch not protected" | Not set. |
| Review on merged PRs | PRs #1 and #2 were both merged by the account that opened them, with no review recorded. Nothing required one. | A gap, shown in Git. |

## How it is measured

- **Checks catching things:** failed `intent-status` runs on pull requests, read from the Actions history. A check that has never failed has not yet been shown to work on GitHub.
- **Drift between skill and policy:** when a policy skill exists, review findings that cite the policy should fall toward zero. If they do not, the skill is not triggering or its text has drifted from the policy.
