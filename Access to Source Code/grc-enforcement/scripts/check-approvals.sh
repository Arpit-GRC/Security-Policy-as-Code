#!/usr/bin/env bash
set -euo pipefail

MIN="${1:-2}"

if [ -z "${GITHUB_EVENT_PATH:-}" ] || [ ! -f "${GITHUB_EVENT_PATH}" ]; then
  exit 2
fi

PR="$(jq -r .pull_request.number < "$GITHUB_EVENT_PATH")"
REPO_FULL="$(jq -r .repository.full_name < "$GITHUB_EVENT_PATH")"
OWNER="${REPO_FULL%/*}"
REPO="${REPO_FULL#*/}"

TOKEN="${GITHUB_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  exit 2
fi

graphql_query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      author { login }
      reviewDecision
      commits(last: 1) { nodes { commit { committedDate } } }
      reviews(last: 100) { nodes { author { login } state submittedAt } }
    }
  }
}'

if command -v gh >/dev/null 2>&1; then
  resp="$(gh api graphql -f query="$graphql_query" -F owner="$OWNER" -F name="$REPO" -F number="$PR")"
else
  resp="$(curl -sS -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "$(jq -nc --arg q "$graphql_query" --arg owner "$OWNER" --arg name "$REPO" --argjson number "$PR" \
      '{query:$q, variables:{owner:$owner, name:$name, number:$number}}')" \
    https://api.github.com/graphql)"
fi

author_login="$(jq -r '.data.repository.pullRequest.author.login // empty' <<<"$resp")"
review_decision="$(jq -r '.data.repository.pullRequest.reviewDecision // empty' <<<"$resp")"
last_commit_date="$(jq -r '.data.repository.pullRequest.commits.nodes[0].commit.committedDate // empty' <<<"$resp")"

if [ -z "$author_login" ] || [ -z "$last_commit_date" ]; then
  exit 2
fi

approved_unique="$(
  jq -r --arg author "$author_login" --arg lastCommit "$last_commit_date" '
    .data.repository.pullRequest.reviews.nodes
    | map(select(.author.login != null))
    | group_by(.author.login)
    | map(sort_by(.submittedAt) | last)
    | map(select(.author.login != $author))
    | map(select(.state == "APPROVED"))
    | map(select(.submittedAt >= $lastCommit))
    | length
  ' <<<"$resp"
)"

if [ "$review_decision" != "APPROVED" ]; then
  exit 1
fi

if [ "$approved_unique" -lt "$MIN" ]; then
  exit 1
fi

exit 0
