# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A working example of an AI-native SDLC: planning artifacts (`intent.md`, `spec.md`) live in Git next to the code, and Claude skills move a change through the stages. The sample change is `intent/claims-status-self-service/`. `src/` is still the untouched Create React App scaffold; there is no claims portal, backend or claims system in this repo yet. Do not describe or reference one as if it exists.

## Commands

- Dev server: `npm start` (http://localhost:3000)
- Single test: `npm test -- --watchAll=false -t "renders learn react link"`, or pass a file path.
- List intents and what to run next: `bash .github/scripts/list-intents.sh`
- Check an intent is accepted (same rule as CI): `bash .github/scripts/check-intent-status.sh intent/<slug>/intent.md`
- Check a spec may be written (same rule as the hook and CI): `bash .github/scripts/check-spec-gate.sh intent/<slug>/spec.md`

## Verifying your work

Run all three before reporting any task complete, and paste the output. Check against a stated target ("all tests pass", "the endpoint returns 200"), not "looks right".

- Lint: `npm run lint`. Healthy: nothing after the `> eslint src --max-warnings 0` header, exit 0. Any warning fails it.
- Test: `npm test -- --watchAll=false` (plain `npm test` is watch mode and never exits). Healthy: `PASS src/App.test.js`, `Tests: 1 passed, 1 total`, exit 0.
- Build: `npm run build`. Healthy: `File sizes after gzip:` then `The build folder is ready to be deployed.`, exit 0. A Node `DEP0176` deprecation warning above it is normal.

If a test fails, fix the code, not the test. Change a test only when the requirement it covers has changed, and say so.

**Bug fix:** write the failing test first, run it, confirm it fails for the expected reason, and commit it. Then fix with `CLAUDE_FIX_TASK=1` set, which makes the `test-guard` hook block every test edit. See `docs/feedback-loop.md`.

No browser or screenshot tool is wired in, so a UI change cannot be checked visually yet. Say so; do not claim the screen was checked.

## The intent workflow (read multiple files to see it)

Stage 1 Intent → Stage 2 Design (spec) → Stage 3 Build (plan mode; `plan.md` does not exist yet). One folder per change under `intent/<slug>/`.

- Skills in `.claude/skills/`: `capture-intent` (idea → `intent.md`), `accept-intent` (product owner's readiness check and decision), `draft-spec` (accepted intent → `spec.md`), `accept-spec` (product owner's decision on a spec, then accepted spec → `plan.md`). Detail in `docs/intent-creation.md`, `docs/intent-approval.md`, `docs/spec-creation.md`. What is enforced and what is not: `docs/enforcement.md`. The record of the first change: `docs/worked-example.md`.
- **Approved means merged into `main` with `Status: accepted`.** The merge is the decision. `Status` lives on the `Author:` line of `intent.md` (`Author: <name> (<team>). Status: draft.`). `check-intent-status.sh`, `list-intents.sh` and the `intent-status` workflow all grep that one line. If you change the template shape, update both scripts.
- A spec's `Status` lives on its `From:` line, not `Author:`. Nothing in CI reads it yet; `accept-spec` checks it inline. A plan comes only from a spec accepted on `main`.
- Subagents in `.claude/agents/`: `verifier` (runs tests, build and app, then the plan's Proof; reports only) and `researcher` (read-only "what exists today"). Parallel sessions, one worktree each: see `docs/parallel-sessions.md`. A new worktree has no `node_modules` (run `npm ci`), and two dev servers need different ports (`PORT=3001 npm start`).
- **Every change a skill makes to `intent.md`, `spec.md` or `plan.md` ends in a PR into `main` before the turn ends.** It is never left only in the working copy, and never committed to `main`. The skill does this itself as its last step, so it needs no separate ask. It never merges. **How skill changes land:**
  1. `git fetch origin`. Branch from `origin/main`, named for the skill: `intent/<slug>` for a captured intent, `accept/<slug>` for intent acceptance, `spec/<slug>` for a spec, `accept-spec/<slug>` for spec acceptance, `plan/<slug>` for a plan. If that branch or an open PR for it already exists, add a commit to it instead of starting another. If the name was used by a merged PR, add a suffix such as `-2`.
  2. Commit only the files the skill changed. If local `main` holds commits that are not on `origin/main` and do not belong in the PR, build the commit in a temporary worktree based on `origin/main`, so the PR holds only this change.
  3. Push, then open the PR into `main` with `gh pr create`. Use `--draft` while it is not asking for a merge decision: an intent still at `Status: draft` (`intent-status` fails on it by design), or an acceptance PR before the product owner's yes.
  4. Tell the user the PR link, which branch the checkout is on, and who has to merge it.
  5. If there is no remote, or `gh` is not signed in, say plainly that the change has **not landed** and stop at the local commit on the branch.
- `spec.md` is derived from the text of `intent.md` **on `main`**, not a working copy with uncommitted edits. A `PreToolUse` hook (`.claude/hooks/spec-gate.sh`, registered in `.claude/settings.json`) blocks any Edit or Write to a `spec.md` until `check-spec-gate.sh` passes, and the `intent-status` workflow runs the same script on PRs. If the hook blocks you, run `/accept-intent`; do not work around it.

## Things Claude gets wrong here

- Never set `Status: accepted` without the product owner's explicit yes in the conversation, and never merge. Running `/accept-intent` is not a yes. Do not offer to "just proceed" past a draft intent.
- `draft-spec` never edits `intent.md`. If the intent looks wrong, raise it as an area of concern; the fix is a new intent PR.
- Do not invent systems, endpoints, numbers or states. If the intent or repo does not say, write "not yet identified" or carry it as an open question. The claim status source system is currently unidentified.
- A missing policy skill (brand, security, compliance, UX) is "not available", never "checked and fine".
- Apart from the skills' own PR step above, commit, push or open PRs only when asked. That covers docs, scripts, skills, hooks and source code. Do not overwrite an existing `spec.md`; revise it in place.
- `.github/CODEOWNERS` still has the owner line commented out and `main` has no branch protection (checked 2026-11-05), so nothing enforces product owner review yet. `docs/enforcement.md` lists what is and is not enforced.
