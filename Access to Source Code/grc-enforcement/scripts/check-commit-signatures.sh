#!/usr/bin/env bash
set -euo pipefail

COMMITS_FILE="${1:-}"
if [ -z "$COMMITS_FILE" ] || [ ! -f "$COMMITS_FILE" ]; then
  echo "Usage: $0 <commits-file>" >&2
  exit 2
fi

if [ -z "${ALLOWED_SIGNERS:-}" ]; then
  echo "ALLOWED_SIGNERS not set (comma-separated exact fingerprints)" >&2
  exit 2
fi

IFS=',' read -r -a ALLOWED <<< "$ALLOWED_SIGNERS"
IFS=',' read -r -a TRUST_ALLOWED <<< "${ALLOWED_GPG_TRUST:-u,f}"

normalize() { tr -d '[:space:]' | tr '[:lower:]' '[:upper:]'; }

is_allowed_exact() {
  local fp="$1"
  fp="$(printf '%s' "$fp" | normalize)"
  for a in "${ALLOWED[@]}"; do
    if [ "$fp" = "$(printf '%s' "$a" | normalize)" ]; then
      return 0
    fi
  done
  return 1
}

is_allowed_trust() {
  local t="$1"
  for a in "${TRUST_ALLOWED[@]}"; do
    if [ "$t" = "$a" ]; then
      return 0
    fi
  done
  return 1
}

extract_fp_fallback() {
  local commit="$1"
  local out fp
  out="$(git verify-commit "$commit" 2>&1 || true)"
  fp="$(printf '%s\n' "$out" | sed -nE 's/.*key fingerprint (SHA256:[A-Za-z0-9+\/=]+).*/\1/p' | head -n1)"
  if [ -z "$fp" ]; then
    fp="$(printf '%s\n' "$out" | sed -nE 's/.*using [A-Z ]* key ([0-9A-Fa-f]{8,}).*/\1/p' | head -n1)"
  fi
  printf '%s' "$fp"
}

verify_git_signature() {
  local commit="$1"
  local status fp trust

  read -r status fp trust < <(git log -n 1 --format='%G? %GF %GT' "$commit" 2>/dev/null || true)

  if [ -z "$status" ]; then
    echo "Commit $commit: unable to read signature metadata" >&2
    return 1
  fi

  case "$status" in
    G) : ;;
    B|E)
      echo "Commit $commit: signature bad or unverifiable (status=$status)" >&2
      return 1
      ;;
    U)
      echo "Commit $commit: signature good but trust unknown (status=U)" >&2
      return 1
      ;;
    X|Y)
      echo "Commit $commit: signature/key expired (status=$status)" >&2
      return 1
      ;;
    R)
      echo "Commit $commit: signing key revoked (status=R)" >&2
      return 1
      ;;
    N)
      return 1
      ;;
    *)
      echo "Commit $commit: unsupported signature status ($status)" >&2
      return 1
      ;;
  esac

  if [ -z "${fp:-}" ] || [ "$fp" = "-" ]; then
    fp="$(extract_fp_fallback "$commit")"
  fi

  if [ -z "$fp" ]; then
    echo "Commit $commit: signature present but fingerprint not found" >&2
    return 1
  fi

  if ! is_allowed_exact "$fp"; then
    echo "Commit $commit: signer fingerprint not allowed: $fp" >&2
    return 1
  fi

  if [ -n "${trust:-}" ] && [ "$trust" != "-" ]; then
    if ! is_allowed_trust "$trust"; then
      echo "Commit $commit: GPG trust not sufficient: $trust (allowed: ${TRUST_ALLOWED[*]})" >&2
      return 1
    fi
  fi

  return 0
}

verify_cosign_signature() {
  local commit="$1"

  command -v cosign >/dev/null 2>&1 || return 1
  [ -n "${COSIGN_SIGNATURES_DIR:-}" ] || return 1
  [ -d "${COSIGN_SIGNATURES_DIR:-}" ] || return 1

  local sig="${COSIGN_SIGNATURES_DIR%/}/${commit}.sig"
  [ -f "$sig" ] || return 1

  local tmp
  tmp="$(mktemp)"
  printf '%s' "$commit" > "$tmp"

  if [ -n "${COSIGN_PUBLIC_KEY:-}" ]; then
    cosign verify-blob --key "$COSIGN_PUBLIC_KEY" --signature "$sig" "$tmp" >/dev/null 2>&1 || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    return 0
  fi

  if [ -n "${COSIGN_OIDC_ISSUER:-}" ] && [ -n "${COSIGN_IDENTITY_RE:-}" ]; then
    cosign verify-blob --certificate-oidc-issuer "$COSIGN_OIDC_ISSUER" \
      --certificate-identity-regexp "$COSIGN_IDENTITY_RE" \
      --signature "$sig" "$tmp" >/dev/null 2>&1 || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    return 0
  fi

  rm -f "$tmp"
  return 1
}

fail=0

while IFS= read -r commit || [ -n "${commit:-}" ]; do
  commit="${commit//[$'\t\r\n ']}"
  [ -z "$commit" ] && continue

  if ! git cat-file -e "$commit" 2>/dev/null; then
    echo "Commit $commit not available locally" >&2
    fail=1
    continue
  fi

  if verify_git_signature "$commit"; then
    continue
  fi

  if verify_cosign_signature "$commit"; then
    continue
  fi

  echo "Commit $commit: no acceptable signature (git/gpg/ssh) and no acceptable cosign signature" >&2
  fail=1
done < "$COMMITS_FILE"

[ "$fail" -eq 0 ] && exit 0 || exit 1
