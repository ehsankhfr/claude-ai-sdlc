# Parallel sessions and subagents

One engineer can drive several streams of work at once. A **parallel session** is another full Claude Code instance on a separate task, in its own Git worktree. A **subagent** is a scoped helper inside one session, with its own context window and tool limits. Sessions raise how many tasks are in flight. Subagents keep each session focused on its own task. The engineer's job is steering and reviewing both.

State below was checked on 2026-11-05.

## Subagents in this repo

Defined in [.claude/agents/](../.claude/agents/), shared through Git. Restart the session, or run `/agents`, to load a new one.

| Agent | Tools | Job |
|---|---|---|
| [verifier](../.claude/agents/verifier.md) | Bash, Read | Runs the tests, the build and the app, then runs the Proof section of `plan.md`. Reports mismatches against the plan's R numbers. Never fixes. |
| [researcher](../.claude/agents/researcher.md) | Read, Grep, Glob | Answers "what exists today" for `/draft-spec` and `/accept-spec` without flooding the main context. Read-only by tool list, so it cannot edit. |

The verifier has no browser, and this is a client-rendered app, so it cannot see what a user sees. It is told to say so instead of claiming the screen was checked.

## Running parallel sessions

1. **Split by files.** Read the plan's **Files that change** and **Order of work**. Steps tagged with different streams share no file and do not depend on each other (see [accept-spec](../.claude/skills/accept-spec/SKILL.md)). Each stream can be its own session. Steps in one stream, and everything on one change's spec and plan, run in one session, one after another. Different change slugs touch different folders under `intent/`, so they are independent by default.
2. **One worktree per session**, on its own branch named as in [CLAUDE.md](../CLAUDE.md): `claude --worktree <name>` (from the lesson, not verified here because `claude` was not on this shell's PATH), or `git worktree add ../claude-ai-sdlc-<name> -b <branch> <base>`. Git will not check out one branch in two worktrees, so never give two sessions the same branch. **A worktree carries only committed files.** Today the `spec-gate` hook, the gate script and the `accept-spec` skill exist only on `enforce/spec-gate`, not on `main`, and these agents are not committed yet. A worktree based on `origin/main` has none of them, so merge first, or base the worktree on a branch that has them.
3. **Prepare each worktree.** `node_modules` is gitignored, so a new worktree has none: run `npm ci`. Two dev servers cannot both use port 3000: give each its own, for example `PORT=3001 npm start`.
4. **Start with two or three sessions.** Add one only while you are still reviewing each stream properly.
5. **Each session ends as its own PR.** Merge them one at a time. The second to merge rebases if the two touched the same file.
6. **Clean up.** `git worktree list`, then `git worktree remove <path>` once its PR is merged.

## What already applies to every session

[.claude/settings.json](../.claude/settings.json) is tracked, so a worktree based on a commit that has it carries the `spec-gate` hook (see the note on committed files above), and the `intent-status` workflow checks every PR. Both are described in [enforcement.md](enforcement.md). The hook still needs `jq`, and it guards Claude's edits, not people. Parallel sessions add no new bypass, but they add more output to review, so the controls must stay in the repo and not in one engineer's settings.

## Not done yet

| Item | Why it is not done | What closes it |
|---|---|---|
| **Permission allowlist** so sessions do not wait on prompts | What the organization treats as safe is its call, not ours. `.claude/settings.json` holds only the hook. | The organization names the commands. `/fewer-permission-prompts` can propose a list from past transcripts for review. |
| **The agents have not run in a live session** | Written, not exercised. The verifier's plan path has nothing to run against: the claims spec is still `draft`, so no `plan.md` exists, and the app is the starter. | Run both once a plan exists, and correct them. |
| **A code simplifier agent** | The built-in `/simplify` skill exists, and there is no application code yet to simplify. | Add one when repeated cleanups show up in review. |
| **Concurrency measure** | The lesson counts sessions from an OpenTelemetry export, which is not set up. | Configure the export. Until then `git worktree list` per engineer is a weak proxy. |

## How it is measured

- **Leading:** concurrent sessions per engineer while review quality holds, and the share of the day spent steering rather than waiting.
- **Lagging:** changes merged per engineer per week, read next to the rework rate from PR history: follow-up fixes to merged PRs, and `spec.md` commits after the first `plan.md` (see [spec-creation.md](spec-creation.md#how-it-is-measured)).
