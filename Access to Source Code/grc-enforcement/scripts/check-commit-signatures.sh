#!/usr/bin/env bash
set -euo pipefail

COMMITS_FILE="${1:-}"
if [ -z "$COMMITS_FILE" ] || [ ! -f "$COMMITS_FILE" ]; then
  echo "Usage: $0 <commits-file>" >&2
  exit 2
fi
if [ -z "${ALLOWED_SIGNERS:-}" ]; then
  echo "ALLOWED_SIGNERS not set" >&2
  exit 2
fi

IFS=',' read -r -a ALLOWED <<< "$ALLOWED_SIGNERS"
fail=0

while read -r commit; do
  commit="${commit//[$'\t\r\n ']}"
  [ -z "$commit" ] && continue

  # require commit object present
  if ! git cat-file -e "$commit" 2>/dev/null; then
    echo "Commit $commit not available locally" >&2
    fail=1; continue
  fi

  # verify GPG signature
  if git verify-commit "$commit" >/dev/null 2>&1; then
    signer=$(git verify-commit "$commit" 2>&1 | tr '\n' ' ' | sed -E 's/.*using GPG key: //;s/^[[:space:]]+//')
    ok=1
    for a in "${ALLOWED[@]}"; do
      if [[ "$signer" == *"$a"* ]]; then ok=0; break; fi
    done
    if [ "$ok" -ne 0 ]; then
      echo "Commit $commit signed by unapproved signer: $signer" >&2
      fail=1
    fi
  else
    echo "Commit $commit is unsigned or signature invalid" >&2
    fail=1
  fi
done < "$COMMITS_FILE"

[ "$fail" -eq 0 ] && exit 0 || exit 1
