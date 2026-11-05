#!/usr/bin/env bash
# PreToolUse hook for Edit|Write. It protects the feedback loop (docs/feedback-loop.md).
#
# During a fix task, an agent must not be able to weaken the check on its own
# fix. The engineer starts the session with CLAUDE_FIX_TASK=1 after committing
# the failing test. While that is set, this blocks any edit to a test file.
# With it unset the hook does nothing, because feature work legitimately edits
# tests (the starter test has to go when the starter page is replaced).
#
# It runs in the session's environment, so the agent cannot switch it off from
# a shell command. It cannot see a test file rewritten by a shell command
# either (sed, tee, git checkout). Review the diff for that.
# Exit 2 blocks the edit and puts stderr in front of Claude.
[ -n "${CLAUDE_FIX_TASK:-}" ] || exit 0

if ! command -v jq > /dev/null 2>&1; then
  echo "test-guard hook skipped: jq is not installed, so test files are not protected in this fix session." >&2
  exit 1
fi

file=$(jq -r '.tool_input.file_path // empty')

case "$file" in
  *.test.* | *.spec.js | *.spec.jsx | *.spec.ts | *.spec.tsx | */__tests__/* | */setupTests.*) ;;
  *) exit 0 ;; # not a test file
esac

echo "test-guard: this is a fix task (CLAUDE_FIX_TASK is set), so test files cannot be edited or created: $file" >&2
echo "Fix the code, not the test. If the test itself is wrong, stop and tell the engineer. They end the fix session and change the test in a separate commit." >&2
exit 2
