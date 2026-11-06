# Build log: what was added and why

A record of the work that added `CLAUDE.md`, the plan stage, subagents and parallel sessions, and the feedback loop to this repo, on 2026-11-05. For how to use any of it, see [README.md](README.md). For the first change taken through the workflow, see [worked-example.md](worked-example.md). Other changes landed in the same period, so `git log` is the full record. This page covers only the pieces below.

All of it is on the branch `enforce/spec-gate`. Only `CLAUDE.md` is on `main`.

## What was added

| Area | Piece | Commit | Why |
|---|---|---|---|
| Context for every session | [CLAUDE.md](../CLAUDE.md), made with `/init` and cut to what a new joiner needs | `b130765` | A session starts knowing the commands, the conventions and the mistakes the team sees. It is the file all other pieces point at. |
| Plan stage | [accept-spec skill](../.claude/skills/accept-spec/SKILL.md) | `ae2d818` | Stage 3 needs an accepted spec and a plan. One skill, two phases, run as separate PRs because the plan must come from the accepted text on `main`. |
| Subagents | [verifier](../.claude/agents/verifier.md), [researcher](../.claude/agents/researcher.md) | `244d126` | Two jobs recur: checking a change in a fresh context, and finding out "what exists today" without flooding the main session. |
| Parallel sessions | [parallel-sessions.md](parallel-sessions.md), plus stream letters in the plan template | `244d126` | One engineer can run several sessions in worktrees. The plan has to show which steps share no file so work can be split safely. |
| Feedback loop | `npm run lint` script in [package.json](../package.json), the "Verifying your work" block in CLAUDE.md | `5e05568` | The repo had no lint command. A session needs one command each for lint, test and build, with a known healthy output. |
| Feedback loop | [test-guard hook](../.claude/hooks/test-guard.sh), registered in [settings.json](../.claude/settings.json) | `5e05568` | An agent fixing code must not be able to weaken the test that checks it. |
| Feedback loop | [ci workflow](../.github/workflows/ci.yml), [feedback-loop.md](feedback-loop.md), rows in [enforcement.md](enforcement.md) | `cc0c6e9` | The PR's check run is where the reviewer and any later auditor read the evidence. |
| Decision record | Step 8 part C of [accept-intent](../.claude/skills/accept-intent/SKILL.md) and [accept-spec](../.claude/skills/accept-spec/SKILL.md): the readiness report and the product owner's answer, yes or no, posted on the PR as comments | not committed yet | The product owner's yes lived only in a chat transcript, and Git showed just the merge. The comment puts it next to the diff, labelled as Claude's unverified record. |
| Guide | [README.md](README.md) and this page | not committed yet | One place that says how to use all of it. |

## How each piece works, in a line

- **accept-spec.** Phase A: runs `check-spec-gate.sh`, a readiness check (7 blocking, 5 advisory), has the product owner choose a disposition for every area of concern, then on an explicit yes sets `Status: accepted` on the spec's `From:` line. Phase B: only if the spec is accepted on `main` and unchanged, writes `plan.md` (files that change, order of work with streams and blocked steps, risks, proof). Every step cites R numbers. Every Proof line must be a command with a pass condition.
- **verifier.** Bash and Read only. Runs lint, tests, build, starts the app on a spare port, runs the plan's Proof, and reports mismatches. Never edits. States what it could not observe, because it has no browser.
- **researcher.** Read, Grep and Glob only, so it cannot edit. Reports what exists and what it could not find, in under 300 words.
- **test-guard.** Does nothing unless `CLAUDE_FIX_TASK` is set in the session's environment. When set, blocks any edit or new file matching a test pattern.
- **ci.** `npm ci`, `npm run lint`, `npm test -- --watchAll=false`, `npm run build` on every PR and push to `main`.

## Choices that were not obvious

| Choice | Why |
|---|---|
| The verifier runs `npm test`, `npm run build` and `npm start`, not the lesson's `make run`. | This repo has no Makefile. Copying the example would have meant inventing a command. |
| The test guard is switched on by an environment variable, not always on. | Feature work has to edit tests: the starter test must go when the starter page is replaced. An environment variable also cannot be unset by the agent from a shell command. |
| One skill, `accept-spec`, for both accepting a spec and planning. | One skill was asked for. It routes by the spec's state, so the same command does the right half. |
| A spec's status is on its `From:` line. | The spec template had no stable status line. The `From:` line already carries `Status: draft`. Nothing in CI reads it yet. |
| Permissions were left alone. | What the organization treats as safe is its decision. `.claude/settings.json` holds only hooks. |
| No dependency was changed after `npm ci` reported vulnerabilities. | You chose to continue and leave them. The suggested fix is a major-version change of `react-scripts`, which nobody has decided. |
| CI uses Node 24. | That is the version the commands were run on. |

## What was checked

| Check | How | Result |
|---|---|---|
| `accept-spec` gate commands | Ran on the real claims spec: read its status, confirmed it is not accepted on `main`, ran `check-spec-gate.sh`, and diffed the intent against the commit the spec cites | Each behaved as the skill expects. The spec is `draft`, so the skill would start at phase A. |
| `test-guard` | Simulated tool input: test file, new test file, `setupTests.js` and `__tests__/` with the variable set; source, a spec and `package.json` with it set; a test file with it unset; empty input | Blocked only test files, only with the variable set. |
| Lint, test, build | Run locally, with and without `CI=true` | All exit 0. Lint exits 1 when a warning is present. |
| `ci.yml` | Parsed as YAML, then run by GitHub on PR #3 | Passed on Node 24.22.2. The build printed `Compiled successfully.` |
| `npm ci` | Run in the repo | Succeeded. Reported vulnerabilities (below). |

**Not checked:**
- `accept-spec` has never run end to end, and neither phase has produced a PR.
- Neither agent has run in a live session. The verifier's plan path has nothing to run against, because no `plan.md` exists.
- Neither hook has been seen firing in a live session. `settings.json` may need a restart to load, and the variable has to reach the hook's environment.
- No workflow has been seen failing on GitHub, so neither has been shown to catch anything there. `intent-status`'s spec step ran on PR #3 but had no spec to check.
- `claude --worktree` was not checked because `claude` was not on the shell's PATH.

## Still open

| Item | What closes it |
|---|---|
| Permission allowlist so sessions do not wait on prompts | The organization names the commands it treats as safe. `/fewer-permission-prompts` can propose a list from past transcripts. |
| `npm audit` findings in `react-scripts` 5.0.1's dependencies | A decision on `react-scripts`, and whether `ci` should audit. |
| `CODEOWNERS` owner line and branch protection on `main` | The product owner's GitHub name, then the settings in [intent-approval.md](intent-approval.md#branch-protection-settings). Until then `intent-status` and `ci` are not required checks. |
| The product owner decides with their own PR comment, checked by a workflow | The product owner's GitHub login in `CODEOWNERS`, then the workflow described in [enforcement.md](enforcement.md#not-done-yet). The decision record exists but has never been posted: neither skill has run since the change. |
| `list-intents.sh` does not offer `/accept-spec` | Add the case to the script's "Next" column. Both older skills rely on that script, so it needs care. |
| Enforcement that a spec is accepted before Stage 3, and a check that a fix PR did not touch existing tests | See [enforcement.md](enforcement.md#not-done-yet). |
| GitHub warns that `actions/checkout@v4` and `actions/setup-node@v4` target the deprecated Node 20 | Move both actions to a release that targets a supported Node. Not changed. |
| A visual check for UI work | A browser or screenshot tool, and a mock to compare against. |
| Who accepts a plan | Nothing defines it. `plan.md` carries `Status: draft` and has no gate. |
| `CLAUDE.md` is over a page | The lesson says to keep it under one. The PR-landing rules are most of the growth and could move to a doc. |
