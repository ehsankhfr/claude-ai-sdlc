#!/usr/bin/env bash
# List every intent, where it stands, and which skill to run next.
# Used by /accept-intent and /draft-spec when they are run without a slug,
# so both show the same picture. Run from the repo root.
#
# "Status" is read from the Author line, the same place check-intent-status.sh
# reads it. It is read twice: from the working copy and from the main branch.
# The product owner's decision is the merge, so an intent accepted only on a
# branch is not ready for Stage 2 yet.
set -euo pipefail

main=${MAIN_BRANCH:-main}

# Reads an intent.md on stdin. Prints accepted, draft, or none.
status_of() {
  local line
  line=$(grep -m1 -E '^Author:' || true)
  case "$line" in
    *"Status: accepted"*) echo accepted ;;
    *"Status: draft"*) echo draft ;;
    *) echo none ;;
  esac
}

rows=""
for f in intent/*/intent.md; do
  [ -e "$f" ] || continue
  dir=$(dirname "$f")
  slug=$(basename "$dir")

  here=$(status_of < "$f")
  if git cat-file -e "$main:$f" 2>/dev/null; then
    onmain=$(git show "$main:$f" | status_of)
  else
    onmain="not on $main"
  fi
  if [ -e "$dir/spec.md" ]; then spec=yes; else spec=no; fi

  case "$here/$onmain/$spec" in
    none/*)
      next="Fix the Author line: no Status found" ;;
    draft/accepted/*)
      next="Draft here but accepted on $main. Reconcile before going on" ;;
    draft/*)
      next="/accept-intent $slug" ;;
    accepted/accepted/no)
      next="/draft-spec $slug" ;;
    accepted/accepted/yes)
      next="Spec drafted. /draft-spec $slug only to revise it" ;;
    accepted/*)
      next="Accepted here, not on $main yet. Merge the PR, then /draft-spec $slug" ;;
  esac

  rows="$rows| $slug | $here | $onmain | $spec | $next |"$'\n'
done

if [ -z "$rows" ]; then
  echo "No intents found under intent/."
  exit 0
fi

echo "| Intent | Status here | Status on $main | spec.md | Next |"
echo "| :---- | :---- | :---- | :---- | :---- |"
printf '%s' "$rows"
