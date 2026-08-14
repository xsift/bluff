#!/usr/bin/env bash
set -Eeuo pipefail

# Initialize the Sift labels and task Issues in the repository cloned from this
# template. Every remote operation is explicit and safe to repeat.
command -v git >/dev/null || { echo "bootstrap: git is required" >&2; exit 1; }
command -v gh >/dev/null || { echo "bootstrap: GitHub CLI (gh) is required" >&2; exit 1; }
root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "bootstrap: run this from a git repository" >&2
  exit 1
}
cd "$root"
gh auth status >/dev/null 2>&1 || {
  echo "bootstrap: gh is not authenticated; run gh auth login" >&2
  exit 1
}

remote=$(git remote get-url origin 2>/dev/null) || {
  echo "bootstrap: origin remote is required" >&2
  exit 1
}
case "$remote" in
  https://github.com/*|http://github.com/*|git@github.com:*) ;;
  *) echo "bootstrap: origin must be a GitHub repository" >&2; exit 1 ;;
esac
repo=${remote#https://github.com/}; repo=${repo#http://github.com/}; repo=${repo#git@github.com:}
repo=${repo%.git}
case "$repo" in
  xsift/bluff|xsift/bluff/*|hexai-cn/bluff|hexai-cn/bluff/*)
    echo "bootstrap: refusing to modify the template upstream repository" >&2
    exit 1
    ;;
esac
[[ "$repo" == */* && "$repo" != */*/* ]] || {
  echo "bootstrap: could not determine owner/repository from origin" >&2
  exit 1
}

# Read back the canonical repository and permission from GitHub. This catches
# a stale/mistyped remote before any label or Issue mutation happens.
repo_check=$(gh repo view "$repo" --json nameWithOwner,viewerPermission --jq '.nameWithOwner + "\n" + .viewerPermission') || {
  echo "bootstrap: cannot read repository $repo; check its ownership and access" >&2
  exit 1
}
canonical=$(printf '%s\n' "$repo_check" | sed -n '1p')
permission=$(printf '%s\n' "$repo_check" | sed -n '2p')
[[ "$canonical" == "$repo" ]] || {
  echo "bootstrap: origin does not match the accessible repository ($canonical)" >&2
  exit 1
}
case "$permission" in
  ADMIN|MAINTAIN|WRITE) ;;
  *) echo "bootstrap: authenticated account has no write ownership of $repo (permission: ${permission:-unknown})" >&2; exit 1 ;;
esac

trap 'echo "bootstrap: failed; rerun is safe and will resume completed work" >&2' ERR

labels="sift:run 2ea44f
sift:seed 8250df
priority:p0 b60205
priority:p1 d93f0b
priority:p2 fbca04
priority:p3 cfd3d7"
created_labels=''
while read -r label color; do
  gh label create "$label" --repo "$repo" --color "$color" --force >/dev/null
  created_labels="$created_labels
$label"
  echo "label ready: $label"
done <<EOF
$labels
EOF

shopt -s nullglob
files=(.github/sift-tasks/*.md)
((${#files[@]} >= 5)) || {
  echo "bootstrap: expected at least 5 .github/sift-tasks/*.md files" >&2
  exit 1
}
for task in "${files[@]}"; do
  # Split front matter only at the first colon: label names themselves contain one.
  title=$(sed -n 's/^title:[[:space:]]*//p' "$task" | head -n1)
  title=${title#\"}; title=${title%\"}
  [[ -n "$title" ]] || { echo "bootstrap: missing title in $task" >&2; exit 1; }
  difficulty=$(sed -n 's/^difficulty:[[:space:]]*//p' "$task" | head -n1)
  case "$difficulty" in
    beginner|intermediate|advanced) ;;
    *) echo "bootstrap: seed $task needs beginner, intermediate, or advanced difficulty" >&2; exit 1 ;;
  esac
  labels_csv=$(sed -n 's/^labels:[[:space:]]*//p' "$task" | head -n1)
  labels_csv=${labels_csv:-sift:run,sift:seed}
  issue_labels=( )
  IFS=',' read -ra issue_labels <<< "$labels_csv"

  seed_id=${task##*/}
  marker="<!-- bluff-sift-seed:${seed_id%.md} -->"
  # The repository Issue list is authoritative and immediately readable. Unlike
  # search, it does not depend on GitHub's eventually consistent search index.
  issue_bodies=$(gh api --paginate "repos/$repo/issues?state=all&per_page=100" --jq '.[].body')
  marker_count=$(printf '%s\n' "$issue_bodies" | grep -Fxc "$marker" || true)
  if ((marker_count > 1)); then
    echo "bootstrap: multiple Issues have seed marker $marker; resolve them manually" >&2
    exit 1
  elif ((marker_count == 1)); then
    echo "Issue exists: $title"
    continue
  fi

  body=$(mktemp)
  printf '%s\n\n' "$marker" >"$body"
  awk 'BEGIN { front=0 } /^---$/ { front++; next } front >= 2 { print }' "$task" >>"$body"
  args=(gh issue create --repo "$repo" --title "$title" --body-file "$body")
  for label in "${issue_labels[@]}"; do
    label=$(printf '%s' "$label" | xargs)
    if [[ -n "$label" ]]; then
      printf '%s\n' "$created_labels" | grep -Fqx "$label" || {
        echo "bootstrap: seed $task references unknown label: $label" >&2
        exit 1
      }
      args+=(--label "$label")
    fi
  done
  created_issue=$("${args[@]}")
  rm -f "$body"
  issue_number=${created_issue##*/}
  [[ "$issue_number" =~ ^[0-9]+$ ]] || {
    echo "bootstrap: could not read created Issue number from: $created_issue" >&2
    exit 1
  }
  readback=$(gh issue view "$issue_number" --repo "$repo" --json body --jq '.body')
  printf '%s\n' "$readback" | grep -Fqx "$marker" || {
    echo "bootstrap: created Issue #$issue_number failed marker readback" >&2
    exit 1
  }
  printf '%s\n' "$created_issue"
  echo "Issue created: $title"
done

echo "bootstrap complete for $repo"
