#!/usr/bin/env bash
# Fail unless every spec.md given comes from an accepted intent.
#
# The rule (docs/spec-creation.md): a spec is derived only from an intent that
# is merged into the base branch with "Status: accepted", and the intent text
# in the working copy is exactly that text. The spec file does not have to
# exist yet, so the draft-spec skill can run this before it writes anything.
#
# Usage, from the repo root:
#   check-spec-gate.sh [--base <ref>] intent/<slug>/spec.md [...]
# --base defaults to "main". CI passes the pull request's base commit.
#
# The same script runs in three places so they cannot drift apart:
#   - the draft-spec skill, step 2
#   - the PreToolUse hook .claude/hooks/spec-gate.sh, before any write to a spec.md
#   - the intent-status workflow, on every pull request and push to main
#
# What counts as "accepted" is decided in one place, check-intent-status.sh.
set -uo pipefail

base=main
if [ "${1:-}" = "--base" ]; then
  base=${2:?--base needs a ref}
  shift 2
fi
if [ "$#" -eq 0 ]; then
  echo "usage: check-spec-gate.sh [--base <ref>] intent/<slug>/spec.md [...]" >&2
  exit 2
fi

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
failed=0

fail() { # <spec path> <reason>
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error file=$1::$2"
  else
    echo "FAIL $1: $2" >&2
  fi
  failed=1
}

for spec in "$@"; do
  intent="$(dirname "$spec")/intent.md"

  if [ ! -f "$intent" ]; then
    fail "$spec" "There is no intent.md next to it. A spec comes from an accepted intent."
    continue
  fi

  # 1. The intent is on the base branch and accepted there.
  if ! git cat-file -e "$base:$intent" 2>/dev/null; then
    fail "$spec" "$intent is not on $base. The product owner accepts an intent by merging it. Run /accept-intent first."
    continue
  fi
  git show "$base:$intent" > "$tmp"
  if ! bash "$here/check-intent-status.sh" "$tmp" > /dev/null; then
    fail "$spec" "$intent on $base is not 'Status: accepted'. Run /accept-intent first."
    continue
  fi

  # 2. The working copy says accepted too.
  if ! bash "$here/check-intent-status.sh" "$intent" > /dev/null; then
    fail "$spec" "$intent in the working copy is not 'Status: accepted'."
    continue
  fi

  # 3. The working copy is exactly the accepted text: no uncommitted or branch edits.
  if ! git diff --quiet "$base" -- "$intent"; then
    fail "$spec" "$intent differs from $base. A spec must be derived from the accepted text on $base. Changing the intent is a new intent PR."
    continue
  fi

  [ -n "${GITHUB_ACTIONS:-}" ] || echo "ok: $spec comes from an accepted intent on $base"
done
exit "$failed"
