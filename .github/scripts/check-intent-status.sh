#!/usr/bin/env bash
# Fail if any intent.md given as an argument is not approved.
# Approved means the Author line ends with "Status: accepted".
set -euo pipefail

failed=0
for f in "$@"; do
  if ! grep -qE '^Author:.*Status: accepted' "$f"; then
    echo "::error file=$f::Not approved. Expected 'Status: accepted' on the Author line. The product owner sets it in the PR before merge."
    failed=1
  else
    echo "ok: $f"
  fi
done
exit "$failed"
