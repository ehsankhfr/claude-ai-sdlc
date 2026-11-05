# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A working example of an AI-native SDLC: planning artifacts (`intent.md`, `spec.md`) live in Git next to the code, and Claude skills move a change through the stages. The sample change is `intent/claims-status-self-service/`. `src/` is still the untouched Create React App scaffold; there is no claims portal, backend or claims system in this repo yet. Do not describe or reference one as if it exists.

## Commands

- Dev server: `npm start` (http://localhost:3000)
- Build: `npm run build`
- Tests: `npm test` (watch mode). Single run: `npm test -- --watchAll=false`. Single test: `npm test -- --watchAll=false -t "renders learn react link"` or pass a file path.
- Lint: there is no lint script. ESLint (`react-app` config in `package.json`) runs inside `npm start` and `npm run build`.
- List intents and what to run next: `bash .github/scripts/list-intents.sh`
- Check an intent is accepted (same rule as CI): `bash .github/scripts/check-intent-status.sh intent/<slug>/intent.md`
- Check a spec may be written (same rule as the hook and CI): `bash .github/scripts/check-spec-gate.sh intent/<slug>/spec.md`

## The intent workflow (read multiple files to see it)

Stage 1 Intent → Stage 2 Design (spec) → Stage 3 Build (plan mode; `plan.md` does not exist yet). One folder per change under `intent/<slug>/`.

- Skills in `.claude/skills/`: `capture-intent` (idea → `intent.md`), `accept-intent` (product owner's readiness check and decision), `draft-spec` (accepted intent → `spec.md`). Detail in `docs/intent-creation.md`, `docs/intent-approval.md`, `docs/spec-creation.md`.
- **Approved means merged into `main` with `Status: accepted`.** The merge is the decision. `Status` lives on the `Author:` line of `intent.md` (`Author: <name> (<team>). Status: draft.`). `check-intent-status.sh`, `list-intents.sh` and the `intent-status` workflow all grep that one line. If you change the template shape, update both scripts.
- Branch names: `accept/<slug>` for acceptance, `spec/<slug>` for specs. Open a PR into `main`; never commit to `main` directly.
- `spec.md` is derived from the text of `intent.md` **on `main`**, not a working copy with uncommitted edits. A `PreToolUse` hook (`.claude/hooks/spec-gate.sh`, registered in `.claude/settings.json`) blocks any Edit or Write to a `spec.md` until `check-spec-gate.sh` passes, and the `intent-status` workflow runs the same script on PRs. If the hook blocks you, run `/accept-intent`; do not work around it.

## Things Claude gets wrong here

- Never set `Status: accepted` without the product owner's explicit yes in the conversation, and never merge. Running `/accept-intent` is not a yes. Do not offer to "just proceed" past a draft intent.
- `draft-spec` never edits `intent.md`. If the intent looks wrong, raise it as an area of concern; the fix is a new intent PR.
- Do not invent systems, endpoints, numbers or states. If the intent or repo does not say, write "not yet identified" or carry it as an open question. The claim status source system is currently unidentified.
- A missing policy skill (brand, security, compliance, UX) is "not available", never "checked and fine".
- Commit, push or open PRs only when asked. Do not overwrite an existing `spec.md`; revise it in place.
- `docs/` is partly stale: it says there is no remote, but `origin` exists. `.github/CODEOWNERS` still has the owner line commented out, so nothing enforces product owner review yet, and branch protection on `main` is not confirmed set up.
