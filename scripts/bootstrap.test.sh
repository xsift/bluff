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
  cp "$script_dir/../.github/sift-tasks/01-add-visible-mode-badge.md" "$dir/.github/sift-tasks/"
  for n in 2 3 4 5; do cp "$script_dir/../.github/sift-tasks/01-add-visible-mode-badge.md" "$dir/.github/sift-tasks/0$n-task.md"; done
}

write_gh() {
  local dir=$1
  cat >"$dir/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
state=${GH_STATE:?}
case "${1:-}" in
  auth) [[ "${GH_AUTH_OK:-1}" == 1 ]] || exit 1; exit 0 ;;
  repo)
    [[ "${GH_REPO_OK:-1}" == 1 ]] || exit 1
    printf '%s\nWRITE\n' "${GH_REPO_NAME:-owner/project}"
    ;;
  label) printf 'label %s\n' "$*" >>"$GH_LOG" ;;
  issue)
    if [[ "$2" == list ]]; then
      cat "$state"
    elif [[ "$2" == create ]]; then
      [[ "${GH_CREATE_FAIL_ONCE:-0}" == 1 && ! -f "$state.failed" ]] && { touch "$state.failed"; exit 1; }
      title=''; while (($#)); do [[ "$1" == --title ]] && { title=$2; shift; }; shift; done
      printf '%s\n' "$title" >>"$state"
      printf 'created\n'
    fi
    ;;
  *) exit 0 ;;
esac
MOCK
  chmod +x "$dir/bin/gh"
  : >"$dir/gh.state"
  : >"$dir/gh.log"
}

# Missing CLI is a hard stop before any mutation.
tmp=$(mktemp -d); trap 'rm -rf "$tmp" /tmp/bootstrap-test.out' EXIT
make_repo "$tmp/no-gh" "https://github.com/me/project.git"
assert_fail env PATH="/usr/bin:/bin" sh -c "cd '$tmp/no-gh' && '$script_dir/bootstrap.sh'"

# Authentication is checked before repository writes.
make_repo "$tmp/no-auth" "https://github.com/me/project.git"; write_gh "$tmp/no-auth"
assert_fail env PATH="$tmp/no-auth/bin:$PATH" GH_AUTH_OK=0 GH_STATE="$tmp/no-auth/gh.state" GH_LOG="$tmp/no-auth/gh.log" sh -c "cd '$tmp/no-auth' && '$script_dir/bootstrap.sh'"
[[ ! -s "$tmp/no-auth/gh.log" ]] || fail "unauthenticated run mutated labels"

# The template upstream is always refused.
make_repo "$tmp/upstream" "https://github.com/xsift/bluff.git"; write_gh "$tmp/upstream"
assert_fail env PATH="$tmp/upstream/bin:$PATH" GH_STATE="$tmp/upstream/gh.state" GH_LOG="$tmp/upstream/gh.log" sh -c "cd '$tmp/upstream' && '$script_dir/bootstrap.sh'"

# A failed Issue create leaves completed work resumable; the next run succeeds.
make_repo "$tmp/recover" "https://github.com/me/project.git"; write_gh "$tmp/recover"
env PATH="$tmp/recover/bin:$PATH" GH_STATE="$tmp/recover/gh.state" GH_LOG="$tmp/recover/gh.log" GH_REPO_NAME=me/project GH_CREATE_FAIL_ONCE=1 sh -c "cd '$tmp/recover' && '$script_dir/bootstrap.sh'" >/dev/null 2>&1 || true
env PATH="$tmp/recover/bin:$PATH" GH_STATE="$tmp/recover/gh.state" GH_LOG="$tmp/recover/gh.log" GH_REPO_NAME=me/project sh -c "cd '$tmp/recover' && '$script_dir/bootstrap.sh'" >/dev/null
count=$(grep -c 'Sift seed' "$tmp/recover/gh.state" || true)
[[ "$count" -ge 1 ]] || fail "recovery did not create an Issue"

# A successful rerun must not create duplicates.
before=$(wc -l <"$tmp/recover/gh.state")
env PATH="$tmp/recover/bin:$PATH" GH_STATE="$tmp/recover/gh.state" GH_LOG="$tmp/recover/gh.log" GH_REPO_NAME=me/project sh -c "cd '$tmp/recover' && '$script_dir/bootstrap.sh'" >/dev/null
after=$(wc -l <"$tmp/recover/gh.state")
[[ "$before" -eq "$after" ]] || fail "rerun created duplicate Issues"

echo "bootstrap shell tests passed"
