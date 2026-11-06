# The feedback loop

A session should check its own work and fix its own mistakes before an engineer sees them. This repo gives it a way to: lint, tests and build, each one command that exits non-zero on failure, with the healthy output listed in [CLAUDE.md](../CLAUDE.md#verifying-your-work). The same three commands run on every pull request in [ci.yml](../.github/workflows/ci.yml), so the reviewer reads evidence from the toolchain instead of re-running it.

State below was checked on 2026-11-05.

## The loop and the verifier are different things

| | Feedback loop | `verifier` subagent |
|---|---|---|
| When | Through the whole task, as many times as the work needs | Once, when the session believes the work is done |
| Context | The session's own, with its assumptions | A fresh one, so the verdict is not colored by how the code was written |
| What it does | Run, read the failure, fix, run again | Runs the checks and the plan's Proof section, and reports only |
| Defined in | [CLAUDE.md](../CLAUDE.md) | [verifier.md](../.claude/agents/verifier.md) |

## Targets a session can check

A target is a command and a pass condition, not a feeling. "All tests in `App.test.js` pass" is a target. "It works" is not. The plan's **Proof** section is where targets are written for a change: `accept-spec` requires each line to be a command or named test plus its pass condition, so the session and the `verifier` can run it without asking anyone.

## Fixing a bug

1. In a normal session, ask Claude to reproduce the bug as a test. Run it and confirm it fails **for the reason you expect**. Commit that test.
2. Start a new session with the guard on: `CLAUDE_FIX_TASK=1 claude` (add `--worktree <name>` for a parallel session, see [parallel-sessions.md](parallel-sessions.md)).
3. Ask Claude to make the test pass. The [test-guard hook](../.claude/hooks/test-guard.sh) blocks any edit or new file that matches a test pattern, so the test cannot be weakened. A test that existed before the fix and could not be rewritten is proof the bug is gone.
4. If the committed test is itself wrong, the session stops and says so. End it, correct the test in a separate commit, and start again.

Outside a fix task the variable is not set and tests can be edited, because feature work needs it. The starter test, for example, has to go when the starter page is replaced.

## Not done yet

| Item | Why it is not done | What closes it |
|---|---|---|
| **A visual check for UI work** | No browser or screenshot tool is wired in, and no mock exists yet. The `verifier` has only Bash and Read, so it cannot see a rendered page. CLAUDE.md tells sessions to say so. | A browser tool or screenshot utility (for example through MCP), and a mock to compare against. Then the loop is implement, screenshot, compare, adjust. |
| **A pull request check that a fix did not touch existing tests** | See [enforcement.md](enforcement.md#not-done-yet). | Agree how a fix PR is recognised. |
| **`ci` as a required check** | It is not enforced by branch protection, which is not set up. | See [enforcement.md](enforcement.md#not-done-yet). |
| **`npm audit` findings** | `npm ci` reports vulnerabilities, including three high-severity ones in dependencies of `react-scripts` 5.0.1 (`@svgr/plugin-svgo`, `bfj`, `css-select`). All come from Create React App's build tooling. The fix npm suggests is a major version change of `react-scripts`, which nobody has decided. No dependency was changed, and `ci` does not run `npm audit`. | A decision on `react-scripts`, which is a dependency choice for the platform owner, and whether `ci` should audit. |

## How it is measured

- **Leading:** first-pass CI success rate for agent-written changes, read from the `ci` workflow's history. It has run once so far, on PR #3, and passed.
- **Lagging:** review time per PR from PR metadata, which should fall as the checks catch what reviewers used to catch, and the change failure rate from an incident tracker, which this repo does not have.
