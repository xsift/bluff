#!/usr/bin/env bash
set -Eeuo pipefail

# Initialize the Sift labels and task Issues in the repository cloned from this
# template. Every remote operation is explicit and safe to repeat.
command -v git >/dev/null || { echo "bootstrap: git is required" >&2; exit 1; }
command -v gh >/dev/null || { echo "bootstrap: GitHub CLI (gh) is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "bootstrap: jq is required" >&2; exit 1; }
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
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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

# Snapshot the authoritative Issue list once. It is immediately readable and,
# unlike search, does not depend on GitHub's eventually consistent search index.
# Each seed's stable identity lives in front matter `id`, never the file name.
issues_file="$tmpdir/issues.json"
gh api --paginate "repos/$repo/issues?state=all&per_page=100" --jq '.[]' >"$issues_file"
marker_prefix='<!-- bluff-sift-seed:'
seen_ids=''
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
  id=$(sed -n 's/^id:[[:space:]]*//p' "$task" | head -n1)
  id=${id#\"}; id=${id%\"}
  [[ -n "$id" ]] || { echo "bootstrap: missing id (stable task identity) in $task" >&2; exit 1; }
  [[ "$id" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "bootstrap: invalid id '$id' in $task (use letters, digits, . _ -)" >&2
    exit 1
  }
  if printf '%s\n' "$seen_ids" | grep -Fqx "$id"; then
    echo "bootstrap: duplicate seed id '$id' in $task" >&2
    exit 1
  fi
  seen_ids="$seen_ids
$id"
  labels_csv=$(sed -n 's/^labels:[[:space:]]*//p' "$task" | head -n1)
  labels_csv=${labels_csv:-sift:run,sift:seed}
  issue_labels=( )
  IFS=',' read -ra issue_labels <<< "$labels_csv"

  marker="${marker_prefix}${id} -->"

  # 1. An Issue already carrying this canonical marker is authoritative.
  # GitHub can report `body: null` (Issues created without a body); treat it as
  # an empty string so jq's `contains` never receives null.
  marked=$(jq -s -c --arg m "$marker" '[.[] | select((.body // "") | contains($m))]' "$issues_file")
  marked_n=$(printf '%s\n' "$marked" | jq 'length')
  if ((marked_n > 1)); then
    echo "bootstrap: multiple Issues have seed marker $marker; resolve them manually" >&2
    exit 1
  elif ((marked_n == 1)); then
    echo "Issue exists: $title"
    continue
  fi

  # 2. Migration/dedupe: an Issue created by a bootstrap older than stable body
  # markers has no marker at all. Match it by exact title and stamp the canonical
  # marker into its body instead of creating a duplicate. A renamed task file is
  # matched here too, because identity comes from `id`, not the file name.
  legacy=$(jq -s -c --arg m "$marker" --arg t "$title" \
    '[.[] | select(.title == $t) | select(((.body // "") | contains($m)) | not)]' "$issues_file")
  legacy_n=$(printf '%s\n' "$legacy" | jq 'length')
  if ((legacy_n > 1)); then
    echo "bootstrap: multiple Issues match seed title \"$title\" without marker; resolve them manually" >&2
    exit 1
  elif ((legacy_n == 1)); then
    legacy_num=$(printf '%s\n' "$legacy" | jq -r '.[0].number')
    old_body=$(printf '%s\n' "$legacy" | jq -r '.[0].body // ""')
    # Strip any older seed markers so the canonical marker is unambiguous.
    clean=$(printf '%s\n' "$old_body" | sed '/^<!-- bluff-sift-seed:/d')
    body=$(mktemp)
    printf '%s\n\n' "$marker" >"$body"
    printf '%s' "$clean" >>"$body"
    gh issue edit "$legacy_num" --repo "$repo" --body-file "$body" >/dev/null
    rm -f "$body"
    readback=$(gh issue view "$legacy_num" --repo "$repo" --json body --jq '.body')
    printf '%s\n' "$readback" | grep -Fq "$marker" || {
      echo "bootstrap: migrated Issue #$legacy_num failed marker readback" >&2
      exit 1
    }
    echo "Issue migrated: $title"
    continue
  fi

  # 3. No existing Issue: create a fresh one with the canonical marker.
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
