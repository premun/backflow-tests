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

  path=/work/repo
  name="$path-${from}-${to}.patch"

  local res=$(createPatch "$path" "$name" "$from" "$to")
  echo "$res"
}

function createVmrPatch() {
  local from=$1
  local to=$2

  path=/work/tmp/vmr
  name="$path-${from}-${to}.patch"

  local res=$(createPatch "$path" "$name" "$from" "$to")
  echo "$res"
}

function createPatch() {
  local path=$1
  local name=$2
  local from=$3
  local to=$4

  pushd "$path" || exit 1
  git diff --patch --binary --output "$name" --relative "$from..$to" -- . \
    || fail "Failed to create patch"
  popd || exit 1

  echo "$name"
}

function applyPatchToVmr() {
  applyPatch /work/vmr "$1" src
}

function applyPatchToRepo() {
  applyPatch /work/repo "$1" .
}

function applyPatch() {
  local repoPath=$1
  local patchPath=$2
  local targetDir=$3
  git -C "$repoPath" apply --ignore-space-change --directory "$targetDir" "$patchPath" || fail "Applying the patch failed!"
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
  local toSha=$1
  local baseSha=$2
  local fromSha="$(cat /work/vmr/last_sync)"

  echo "Flowing code from repo to VMR ($fromSha → $toSha)"
  flow /work/repo /work/vmr "$fromSha" "$toSha" "$baseSha" src

  if git -C /work/vmr merge main --no-ff --no-commit; then
    succeed "RESULT: No conflicts with main"
    git -C /work/vmr reset --hard pr-branch
  else
    fail "RESULT: Conflicts with main"
    git -C /work/vmr merge --abort
  fi
}

function backwardFlow() {
  local toSha=$1
  local baseSha=$2
  local fromSha=$(cat /work/repo/last_sync)
  
  if [ -z "$fromSha" ]; then
    # First commit in VMR
    fromSha=$(git -C /work/vmr log --format=format:%H | tail -n 1)
  fi

  echo "Flowing code from VMR to repo ($fromSha → $toSha)"
  flow /work/vmr /work/repo "$fromSha" "$toSha" "$baseSha" .
}

function flow() {
  local fromRepoPath=$1
  local toRepoPath=$2
  local fromSha=$3
  local toSha=$4
  local targetBaseSha=$5
  local targetDir=$6

  local patch=/work/tmp/pr.patch
  createPatch "$fromRepoPath" "$patch" "$fromSha" "$toSha"
  git -C "$toRepoPath" checkout -b pr-branch "$targetBaseSha"
  applyPatch "$toRepoPath" "$patch" "$targetDir"
  echo "$toSha" > "$toRepoPath"/last_sync
  git -C "$toRepoPath" add -A
  git -C "$toRepoPath" commit -am "Sync of $fromRepoPath from $fromSha to $toSha"
}
