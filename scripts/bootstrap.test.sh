#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_fail() { if "$@" >/tmp/bootstrap-test.out 2>&1; then fail "expected failure: $*"; fi; }

make_repo() {
  local dir=$1 remote=$2
  mkdir -p "$dir" "$dir/bin"
  git -C "$dir" init -q
  git -C "$dir" remote add origin "$remote"
  mkdir -p "$dir/.github/sift-tasks"
  cp "$script_dir"/../.github/sift-tasks/*.md "$dir/.github/sift-tasks/"
}

write_gh() {
  local dir=$1
  cat >"$dir/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
state=${GH_STATE:?}; labels="$state/labels"
case "${1:-}" in
  auth) [[ "${GH_AUTH_OK:-1}" == 1 ]] || exit 1; exit 0 ;;
  repo)
    [[ "${GH_REPO_OK:-1}" == 1 ]] || exit 1
    printf '%s\nWRITE\n' "${GH_REPO_NAME:-owner/project}" ;;
  label)
    [[ "$2" == create ]] || exit 1
    name=$3; grep -Fqx "$name" "$labels" || printf '%s\n' "$name" >>"$labels"
    printf 'label %s\n' "$*" >>"$GH_LOG" ;;
  api)
    for body in "$state"/issue-*.body; do
      [[ -e "$body" ]] && cat "$body"
    done
    true ;;
  issue)
    if [[ "$2" == view ]]; then
      cat "$state/issue-$3.body"
    elif [[ "$2" == create ]]; then
      title=''; body_file=''; issue_labels=()
      while (($#)); do
        case "$1" in
          --title) title=$2; shift 2;;
          --body-file) body_file=$2; shift 2;;
          --label) issue_labels+=("$2"); shift 2;;
          *) shift;;
        esac
      done
      for label in "${issue_labels[@]}"; do
        grep -Fqx "$label" "$labels" || { echo 'GitHub API: 422 unknown label' >&2; exit 22; }
      done
      next=$(find "$state" -name 'issue-*.body' | wc -l | tr -d ' ')
      next=$((next + 1))
      if [[ "${GH_CREATE_FAIL_AT:-0}" == "$next" && ! -f "$state/failed" ]]; then
        touch "$state/failed"
        exit 1
      fi
      cp "$body_file" "$state/issue-$next.body"
      printf '%s\n' "$title" >"$state/issue-$next.title"
      printf 'issue create %s\n' "$title" >>"$GH_LOG"
      printf 'https://github.com/%s/issues/%s\n' "${GH_REPO_NAME:-owner/project}" "$next"
    fi ;;
  *) exit 0 ;;
esac
MOCK
  chmod +x "$dir/bin/gh"
  mkdir -p "$dir/gh.state"
  : >"$dir/gh.state/labels"
  : >"$dir/gh.log"
}

# Missing CLI is a hard stop before any mutation.
tmp=$(mktemp -d); trap 'rm -rf "$tmp" /tmp/bootstrap-test.out' EXIT
make_repo "$tmp/no-gh" "https://github.com/me/project.git"
mkdir -p "$tmp/no-gh-path"
ln -s "$(command -v git)" "$tmp/no-gh-path/git"
assert_fail env PATH="$tmp/no-gh-path" /bin/bash -c "cd '$tmp/no-gh' && /bin/bash '$script_dir/bootstrap.sh'"

# Authentication is checked before repository writes.
make_repo "$tmp/no-auth" "https://github.com/me/project.git"; write_gh "$tmp/no-auth"
assert_fail env PATH="$tmp/no-auth/bin:$PATH" GH_AUTH_OK=0 GH_STATE="$tmp/no-auth/gh.state" GH_LOG="$tmp/no-auth/gh.log" sh -c "cd '$tmp/no-auth' && '$script_dir/bootstrap.sh'"
[[ ! -s "$tmp/no-auth/gh.log" ]] || fail "unauthenticated run mutated labels"

# The template upstream is always refused.
make_repo "$tmp/upstream" "https://github.com/xsift/bluff.git"; write_gh "$tmp/upstream"
assert_fail env PATH="$tmp/upstream/bin:$PATH" GH_STATE="$tmp/upstream/gh.state" GH_LOG="$tmp/upstream/gh.log" sh -c "cd '$tmp/upstream' && '$script_dir/bootstrap.sh'"

# A failure after two creates leaves partial work resumable; the next run fills only the gap.
make_repo "$tmp/recover" "https://github.com/me/project.git"; write_gh "$tmp/recover"
env PATH="$tmp/recover/bin:$PATH" GH_STATE="$tmp/recover/gh.state" GH_LOG="$tmp/recover/gh.log" GH_REPO_NAME=me/project GH_CREATE_FAIL_AT=3 sh -c "cd '$tmp/recover' && '$script_dir/bootstrap.sh'" >/dev/null 2>&1 || true
partial=$(find "$tmp/recover/gh.state" -name 'issue-*.body' | wc -l | tr -d ' ')
[[ "$partial" -eq 2 ]] || fail "failure fixture did not leave two completed Issues"
env PATH="$tmp/recover/bin:$PATH" GH_STATE="$tmp/recover/gh.state" GH_LOG="$tmp/recover/gh.log" GH_REPO_NAME=me/project sh -c "cd '$tmp/recover' && '$script_dir/bootstrap.sh'" >/dev/null
count=$(find "$tmp/recover/gh.state" -name 'issue-*.body' | wc -l | tr -d ' ')
[[ "$count" -eq 6 ]] || fail "recovery did not create all 6 Issues (got $count)"
labels_created=$(wc -l <"$tmp/recover/gh.state/labels")
[[ "$labels_created" -eq 6 ]] || fail "not all canonical labels were created"

# An immediate rerun uses stable body markers, even if a title changed, and creates nothing.
printf '%s\n' 'A maintainer renamed this Issue' >"$tmp/recover/gh.state/issue-1.title"
before=$(grep -c '^issue create ' "$tmp/recover/gh.log")
env PATH="$tmp/recover/bin:$PATH" GH_STATE="$tmp/recover/gh.state" GH_LOG="$tmp/recover/gh.log" GH_REPO_NAME=me/project sh -c "cd '$tmp/recover' && '$script_dir/bootstrap.sh'" >/dev/null
after=$(grep -c '^issue create ' "$tmp/recover/gh.log")
[[ "$before" -eq "$after" ]] || fail "immediate rerun created duplicate Issues"

# A seed with an unknown label must fail closed before GitHub can create it.
make_repo "$tmp/unknown-label" "https://github.com/me/project.git"; write_gh "$tmp/unknown-label"
sed -i.bak 's/^labels:.*/labels: sift:run,unknown:label/' "$tmp/unknown-label/.github/sift-tasks/01-add-visible-mode-badge.md"
rm -f "$tmp/unknown-label/.github/sift-tasks/01-add-visible-mode-badge.md.bak"
assert_fail env PATH="$tmp/unknown-label/bin:$PATH" GH_STATE="$tmp/unknown-label/gh.state" GH_LOG="$tmp/unknown-label/gh.log" GH_REPO_NAME=me/project sh -c "cd '$tmp/unknown-label' && '$script_dir/bootstrap.sh'"

# The mock also enforces GitHub's 422 for any issue label not created above.
grep -Fq 'unknown label' /tmp/bootstrap-test.out || fail "unknown label was not rejected"

echo "bootstrap shell tests passed"
