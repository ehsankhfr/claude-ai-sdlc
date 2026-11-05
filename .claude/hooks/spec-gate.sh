#!/usr/bin/env bash
# PreToolUse hook for Edit|Write. It backs step 2 of the draft-spec skill.
#
# Blocks any write to intent/<slug>/spec.md unless that intent is accepted on
# main. It runs the same script as the skill and the pull request check.
# Exit 2 blocks the edit and puts stderr in front of Claude.
#
# An Edit|Write hook does not fire when a shell command rewrites the file.
# That is why the same script also runs on every pull request, in the
# intent-status workflow.
if ! command -v jq > /dev/null 2>&1; then
  echo "spec-gate hook skipped: jq is not installed, so the draft-spec gate is not enforced in this session." >&2
  exit 1
fi

file=$(jq -r '.tool_input.file_path // empty')
root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2> /dev/null)}

case "$file" in
  "$root"/intent/*/spec.md) ;;
  *) exit 0 ;; # not a spec
esac

cd "$root" || exit 2
if ! found=$(bash .github/scripts/check-spec-gate.sh "${file#"$root"/}" 2>&1); then
  echo "draft-spec gate: this spec.md cannot be written yet. A spec may only come from an intent that is accepted on main." >&2
  echo "$found" >&2
  echo "The product owner accepts an intent by merging it. Point the user to /accept-intent <slug>. Do not edit the intent's status." >&2
  exit 2
fi
