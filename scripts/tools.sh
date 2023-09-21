#!/bin/bash

COLOR_RED=$(tput setaf 1 2>/dev/null || true)
COLOR_GREEN=$(tput setaf 2 2>/dev/null || true)
COLOR_CYAN=$(tput setaf 6 2>/dev/null || true)
COLOR_CLEAR=$(tput sgr0 2>/dev/null || true)
COLOR_RESET=uniquesearchablestring

function succeed () {
  echo "${COLOR_GREEN}${1//${COLOR_RESET}/${COLOR_GREEN}}${COLOR_CLEAR}"
}

function fail () {
  echo "${COLOR_RED}${1//${COLOR_RESET}/${COLOR_RED}}${COLOR_CLEAR}"
  # exit 1
}

function highlight () {
  echo
  echo "${COLOR_CYAN}${1//${COLOR_RESET}/${COLOR_CYAN}}${COLOR_CLEAR}"
}

function createRepoPatch() {
  local from=$1
  local to=$2

  local res=$(createPatch /work/repo "/work/tmp/repo-${from}-${to}.patch" "$from" "$to" .)
  echo "$res"
}

function createVmrPatch() {
  local from=$1
  local to=$2
  local res=$(createPatch /work/vmr/src "/work/tmp/vmr-${from}-${to}.patch" "$from" "$to")
  echo "$res"
}

function createPatch() {
  local path=$1
  local name=$2
  local from=$3
  local to=$4

  pushd "$path" 1>/dev/null || exit 1
  git diff --patch --binary --output "$name" --relative "$from..$to" -- . \
    || fail "Failed to create patch"
  popd 1>/dev/null || exit 1

  echo "$name"
}

function applyPatchToVmr() {
  applyPatch /work/vmr "$1" src
}

function applyPatchToRepo() {
  applyPatch /work/repo "$1" ''
}

function applyPatch() {
  local repoPath=$1
  local patchPath=$2
  local targetDir=$3
  pushd "$repoPath" 1>/dev/null || exit 1
  git apply --ignore-space-change --directory "$targetDir" "$patchPath" || fail "Applying the patch failed!"
  popd 1>/dev/null || exit 1
}

function getRepoSha() {
  local res=$(getSha /work/repo "$1")
  echo "$res"
}

function getVmrSha() {
  local res=$(getSha /work/vmr "$1")
  echo "$res"
}

function getSha() {
  local path=$1
  local order
  if [ -z "$2" ]; then
    order=1
  else
    order=$2
  fi

  local sha=$(git -C "$path" log --format=format:%H | head -n $order | tail -n 1)
  echo "$sha"
}

function commitToRepo() {
  local content=$1
  commitChange /work/repo /work/repo/A.txt "$content"
}

function commitToVmr() {
  local content=$1
  commitChange /work/vmr /work/vmr/src/A.txt "$content"
}

function commitChange() {
  local repo=$1
  local path=$2
  local content=$3
  echo "$content" > "$path"
  git -C "$repo" commit -am "A.txt set to $content"
}

function showRepo() {
  show /work/repo
}

function showVmr() {
  show /work/vmr
}

function show() {
  git -C "$1" log --graph --decorate --oneline --all
}

function forwardFlow() {
  local baseSha=$1
  local toSha=$2
  local fromSha="$(cat /work/vmr/last_sync)"

  if [ -z "$toSha" ]; then
    # Last commit in VMR
    toSha=$(getRepoSha)
  fi

  echo "Flowing code from repo to VMR ($fromSha → $toSha)"

  patch=$(createRepoPatch "$fromSha" "$toSha")
  git -C /work/vmr/ checkout -b pr-branch "$baseSha"
  applyPatchToVmr "$patch"
  echo "$toSha" > /work/vmr/last_sync
  git -C /work/vmr add -A
  git -C /work/vmr commit -am "Sync from $fromSha to $toSha"

  checkConflict /work/vmr main
}

function backwardFlow() {
  local toSha=$1
  local baseSha=$(cat /work/vmr/last_sync)
  local fromSha=$(cat /work/repo/last_sync)

  if [ -z "$toSha" ]; then
    # Last commit in VMR
    toSha=$(getVmrSha)
  fi

  if [ -z "$fromSha" ]; then
    # First commit in VMR
    fromSha=$(getVmrSha 1000)
  fi

  echo "Flowing code from VMR to repo ($fromSha → $toSha)"

  patch=$(createVmrPatch "$fromSha" "$toSha")
  git -C /work/repo/ checkout -b pr-branch "$baseSha"
  applyPatchToRepo "$patch"
  echo "$toSha" > /work/repo/last_sync
  git -C /work/repo add -A
  git -C /work/repo commit -am "Sync from $fromSha to $toSha"

  checkConflict /work/repo main
}

function checkConflict() {
  local repo=$1
  local branch=$2
  
  if git -C "$repo" merge "$branch" --no-ff --no-commit; then
    succeed "RESULT: No conflicts with $branch"
    git -C "$repo" reset --hard pr-branch
  else
    fail "RESULT: Conflicts with $branch"
    cat "$repo"/A.txt 2>/dev/null
    cat "$repo"/src/A.txt 2>/dev/null
    git -C "$repo" merge --abort
  fi
}
