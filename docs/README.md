# How to use this repo

This repo is a working example of an AI-native SDLC. A change moves through stages, and each stage leaves a reviewed file in Git next to the code: `intent.md`, then `spec.md`, then `plan.md`, then the code itself. Claude skills do the drafting. People make the decisions, and every decision is a merged pull request.

State below was checked on 2026-11-05. For the workflow as a picture, see [workflow-diagram.md](workflow-diagram.md). For what was added and why, see [build-log.md](build-log.md).

> **Most of this exists only on the branch `enforce/spec-gate`, not on `main`.** Only `CLAUDE.md` is on `main`. Check that branch out, or merge it, before expecting the skills, agents, hooks and workflows below to be there. A new worktree carries only what is committed on the branch it is based on.

## Before you start

| You need | Who | Why |
|---|---|---|
| Claude Code, opened in this repo | everyone | Skills, agents and hooks in `.claude/` load from the repo. After pulling new ones, restart the session or run `/agents`. |
| GitHub access and `gh` signed in | everyone who runs a skill | Skills finish by opening a PR with `gh pr create`. Without `gh` the skill says the change **has not landed** and stops at a local commit. |
| Node and `npm ci` | engineers | `node_modules` is not in Git. Every new checkout and worktree needs `npm ci` (never `npm install`, which can change `package-lock.json`). |
| `jq` | engineers | Both hooks need it. Without it they warn and do **not** block. |

## One change, start to finish

Each step is a PR. Skills never merge: the merge is the decision, and it is a person's. Not sure where a change stands? Run `bash .github/scripts/list-intents.sh`, or run any skill with no slug and it shows the same table.

| # | Who | Run | What happens | What you do |
|---|---|---|---|---|
| 1 | Anyone with an idea, ticket or incident | `/capture-intent <your description>` | Claude asks a few questions, writes `intent/<slug>/intent.md` with `Status: draft`, and opens a **draft** PR from `intent/<slug>`. | Correct the draft. Corrections are further commits on the same PR. |
| 2 | Product owner | `/accept-intent <slug>` | Claude confirms you are the product owner, runs a readiness check, and asks you to give every open question a disposition (Answered, Carry to Design, Blocker). When it is Ready it asks one plain question: accept and open the PR? Only on your yes does it set `Status: accepted`. | Decide. **Merge the PR to accept.** Close it with a reason to reject. |
| 3 | Engineer or product owner | `/draft-spec <slug>` | Refuses unless the intent is accepted on `main`. Writes `spec.md`: numbered requirements, design, how each constraint is met, areas of concern. PR from `spec/<slug>`. | Read the **areas of concern** first. Tell Claude what it misread. |
| 4 | Product owner | `/accept-spec <slug>` while the spec says `Status: draft` | Same pattern as step 2. Readiness check, then a disposition for each area of concern (Resolved, Carry to plan, Blocker), then one yes question. Only on your yes does it set `Status: accepted` on the spec's `From:` line. PR from `accept-spec/<slug>`. | Decide. **Merge the PR to accept.** |
| 5 | Engineer | `/accept-spec <slug>` again, after step 4 is merged | Now it plans. Checks the spec is accepted on `main` and unchanged, then writes `plan.md`: files that change, order of work, risks, proof. PR from `plan/<slug>`. | Review the plan against the spec line by line. Every step cites an R number, every proof line is a command. |
| 6 | Engineer | no skill. See "Building" below | Build the change using the plan's streams, the feedback loop and the subagents. | Review each PR. |

Things that stop you, on purpose:
- `/draft-spec` and the `spec-gate` hook refuse a spec from an intent that is not accepted on `main`, or that has changed since. Fixing an intent is a new intent PR, never an edit inside the spec.
- A plan comes only from a spec accepted on `main`. If planning finds a problem in the spec, stop and revise the spec through its own PR.
- A skill never sets `Status: accepted` without the product owner's explicit yes in the conversation. "Do as you can" and "looks good" are not a yes.
- The draft PR for step 1 shows a failing `intent-status` check. That is by design until the intent is accepted.

## Building

**Check your work.** Run all three before saying a task is done, and paste the output. The healthy output for each is in [CLAUDE.md](../CLAUDE.md#verifying-your-work).

```
npm run lint                         # eslint, zero warnings allowed
npm test -- --watchAll=false         # plain `npm test` is watch mode and never exits
npm run build
```

Other commands: `npm start` (http://localhost:3000), and a single test with `npm test -- --watchAll=false -t "<test name>"`. The same three checks run on every PR in the `ci` workflow.

**Fix a bug.** The test is the proof, and the agent must not be able to weaken it. Details in [feedback-loop.md](feedback-loop.md).
1. In a normal session, ask Claude to reproduce the bug as a test. Run it and confirm it fails for the reason you expect. Commit the test.
2. Start a new session with the guard on: `CLAUDE_FIX_TASK=1 claude`.
3. Ask Claude to make the test pass. The `test-guard` hook blocks every edit to a test file.
4. If the committed test is wrong, the session stops. End it and fix the test in a separate commit.

**Run several sessions at once.** One worktree per session, one branch each, at most two or three to start. Split by the plan's streams: steps tagged with different streams share no file. Each new worktree needs `npm ci`, and each dev server its own port (`PORT=3001 npm start`). Full steps in [parallel-sessions.md](parallel-sessions.md).

**Use the subagents.** Ask Claude to use one by name, for example "use the verifier on claims-status-self-service". `/agents` lists them.
- `verifier` runs lint, tests, build and the app, then the plan's Proof section, in a fresh context. It reports mismatches and never fixes. It has no browser, so it cannot judge what the screen looks like and says so.
- `researcher` answers "what exists today" read-only, in under 300 words, and says plainly what it could not find.

## Reference

**Skills** (`.claude/skills/`)

| Command | Reads | Writes (via PR) | Branch |
|---|---|---|---|
| `/capture-intent` | your description | `intent/<slug>/intent.md` | `intent/<slug>` |
| `/accept-intent` | a draft `intent.md` | edits agreed with the product owner, then `Status: accepted` | `accept/<slug>` |
| `/draft-spec` | an accepted `intent.md` and the repo | `intent/<slug>/spec.md` | `spec/<slug>` |
| `/accept-spec` | a draft `spec.md`, then an accepted one | `Status: accepted` on the spec, then `intent/<slug>/plan.md` | `accept-spec/<slug>`, `plan/<slug>` |

**Hooks** (`.claude/settings.json`, scripts in `.claude/hooks/`), both on `Edit` and `Write`

| Hook | Blocks | Active when |
|---|---|---|
| `spec-gate` | writing any `intent/<slug>/spec.md` unless its intent is accepted on `main` and unchanged | always |
| `test-guard` | editing or creating any test file (`*.test.*`, `*.spec.js/ts`, `__tests__/`, `setupTests.*`) | only if `CLAUDE_FIX_TASK` is set |

**Scripts** (`.github/scripts/`, run from the repo root)

| Script | Use |
|---|---|
| `list-intents.sh` | Table of every intent: status here and on `main`, whether a spec exists, what to run next. |
| `check-intent-status.sh <intent.md>` | Passes only if `Status: accepted` is on the `Author:` line. The one place that defines "accepted". |
| `check-spec-gate.sh [--base <ref>] <spec.md>` | Passes only if the sibling intent is accepted on the base branch and unchanged. |

**Workflows** (`.github/workflows/`): `intent-status` (accepted intents, and specs from accepted intents) and `ci` (lint, test, build). Both run on every PR and every push to `main`.

**Where `Status` lives:** on the `Author:` line of an intent, and on the `From:` line of a spec. Plans carry `Status: draft` and have no gate.

## What is enforced and what is not

Skills and CLAUDE.md are advice. Hooks and workflows are checks, and the table of which rule has which is in [enforcement.md](enforcement.md). The honest summary:
- **Not enforced yet:** product owner review. `.github/CODEOWNERS` has its owner line commented out and `main` has no branch protection, so a PR's author can merge their own. Neither `intent-status` nor `ci` is a required check.
- **Hooks guard Claude, not people.** Someone editing in an IDE is not blocked, and neither hook sees a file rewritten by a shell command. The PR checks and review cover that.
- **Not seen yet:** either hook firing in a live session, and any workflow failing on GitHub. `ci` and `intent-status` both passed on PR #3, but `intent-status` had no spec to check, so its spec step has not judged a real one on GitHub.

## Known gaps

- `list-intents.sh` does not know about `/accept-spec`. For an intent with a drafted spec its "Next" column says to use `/draft-spec` only to revise. The next step is `/accept-spec`.
- No brand, security, compliance or UX policy skill exists, so every spec lists those four as "not available". Nobody owns them yet.
- No browser or screenshot tool is wired in, so UI changes cannot be checked visually.
- `npm ci` reports vulnerabilities, including three high-severity ones in dependencies of `react-scripts` 5.0.1. No dependency has been changed. See [feedback-loop.md](feedback-loop.md#not-done-yet).
- `claude --worktree <name>` comes from the course lesson and was not checked here. `git worktree add` is the fallback.
- The first change, `claims-status-self-service`, has an accepted intent and a spec that is still `draft`. Its next step is `/accept-spec claims-status-self-service`, and the spec says the plan cannot be fully written until the login and a back end are identified.

## All the docs

| Page | Read it for |
|---|---|
| [intent-creation.md](intent-creation.md) | Step 1 in detail, and the intent template |
| [intent-approval.md](intent-approval.md) | Step 2: states, the readiness check, branch protection settings |
| [spec-creation.md](spec-creation.md) | Step 3: the spec template and how the product owner reviews it |
| [workflow-diagram.md](workflow-diagram.md) | The workflow end to end, the build loop and where the checks sit, as diagrams |
| [enforcement.md](enforcement.md) | Which rules have a hook or a PR check, and what is not enforced |
| [parallel-sessions.md](parallel-sessions.md) | Worktrees, subagents, splitting work |
| [feedback-loop.md](feedback-loop.md) | Lint, test, build, the bug-fix procedure, the test guard |
| [worked-example.md](worked-example.md) | The first change, with timestamps and commits |
| [build-log.md](build-log.md) | What was added to this repo, why, and how it was checked |
| [../intent/README.md](../intent/README.md) | The `intent/` folder layout |
| [../CLAUDE.md](../CLAUDE.md) | What every Claude session reads first |
